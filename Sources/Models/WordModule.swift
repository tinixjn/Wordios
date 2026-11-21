import Foundation

final class WordModule: DeckManageable, Identifiable {
    let id: UUID
    var title: String
    var level: EnglishLevel
    var cards: [WordCard]

    init(
        id: UUID = UUID(),
        title: String,
        level: EnglishLevel,
        cards: [WordCard] = []
    ) {
        self.id = id
        self.title = title
        self.level = level
        self.cards = cards
    }

    // MARK: - DeckManageable

    func addCard(_ card: WordCard) {
        cards.append(card)
    }

    func filterCards(by status: LearningStatus) -> [WordCard] {
        cards.filter { $0.status == status }
    }

    // Прогрес = відсоток карток зі статусом «Вивчено».
    func calculateProgress() -> Double {
        guard !cards.isEmpty else { return 0 }
        let masteredCount = filterCards(by: .mastered).count
        return Double(masteredCount) / Double(cards.count) * 100
    }

    // MARK: - Additional WordModule Features

    func findCard(term: String) -> WordCard? {
        let query = term.trimmingCharacters(in: .whitespacesAndNewlines)
        return cards.first {
            $0.term.compare(query, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    @discardableResult
    func updateCardStatus(id: UUID, to newStatus: LearningStatus) -> Bool {
        guard let index = cards.firstIndex(where: { $0.id == id }) else {
            return false
        }
        cards[index].updateStatus(to: newStatus)
        return true
    }

    // Безпечне розгортання Optional за допомогою if let.
    func displayTranscription(for card: WordCard) -> String {
        if let transcription = card.transcription,
           !transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return transcription
        }
        return "Транскрипція відсутня"
    }
}
