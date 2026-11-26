import Foundation
import XCTest
@testable import Wordios

final class PracticalPersistenceTests: XCTestCase {
    private func storageURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("WordiosTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("dictionary.json")
    }

    func testNewWordSurvivesRepositoryRestart() throws {
        let url = storageURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let module = WordModule(title: "Test", level: .a2)
        let first = JSONDictionaryRepository(fileURL: url, seedModules: [module])
        let newWord = WordCard(term: "Journey", translation: "Подорож", synonyms: ["trip"])
        first.addCard(newWord, toModuleId: module.id)

        let reopened = JSONDictionaryRepository(fileURL: url, seedModules: [module])
        let restored = try XCTUnwrap(reopened.fetchModule(by: module.id))
        XCTAssertEqual(restored.cards.count, 1)
        XCTAssertEqual(restored.cards[0].id, newWord.id)
        XCTAssertEqual(restored.cards[0].translation, "Подорож")
        XCTAssertEqual(restored.cards[0].synonyms, ["trip"])
    }

    func testLearningStatusAndModuleProgressSurviveRestart() throws {
        let url = storageURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let word = WordCard(term: "Ticket", translation: "Квиток")
        let module = WordModule(title: "Test", level: .a2, cards: [word])
        let first = JSONDictionaryRepository(fileURL: url, seedModules: [module])
        first.updateCardStatus(cardId: word.id, inModuleId: module.id, to: .mastered)

        let reopened = JSONDictionaryRepository(fileURL: url, seedModules: [module])
        let savedModule = try XCTUnwrap(reopened.fetchModule(by: module.id))
        XCTAssertEqual(savedModule.cards[0].status, .mastered)
        XCTAssertEqual(savedModule.calculateProgress(), 100)
    }

    func testNewDemoWordsMergeWithoutLosingCustomOnes() throws {
        let url = storageURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let module = WordModule(title: "Подорожі", level: .a2,
                                cards: [WordCard(term: "Journey", translation: "Подорож")])
        let first = JSONDictionaryRepository(fileURL: url, seedModules: [module])
        first.addCard(WordCard(term: "Custom", translation: "Власне"), toModuleId: module.id)

        let expanded = WordModule(title: "Подорожі", level: .a2,
                                  cards: [WordCard(term: "Journey", translation: "Подорож"),
                                          WordCard(term: "Trip", translation: "Поїздка")])
        let reopened = JSONDictionaryRepository(fileURL: url, seedModules: [expanded])
        let terms = try XCTUnwrap(reopened.fetchModule(by: module.id)).cards.map { $0.term }
        XCTAssertEqual(terms.count, 3)
        XCTAssertTrue(terms.contains("Custom"))
        XCTAssertTrue(terms.contains("Journey"))
        XCTAssertTrue(terms.contains("Trip"))
        let reopenedAgain = JSONDictionaryRepository(fileURL: url, seedModules: [expanded])
        XCTAssertEqual(reopenedAgain.fetchModule(by: module.id)?.cards.count, 3)
    }

    func testPartialMatchIsNotFullMatch() {
        let adapter = DictionaryWordAdapter()
        let first = ["trip", "travel"]
        let second = ["journey", "TRAVEL", "excursion"]
        XCTAssertEqual(adapter.commonSynonyms(first, second), ["travel"])
        XCTAssertTrue(adapter.synonymsOverlap(first, second))
        XCTAssertFalse(adapter.synonymsMatch(first, second))
    }

    func testCompleteMatchDoesNotDependOnOrderOrCase() {
        let adapter = DictionaryWordAdapter()
        XCTAssertTrue(adapter.synonymsMatch(["Travel", "trip"], ["TRIP", "travel"]))
        XCTAssertEqual(adapter.commonSynonyms(["Travel", "trip"], ["TRIP", "travel"]).count, 2)
    }

    func testNoSubstringFalsePositive() {
        let adapter = DictionaryWordAdapter()
        XCTAssertFalse(adapter.synonymsOverlap(["travel"], ["traveller"]))
        XCTAssertFalse(adapter.synonymsOverlap(["pay"], ["payment"]))
    }

    func testDemoPairsHaveCommonSynonym() throws {
        let repository = MockDictionaryRepository()
        let travel = try XCTUnwrap(repository.fetchModules().first(where: { $0.level == .a2 }))
        let journey = try XCTUnwrap(travel.findCard(term: "Journey"))
        let trip = try XCTUnwrap(travel.findCard(term: "Trip"))
        XCTAssertEqual(DictionaryWordAdapter().commonSynonyms(journey.synonyms, trip.synonyms), ["travel"])

        let work = try XCTUnwrap(repository.fetchModules().first(where: { $0.level == .b1 }))
        let colleague = try XCTUnwrap(work.findCard(term: "Colleague"))
        let coworker = try XCTUnwrap(work.findCard(term: "Coworker"))
        XCTAssertEqual(DictionaryWordAdapter().commonSynonyms(colleague.synonyms, coworker.synonyms), ["teammate"])
    }
}
