import Foundation

/// In-memory сховище для демонстрації роботи без підключення до мережі.
final class MockDictionaryRepository: DictionaryRepositoryProtocol {
    private var modules: [WordModule]

    init(modules: [WordModule] = MockDictionaryRepository.makeInitialModules()) {
        self.modules = modules
    }

    func fetchModules() -> [WordModule] {
        modules
    }

    func fetchModule(by id: UUID) -> WordModule? {
        modules.first { $0.id == id }
    }

    func saveModule(_ module: WordModule) {
        if let index = modules.firstIndex(where: { $0.id == module.id }) {
            modules[index] = module
        } else {
            modules.append(module)
        }
    }

    func addCard(_ card: WordCard, toModuleId moduleId: UUID) {
        guard let module = fetchModule(by: moduleId) else { return }
        module.addCard(card)
    }

    func updateCardStatus(cardId: UUID, inModuleId moduleId: UUID, to newStatus: LearningStatus) {
        guard let module = fetchModule(by: moduleId) else { return }
        module.updateCardStatus(id: cardId, to: newStatus)
    }

    /// Поки один демонстраційний набір.
    private static func makeInitialModules() -> [WordModule] {
        let cards: [WordCard] = [
            WordCard(term: "Journey", translation: "Подорож", transcription: "/ˈdʒɜːrni/", synonyms: ["trip", "travel"]),
            WordCard(term: "Ticket", translation: "Квиток", transcription: "/ˈtɪkɪt/", synonyms: ["pass"]),
            WordCard(term: "Luggage", translation: "Багаж", transcription: "/ˈlʌɡɪdʒ/", synonyms: ["baggage"]),
            WordCard(term: "Destination", translation: "Місце призначення"),
            WordCard(term: "Airport", translation: "Аеропорт", transcription: "/ˈeəpɔːrt/"),
            WordCard(term: "Passport", translation: "Паспорт", transcription: "/ˈpɑːspɔːrt/"),
            WordCard(term: "Suitcase", translation: "Валіза", synonyms: ["case"]),
            WordCard(term: "Hotel", translation: "Готель", transcription: "/həʊˈtel/", synonyms: ["inn"]),
            WordCard(term: "Map", translation: "Мапа", transcription: "/mæp/"),
            WordCard(term: "Departure", translation: "Відправлення", synonyms: ["leaving"])
        ]
        return [WordModule(title: "Подорожі", level: .a2, cards: cards)]
    }
}
