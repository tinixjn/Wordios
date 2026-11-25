import Foundation

/// Дані у форматі, який може надходити з зовнішнього словника.
struct RawDictionaryWord {
    let term: String
    let translation: String
    let transcription: String?
    /// Синоніми у вигляді рядка: "trip, journey; voyage".
    let synonyms: String
}

/// Adapter: перетворює зовнішній формат слова на внутрішню модель WordCard.
struct DictionaryWordAdapter {
    func adapt(_ raw: RawDictionaryWord) -> WordCard {
        let transcription = raw.transcription?.trimmingCharacters(in: .whitespacesAndNewlines)

        return WordCard(
            term: raw.term.trimmingCharacters(in: .whitespacesAndNewlines),
            translation: raw.translation.trimmingCharacters(in: .whitespacesAndNewlines),
            transcription: transcription?.isEmpty == true ? nil : transcription,
            synonyms: parseSynonyms(raw.synonyms)
        )
    }

    /// Прибирає зайві пропуски та дублікати без урахування регістру.
    func parseSynonyms(_ raw: String) -> [String] {
        let parts = raw.components(separatedBy: CharacterSet(charactersIn: ",;\n"))
        var seen = Set<String>()
        var result: [String] = []

        for part in parts {
            let word = part.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = word.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            if !word.isEmpty && seen.insert(key).inserted {
                result.append(word)
            }
        }
        return result
    }

    /// Стабільний формат для порівняння наборів синонімів.
    func formatSynonymsForComparison(_ synonyms: [String]) -> String {
        let normalized = parseSynonyms(synonyms.joined(separator: ","))
            .map { $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil) }
            .sorted()
        return normalized.joined(separator: ", ")
    }

    func synonymsMatch(_ lhs: [String], _ rhs: [String]) -> Bool {
        formatSynonymsForComparison(lhs) == formatSynonymsForComparison(rhs)
    }
}
