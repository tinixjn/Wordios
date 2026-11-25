import Foundation

enum NetworkError: Error, LocalizedError, Equatable {
    case invalidURL
    case transportError(String)
    case httpError(statusCode: Int)
    case decodingError
    case emptyResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некоректна адреса запиту до словника."
        case .transportError:
            return "Відсутнє з'єднання з інтернетом або сервер недоступний."
        case .httpError(let statusCode):
            if statusCode == 404 {
                return "Слово не знайдено у словнику (помилка 404)."
            }
            return "Помилка сервера (HTTP статус: \(statusCode))."
        case .decodingError:
            return "Не вдалося обробити відповідь від сервера (помилка декодування JSON)."
        case .emptyResponse:
            return "Сервер повернув порожній результат для цього слова."
        }
    }
}

protocol DictionaryAPIServiceProtocol {
    func fetchWordDetails(for word: String) async throws -> DictionaryEntryDTO
}

final class DictionaryAPIService: DictionaryAPIServiceProtocol {
    private let baseURL = "https://api.dictionaryapi.dev/api/v2/entries/en/"
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }
    
    func fetchWordDetails(for word: String) async throws -> DictionaryEntryDTO {
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedWord.isEmpty,
              let encodedWord = trimmedWord.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: baseURL + encodedWord) else {
            throw NetworkError.invalidURL
        }
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw NetworkError.transportError(error.localizedDescription)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.transportError("Некоректна відповідь від сервера.")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let entries: [DictionaryEntryDTO]
        do {
            entries = try decoder.decode([DictionaryEntryDTO].self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
        
        guard let firstEntry = entries.first else {
            throw NetworkError.emptyResponse
        }
        
        return firstEntry
    }
}