import XCTest
@testable import Wordios

final class Practical3Tests: XCTestCase {

    func testInitialModulesIncludeA2B1C1() {
        let repository = MockDictionaryRepository()
        let levels = repository.fetchModules().map { $0.level }
        XCTAssertTrue(levels.contains(.a2))
        XCTAssertTrue(levels.contains(.b1))
        XCTAssertTrue(levels.contains(.c1))
    }

    @MainActor
    func testAddingWordRefreshesModuleList() {
        let module = WordModule(title: "Travel", level: .a2)
        let repository = MockDictionaryRepository(modules: [module])
        let viewModel = ModulesListViewModel(repository: repository)

        let word = WordCard(term: "Station", translation: "Станція")
        viewModel.addCard(word, to: module.id)

        XCTAssertEqual(viewModel.modules.first?.cards.count, 1)
        XCTAssertEqual(viewModel.modules.first?.cards.first?.term, "Station")
    }

    @MainActor
    func testCompletingSessionPersistsStatus() {
        let card = WordCard(term: "Station", translation: "Станція")
        let module = WordModule(title: "Travel", level: .a2, cards: [card])
        let repository = MockDictionaryRepository(modules: [module])
        let viewModel = FlashcardSessionViewModel(
            moduleId: module.id,
            repository: repository,
            strategy: SequentialStrategy()
        )

        viewModel.markAsMastered()

        XCTAssertTrue(viewModel.isSessionCompleted)
        XCTAssertEqual(viewModel.progress, 100.0)
        XCTAssertEqual(repository.fetchModule(by: module.id)?.cards.first?.status, .mastered)

        viewModel.restartSession()
        XCTAssertFalse(viewModel.isSessionCompleted)
        XCTAssertEqual(viewModel.currentPosition, 1)
    }
}
