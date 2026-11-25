import Foundation
import Combine

/// Стан одного тренування; порядок карток визначає Strategy.
@MainActor
final class FlashcardSessionViewModel: ObservableObject {
    @Published private(set) var module: WordModule?
    @Published private(set) var orderedCards: [WordCard] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var isSessionCompleted = false

    private let repository: any DictionaryRepositoryProtocol
    private let strategy: any StudyOrderStrategy

    init(moduleId: UUID,
         repository: any DictionaryRepositoryProtocol,
         strategy: any StudyOrderStrategy) {
        self.repository = repository
        self.strategy = strategy
        self.module = repository.fetchModule(by: moduleId)
        self.orderedCards = strategy.orderCards(module?.cards ?? [])
    }

    var currentCard: WordCard? {
        guard orderedCards.indices.contains(currentIndex) else { return nil }
        return orderedCards[currentIndex]
    }

    var totalCount: Int { orderedCards.count }
    var currentPosition: Int { currentCard == nil ? 0 : currentIndex + 1 }
    var strategyName: String { strategy.strategyName }
    var progress: Double { module?.calculateProgress() ?? 0 }

    var canAdvance: Bool { currentIndex + 1 < orderedCards.count }

    // Адаптація до наявного інтерфейсу тренування Крістіни.
    var cards: [WordCard] { orderedCards }
    var progressText: String {
        guard totalCount > 0 else { return "0 з 0" }
        return "\(currentPosition) з \(totalCount)"
    }
    var progressValue: Double {
        guard totalCount > 0 else { return 0 }
        if isSessionCompleted { return 1 }
        return Double(currentIndex) / Double(totalCount)
    }

    func advance() {
        guard canAdvance else { return }
        currentIndex += 1
    }

    func markAsLearning() {
        completeCurrentCard(as: .learning)
    }

    func markAsMastered() {
        completeCurrentCard(as: .mastered)
    }

    private func completeCurrentCard(as status: LearningStatus) {
        guard currentCard != nil, !isSessionCompleted else { return }
        markCurrentCard(as: status)
        if canAdvance {
            advance()
        } else {
            isSessionCompleted = true
        }
    }

    func restartSession() {
        if let moduleId = module?.id {
            module = repository.fetchModule(by: moduleId)
        }
        orderedCards = strategy.orderCards(module?.cards ?? [])
        currentIndex = 0
        isSessionCompleted = false
    }

    /// Не перемішує картки повторно, тож послідовність тренування не стрибає.
    func markCurrentCard(as status: LearningStatus) {
        guard let module = module, let card = currentCard else { return }
        repository.updateCardStatus(cardId: card.id, inModuleId: module.id, to: status)
        // Оновлюємо локальний стан.
        orderedCards[currentIndex].updateStatus(to: status)
        self.module = repository.fetchModule(by: module.id)
    }
}
