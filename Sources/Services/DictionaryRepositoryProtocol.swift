import Foundation

// Принцип інверсії залежностей (DIP): ViewModel залежить від протоколу, а не від конкретної реалізації сховища
protocol DictionaryRepositoryProtocol {
    func fetchModules() -> [WordModule]
    func fetchModule(by id: UUID) -> WordModule?
    func saveModule(_ module: WordModule)
    func addCard(_ card: WordCard, toModuleId moduleId: UUID)
    func updateCardStatus(cardId: UUID, inModuleId moduleId: UUID, to newStatus: LearningStatus)
}