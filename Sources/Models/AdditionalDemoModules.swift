import Foundation

/// Два додаткові набори для практичної №3: B1 і C1.
/// A2 продовжує зберігатися в MockDictionaryRepository.
enum AdditionalDemoModules {
    static func makeModules() -> [WordModule] {
        let work = WordModule(
            title: "Робота й кар'єра",
            level: .b1,
            cards: [
                WordCard(term: "Interview", translation: "Співбесіда", transcription: "/ˈɪntəvjuː/", synonyms: ["meeting", "conversation"], status: .mastered),
                WordCard(term: "Deadline", translation: "Кінцевий термін", synonyms: ["due date", "time limit"]),
                WordCard(term: "Colleague", translation: "Колега", synonyms: ["coworker", "teammate"]),
                WordCard(term: "Coworker", translation: "Колега по роботі", synonyms: ["colleague", "teammate", "associate"]),
                WordCard(term: "Salary", translation: "Заробітна плата", synonyms: ["pay", "wage"]),
                WordCard(term: "Promotion", translation: "Підвищення", synonyms: ["advancement"]),
                WordCard(term: "Responsibility", translation: "Відповідальність", synonyms: ["duty", "obligation"]),
                WordCard(term: "Schedule", translation: "Розклад", synonyms: ["timetable", "plan"]),
                WordCard(term: "Experience", translation: "Досвід", synonyms: ["practice", "background"]),
                WordCard(term: "Application", translation: "Заява на роботу", synonyms: ["request", "submission"]),
                WordCard(term: "Achievement", translation: "Досягнення", synonyms: ["accomplishment", "success"])
            ]
        )

        let technology = WordModule(
            title: "Наука й технології",
            level: .c1,
            cards: [
                WordCard(term: "Breakthrough", translation: "Прорив", synonyms: ["discovery", "advance"]),
                WordCard(term: "Innovation", translation: "Нововведення", synonyms: ["invention", "advance"]),
                WordCard(term: "Hypothesis", translation: "Гіпотеза", synonyms: ["assumption", "proposition"]),
                WordCard(term: "Feasibility", translation: "Здійсненність", synonyms: ["practicality", "viability"]),
                WordCard(term: "Sustainability", translation: "Сталий розвиток", synonyms: ["durability", "continuity"]),
                WordCard(term: "Algorithm", translation: "Алгоритм", synonyms: ["procedure", "method"]),
                WordCard(term: "Infrastructure", translation: "Інфраструктура", synonyms: ["framework", "foundation"]),
                WordCard(term: "Implementation", translation: "Реалізація", synonyms: ["execution", "application"]),
                WordCard(term: "Reliability", translation: "Надійність", synonyms: ["dependability", "consistency"]),
                WordCard(term: "Evaluation", translation: "Оцінювання", synonyms: ["assessment", "appraisal"])
            ]
        )
        return [work, technology]
    }
}
