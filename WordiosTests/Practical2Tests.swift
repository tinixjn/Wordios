//
//  Practical2Tests.swift
//  WordiosTests
//
//  Created by Діана Сиротюк on 24.11.2026.
//

import XCTest
@testable import Wordios

// MARK: - Repository Tests

final class RepositoryTests: XCTestCase {

    func testFetchModules() {
        let module = WordModule(title: "Travel", level: .a2)
        let repository = MockDictionaryRepository(modules: [module])

        XCTAssertEqual(repository.fetchModules().count, 1)
        XCTAssertEqual(repository.fetchModule(by: module.id)?.title, "Travel")
    }

    func testAddCard() {
        let module = WordModule(title: "Travel", level: .a2)
        let repository = MockDictionaryRepository(modules: [module])

        let card = WordCard(term: "Ticket", translation: "Квиток")
        repository.addCard(card, toModuleId: module.id)

        XCTAssertEqual(repository.fetchModule(by: module.id)?.cards.count, 1)
        XCTAssertEqual(repository.fetchModule(by: module.id)?.cards.first?.term, "Ticket")
    }

    func testUpdateCardStatus() {
        let card = WordCard(term: "Airport", translation: "Аеропорт")
        let module = WordModule(
            title: "Travel",
            level: .a2,
            cards: [card]
        )
        let repository = MockDictionaryRepository(modules: [module])

        repository.updateCardStatus(
            cardId: card.id,
            inModuleId: module.id,
            to: .mastered
        )

        XCTAssertEqual(
            repository.fetchModule(by: module.id)?.cards.first?.status,
            .mastered
        )
    }
}

// MARK: - Adapter Tests

final class AdapterTests: XCTestCase {

    func testAdaptDictionaryWord() {
        let raw = RawDictionaryWord(
            term: " Journey ",
            translation: " Подорож ",
            transcription: " /ˈdʒɜːrni/ ",
            synonyms: "trip, voyage"
        )

        let card = DictionaryWordAdapter().adapt(raw)

        XCTAssertEqual(card.term, "Journey")
        XCTAssertEqual(card.translation, "Подорож")
        XCTAssertEqual(card.transcription, "/ˈdʒɜːrni/")
        XCTAssertEqual(card.synonyms, ["trip", "voyage"])
    }

    func testRemoveDuplicateSynonyms() {
        let adapter = DictionaryWordAdapter()

        let result = adapter.parseSynonyms(
            "trip, Trip; voyage, journey; VOYAGE"
        )

        XCTAssertEqual(result, ["trip", "voyage", "journey"])
    }

    func testSynonymsMatchRegardlessOfOrder() {
        let adapter = DictionaryWordAdapter()

        XCTAssertTrue(
            adapter.synonymsMatch(
                ["Journey", "Trip"],
                ["trip", "journey"]
            )
        )
    }
}

// MARK: - ModulesListViewModel Tests

final class ModulesListViewModelTests: XCTestCase {

    @MainActor
    func testLoadModules() {
        let modules = [
            WordModule(title: "Travel", level: .a2),
            WordModule(title: "Business", level: .b1)
        ]

        let repository = MockDictionaryRepository(modules: modules)
        let viewModel = ModulesListViewModel(repository: repository)

        XCTAssertEqual(viewModel.modules.count, 2)
        XCTAssertEqual(viewModel.visibleModules.count, 2)
    }

    @MainActor
    func testFilterModulesByLevel() {
        let modules = [
            WordModule(title: "Travel", level: .a2),
            WordModule(title: "Business", level: .b1)
        ]

        let repository = MockDictionaryRepository(modules: modules)
        let viewModel = ModulesListViewModel(repository: repository)

        viewModel.selectedLevel = .a2

        XCTAssertEqual(viewModel.visibleModules.count, 1)
        XCTAssertEqual(viewModel.visibleModules.first?.title, "Travel")
    }

    @MainActor
    func testAddModule() {
        let repository = MockDictionaryRepository(modules: [])
        let viewModel = ModulesListViewModel(repository: repository)

        let module = WordModule(title: "Science", level: .c1)
        viewModel.addModule(module)

        XCTAssertEqual(viewModel.modules.count, 1)
        XCTAssertEqual(viewModel.modules.first?.title, "Science")
        XCTAssertEqual(repository.fetchModules().count, 1)
    }
}

// MARK: - FlashcardSessionViewModel Tests

final class FlashcardSessionViewModelTests: XCTestCase {

    @MainActor
    func testAdvanceToNextCard() {
        let cards = [
            WordCard(term: "Ticket", translation: "Квиток"),
            WordCard(term: "Airport", translation: "Аеропорт")
        ]

        let module = WordModule(
            title: "Travel",
            level: .a2,
            cards: cards
        )

        let repository = MockDictionaryRepository(modules: [module])

        let viewModel = FlashcardSessionViewModel(
            moduleId: module.id,
            repository: repository,
            strategy: SequentialStrategy()
        )

        XCTAssertEqual(viewModel.currentCard?.term, "Ticket")
        XCTAssertTrue(viewModel.canAdvance)

        viewModel.advance()

        XCTAssertEqual(viewModel.currentCard?.term, "Airport")
        XCTAssertEqual(viewModel.currentPosition, 2)
        XCTAssertFalse(viewModel.canAdvance)
    }

    @MainActor
    func testMarkCurrentCardAsMastered() {
        let card = WordCard(term: "Ticket", translation: "Квиток")

        let module = WordModule(
            title: "Travel",
            level: .a2,
            cards: [card]
        )

        let repository = MockDictionaryRepository(modules: [module])

        let viewModel = FlashcardSessionViewModel(
            moduleId: module.id,
            repository: repository,
            strategy: SequentialStrategy()
        )

        viewModel.markCurrentCard(as: .mastered)

        XCTAssertEqual(viewModel.currentCard?.status, .mastered)
        XCTAssertEqual(viewModel.progress, 100.0)

        let savedCard = repository.fetchModule(by: module.id)?.cards.first
        XCTAssertEqual(savedCard?.status, .mastered)
    }
}
