import Foundation

final class ModuleBuilder {
    private var id: UUID = UUID()
    private var title: String = "Новий модуль"
    private var level: EnglishLevel = .a1
    private var cards: [WordCard] = []

    @discardableResult
    func setId(_ id: UUID) -> ModuleBuilder {
        self.id = id
        return self
    }

    @discardableResult
    func setTitle(_ title: String) -> ModuleBuilder {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            self.title = trimmed
        }
        return self
    }

    @discardableResult
    func setLevel(_ level: EnglishLevel) -> ModuleBuilder {
        self.level = level
        return self
    }

    @discardableResult
    func addCard(_ card: WordCard) -> ModuleBuilder {
        self.cards.append(card)
        return self
    }

    @discardableResult
    func addCards(_ newCards: [WordCard]) -> ModuleBuilder {
        self.cards.append(contentsOf: newCards)
        return self
    }

    @discardableResult
    func addWord(
        term: String,
        translation: String,
        transcription: String? = nil,
        synonyms: [String] = [],
        status: LearningStatus = .new
    ) -> ModuleBuilder {
        let card = WordCard(
            term: term,
            translation: translation,
            transcription: transcription,
            synonyms: synonyms,
            status: status
        )
        self.cards.append(card)
        return self
    }

    func build() -> WordModule {
        let module = WordModule(id: id, title: title, level: level, cards: cards)
        reset()
        return module
    }

    func reset() {
        self.id = UUID()
        self.title = "Новий модуль"
        self.level = .a1
        self.cards = []
    }
}