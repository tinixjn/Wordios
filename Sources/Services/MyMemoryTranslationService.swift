import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Translation API (English → Ukrainian)

/// Allows a real service and a deterministic fake to be interchanged during tests.
protocol TranslationServiceProtocol {
    func translateToUkrainian(_ word: String) async throws -> String
}

enum TranslationServiceError: LocalizedError {
    case emptyWord
    case tooLong
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(Int)
    case quotaExceeded
    case decodingError
    case emptyTranslation
    case networkError

    var errorDescription: String? {
        switch self {
        case .emptyWord:
            return "Введіть англійське слово для перекладу."
        case .tooLong:
            return "Запит на переклад занадто довгий (максимум 500 байтів)."
        case .invalidURL, .invalidResponse:
            return "Сервіс перекладу повернув некоректну відповідь."
        case .httpError(let code):
            return "Сервіс перекладу недоступний (HTTP \(code))."
        case .apiError(let code):
            return "Сервіс перекладу повідомив про помилку (код \(code))."
        case .quotaExceeded:
            return "Денний ліміт безплатних перекладів вичерпано. Можна ввести переклад вручну."
        case .decodingError:
            return "Не вдалося обробити JSON-відповідь сервісу перекладу."
        case .emptyTranslation:
            return "Сервіс не повернув український переклад. Введіть його вручну."
        case .networkError:
            return "Не вдалося зв'язатися із сервісом перекладу. Перевірте інтернет."
        }
    }
}

/// Public MyMemory GET API: no key needed for the anonymous limit.
/// Docs: https://mymemory.translated.net/doc/spec.php
struct MyMemoryTranslationService: TranslationServiceProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func translateToUkrainian(_ word: String) async throws -> String {
        let text = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw TranslationServiceError.emptyWord }
        guard text.lengthOfBytes(using: .utf8) <= 500 else {
            throw TranslationServiceError.tooLong
        }

        var components = URLComponents(string: "https://api.mymemory.translated.net/get")
        components?.queryItems = [
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "langpair", value: "en|uk")
        ]
        guard let url = components?.url else { throw TranslationServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw TranslationServiceError.invalidResponse
            }
            guard (200...299).contains(http.statusCode) else {
                throw TranslationServiceError.httpError(http.statusCode)
            }
            return try Self.parseResponse(data)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as TranslationServiceError {
            throw error
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch is DecodingError {
            throw TranslationServiceError.decodingError
        } catch {
            throw TranslationServiceError.networkError
        }
    }

    /// Kept separate so real API JSON can be tested without the network.
    static func parseResponse(_ data: Data) throws -> String {
        let envelope = try JSONDecoder().decode(MyMemoryResponse.self, from: data)
        if envelope.quotaFinished == true {
            throw TranslationServiceError.quotaExceeded
        }
        guard let code = envelope.responseStatus, code == 200 else {
            throw TranslationServiceError.apiError(envelope.responseStatus ?? 0)
        }
        guard let text = envelope.responseData?.translatedText?
            .trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            throw TranslationServiceError.emptyTranslation
        }
        return text
    }
}

private struct MyMemoryResponse: Decodable {
    let responseData: MyMemoryTranslationPayload?
    let responseStatus: Int?
    let quotaFinished: Bool?
}

private struct MyMemoryTranslationPayload: Decodable {
    let translatedText: String?
}
