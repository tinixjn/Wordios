import Foundation

protocol StudyOrderStrategy {
    var strategyName: String { get }
    func orderCards(_ cards: [WordCard]) -> [WordCard]
}

// Стратегія 1: послідовна подача карток у тому порядку, в якому вони додані в модуль
struct SequentialStrategy: StudyOrderStrategy {
    let strategyName: String = "По порядку"

    func orderCards(_ cards: [WordCard]) -> [WordCard] {
        return cards
    }
}

// Стратегія 2: випадкове перемішування карток для кращого запам'ятовування
struct RandomShuffleStrategy: StudyOrderStrategy {
    let strategyName: String = "Випадковий порядок"

    func orderCards(_ cards: [WordCard]) -> [WordCard] {
        return cards.shuffled()
    }
}