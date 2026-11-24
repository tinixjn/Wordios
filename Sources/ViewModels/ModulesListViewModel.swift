import Foundation
import Combine

/// Стан головного екрана, незалежний від конкретного способу збереження даних.
@MainActor
final class ModulesListViewModel: ObservableObject {
    @Published private(set) var modules: [WordModule] = []
    @Published var selectedLevel: EnglishLevel? = nil

    private let repository: any DictionaryRepositoryProtocol

    init(repository: any DictionaryRepositoryProtocol) {
        self.repository = repository
        refresh()
    }

    var visibleModules: [WordModule] {
        guard let selectedLevel = selectedLevel else { return modules }
        return modules.filter { $0.level == selectedLevel }
    }

    func refresh() {
        modules = repository.fetchModules()
    }

    func progress(for module: WordModule) -> Double {
        module.calculateProgress()
    }

    func addModule(_ module: WordModule) {
        repository.saveModule(module)
        refresh()
    }

    func addCard(_ card: WordCard, to moduleId: UUID) {
        repository.addCard(card, toModuleId: moduleId)
        refresh() // WordModule — reference type; повторна публікація повідомляє SwiftUI про зміну.
    }
}
