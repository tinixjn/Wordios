import Foundation

enum DemoData {
    static func runPracticalOneDemo() {
        print("=== Wordios: Практична робота №1 ===")

        let travelModule = WordModule(title: "Подорожі", level: .a2)

        let starterCards: [WordCard] = [
                    WordCard(term: "Journey", translation: "Подорож", transcription: "/ˈdʒɜːrni/", synonyms: ["trip", "travel"]),
                    WordCard(term: "Ticket", translation: "Квиток", transcription: "/ˈtɪkɪt/", synonyms: ["pass"]),
                    WordCard(term: "Luggage", translation: "Багаж", transcription: "/ˈlʌɡɪdʒ/", synonyms: ["baggage"]),
                    WordCard(term: "Destination", translation: "Місце призначення", synonyms: []),
                    WordCard(term: "Airport", translation: "Аеропорт", transcription: "/ˈeəpɔːrt/"),
                    WordCard(term: "Passport", translation: "Паспорт", transcription: "/ˈpɑːspɔːrt/"),
                    WordCard(term: "Suitcase", translation: "Валіза", synonyms: ["case"]),
                    WordCard(term: "Hotel", translation: "Готель", transcription: "/həʊˈtel/", synonyms: ["inn"]),
                    WordCard(term: "Map", translation: "Мапа", transcription: "/mæp/"),
                    WordCard(term: "Departure", translation: "Відправлення", synonyms: ["leaving"])
        ]

        for card in starterCards {
            travelModule.addCard(card)
        }

        print("Модуль: \(travelModule.title)")
        print("Рівень: \(travelModule.level.rawValue)")
        print("Кількість слів: \(travelModule.cards.count)")

        if let journey = travelModule.findCard(term: "Journey") {
            travelModule.updateCardStatus(id: journey.id, to: .mastered)
        }

        print("\nВивчені слова:")
        for card in travelModule.filterCards(by: .mastered) {
            print("- \(card.term): \(card.translation)")
            print(travelModule.displayTranscription(for: card))
        }

        if let destination = travelModule.findCard(term: "Destination") {
            print("\n\(destination.term):")
            print(travelModule.displayTranscription(for: destination))
        }

        print("\nПрогрес: \(travelModule.calculateProgress())%")
    }
}
