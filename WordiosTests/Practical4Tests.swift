import XCTest
@testable import Wordios

private struct FakeLookupService: DictionaryAPIServiceProtocol {
    let entry: DictionaryEntryDTO?
    let error: NetworkError?

    func fetchWordDetails(for word: String) async throws -> DictionaryEntryDTO {
        if let error = error { throw error }
        guard let entry = entry else { throw NetworkError.emptyResponse }
        return entry
    }
}

private struct FakeTranslationService: TranslationServiceProtocol {
    let text: String?
    let error: TranslationServiceError?

    func translateToUkrainian(_ word: String) async throws -> String {
        if let error = error { throw error }
        return text ?? ""
    }
}

final class Practical4Tests: XCTestCase {
    private func entry(
        synonyms: [String],
        phonetic: String? = "/ˈdʒɜːni/"
    ) -> DictionaryEntryDTO {
        DictionaryEntryDTO(
            word: "journey",
            phonetic: phonetic,
            phonetics: nil,
            meanings: [MeaningDTO(
                partOfSpeech: "noun",
                definitions: nil,
                synonyms: synonyms
            )]
        )
    }

    private var translation: FakeTranslationService {
        FakeTranslationService(text: "подорож", error: nil)
    }

    @MainActor
    func testBothServicesSucceed() async {
        let dictionary = FakeLookupService(entry: entry(synonyms: ["trip", "travel"]), error: nil)
        let model = DictionaryLookupViewModel(service: dictionary, translationService: translation)
        await model.lookup(word: "journey")
        XCTAssertEqual(model.state, .success)
        XCTAssertEqual(model.translationState, .success)
        XCTAssertEqual(model.result?.transcription, "/ˈdʒɜːni/")
        XCTAssertEqual(model.result?.synonyms, ["trip", "travel"])
        XCTAssertEqual(model.result?.translation, "подорож")
    }

    @MainActor
    func testMissingSynonymsStillGivesTranslation() async {
        let dictionary = FakeLookupService(entry: entry(synonyms: []), error: nil)
        let model = DictionaryLookupViewModel(service: dictionary, translationService: translation)
        await model.lookup(word: "journey")
        XCTAssertEqual(model.state, .noSynonyms)
        XCTAssertEqual(model.translationState, .success)
        XCTAssertEqual(model.result?.synonyms, [])
        XCTAssertEqual(model.result?.translation, "подорож")
    }

    @MainActor
    func testNotFound404DoesNotDiscardTranslation() async {
        let dictionary = FakeLookupService(entry: nil, error: .httpError(statusCode: 404))
        let model = DictionaryLookupViewModel(service: dictionary, translationService: translation)
        await model.lookup(word: "unfindable")
        if case .failure(let message) = model.state {
            XCTAssertTrue(message.contains("404"))
        } else {
            XCTFail("Очікувався стан помилки HTTP 404")
        }
        XCTAssertEqual(model.translationState, .success)
        XCTAssertEqual(model.result?.translation, "подорож")
    }

    @MainActor
    func testDictionaryDecodingErrorIsIndependent() async {
        let dictionary = FakeLookupService(entry: nil, error: .decodingError)
        let model = DictionaryLookupViewModel(service: dictionary, translationService: translation)
        await model.lookup(word: "journey")
        if case .failure(let message) = model.state {
            XCTAssertTrue(message.contains("JSON"))
        } else {
            XCTFail("Очікувався стан помилки декодування JSON")
        }
        XCTAssertEqual(model.result?.translation, "подорож")
    }

    @MainActor
    func testTranslationErrorDoesNotDiscardDictionaryData() async {
        let dictionary = FakeLookupService(entry: entry(synonyms: ["trip"]), error: nil)
        let translationFailure = FakeTranslationService(text: nil, error: .httpError(429))
        let model = DictionaryLookupViewModel(
            service: dictionary, translationService: translationFailure
        )
        await model.lookup(word: "journey")
        XCTAssertEqual(model.state, .success)
        if case .failure(let message) = model.translationState {
            XCTAssertTrue(message.contains("429"))
        } else {
            XCTFail("Очікувався стан помилки перекладу")
        }
        XCTAssertEqual(model.result?.synonyms, ["trip"])
        XCTAssertNil(model.result?.translation)
    }

    @MainActor
    func testEmptyTranslationIsErrorButDictionarySucceeds() async {
        let dictionary = FakeLookupService(entry: entry(synonyms: ["trip"]), error: nil)
        let model = DictionaryLookupViewModel(
            service: dictionary,
            translationService: FakeTranslationService(text: "  ", error: nil)
        )
        await model.lookup(word: "journey")
        XCTAssertEqual(model.state, .success)
        if case .failure = model.translationState {
            // expected
        } else {
            XCTFail("Порожній переклад не повинен позначатися як успішний")
        }
    }

    @MainActor
    func testEmptyQueryDoesNotPerformLookup() async {
        let dictionary = FakeLookupService(entry: nil, error: .httpError(statusCode: 404))
        let model = DictionaryLookupViewModel(service: dictionary, translationService: translation)
        await model.lookup(word: "   ")
        XCTAssertEqual(model.state, .idle)
        XCTAssertEqual(model.translationState, .idle)
        XCTAssertNil(model.result)
    }

    func testMyMemoryParsesUkrainianJSON() throws {
        let data = Data(#"{"responseData":{"translatedText":"подорож"},"responseStatus":200,"quotaFinished":false}"#.utf8)
        XCTAssertEqual(try MyMemoryTranslationService.parseResponse(data), "подорож")
    }

    func testMyMemoryDetectsDailyQuota() {
        let data = Data(#"{"responseData":{"translatedText":""},"responseStatus":200,"quotaFinished":true}"#.utf8)
        XCTAssertThrowsError(try MyMemoryTranslationService.parseResponse(data)) { error in
            guard case TranslationServiceError.quotaExceeded = error else {
                XCTFail("Має бути помилка денного ліміту")
                return
            }
        }
    }

    func testMyMemoryDetectsEmptyResult() {
        let data = Data(#"{"responseData":{"translatedText":"  "},"responseStatus":200}"#.utf8)
        XCTAssertThrowsError(try MyMemoryTranslationService.parseResponse(data)) { error in
            guard case TranslationServiceError.emptyTranslation = error else {
                XCTFail("Має бути помилка порожнього перекладу")
                return
            }
        }
    }

    func testMyMemoryDetectsAPIError() {
        let data = Data(#"{"responseData":{},"responseStatus":429}"#.utf8)
        XCTAssertThrowsError(try MyMemoryTranslationService.parseResponse(data)) { error in
            guard case TranslationServiceError.apiError(429) = error else {
                XCTFail("Має бути помилка API 429")
                return
            }
        }
    }
}
