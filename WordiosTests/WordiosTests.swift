//
//  WordiosTests.swift
//  WordiosTests
//
//  Created by Костенко Крістіна on 20.11.2026.
//

import XCTest
@testable import Wordios

class WordiosTests: XCTestCase {

    func testAddCard() {
        let module = WordModule(
            title: "Travel",
            level: .a2
        )

        let card = WordCard(
            term: "Journey",
            translation: "Подорож"
        )

        module.addCard(card)

        XCTAssertEqual(module.cards.count, 1)
        XCTAssertEqual(module.cards.first?.term, "Journey")
    }

    func testFilterCardsByStatus() {
        let module = WordModule(
            title: "Travel",
            level: .a2
        )

        let newCard = WordCard(
            term: "Ticket",
            translation: "Квиток",
            status: .new
        )

        let masteredCard = WordCard(
            term: "Airport",
            translation: "Аеропорт",
            status: .mastered
        )

        module.addCard(newCard)
        module.addCard(masteredCard)

        let result = module.filterCards(by: .mastered)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.term, "Airport")
    }

    func testCalculateProgress() {
        let module = WordModule(
            title: "Travel",
            level: .a2
        )

        module.addCard(WordCard(
            term: "Ticket",
            translation: "Квиток",
            status: .new
        ))

        module.addCard(WordCard(
            term: "Airport",
            translation: "Аеропорт",
            status: .mastered
        ))

        XCTAssertEqual(module.calculateProgress(), 50.0)
    }
}
