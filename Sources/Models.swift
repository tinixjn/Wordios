import Foundation

enum EnglishLevel: String, CaseIterable, Codable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"
    case c1 = "C1"
    case c2 = "C2"
}

enum LearningStatus: String, Codable {
    case new = "Нове"
    case learning = "В процесі"
    case mastered = "Вивчено"
}

struct WordCard: Identifiable, Codable {
    let id: UUID
    let term: String
    var translation: String
    var transcription: String? 
    var synonyms: [String]     
    var status: LearningStatus

    init(
        id: UUID = UUID(),
        term: String,
        translation: String,
        transcription: String? = nil,
        synonyms: [String] = [],
        status: LearningStatus = .new
    ) {
        self.id = id
        self.term = term
        self.translation = translation
        self.transcription = transcription
        self.synonyms = synonyms
        self.status = status
    }

    mutating func updateStatus(to newStatus: LearningStatus) {
        self.status = newStatus
    }
}

protocol DeckManageable {
    var title: String { get }
    var level: EnglishLevel { get }
    var cards: [WordCard] { get set }

    func addCard(_ card: WordCard)
    func filterCards(by status: LearningStatus) -> [WordCard]
    func calculateProgress() -> Double
}