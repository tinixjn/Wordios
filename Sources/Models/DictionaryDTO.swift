import Foundation

struct DictionaryEntryDTO: Decodable {
    let word: String
    let phonetic: String?
    let phonetics: [PhoneticDTO]?
    let meanings: [MeaningDTO]
    
    var resolvedTranscription: String? {
        if let directPhonetic = phonetic, !directPhonetic.isEmpty {
            return directPhonetic
        }
        return phonetics?.compactMap { $0.text }.first(where: { !$0.isEmpty })
    }
    
    var resolvedSynonyms: [String] {
        var collected: [String] = []
        for meaning in meanings {
            if let meaningSynonyms = meaning.synonyms {
                collected.append(contentsOf: meaningSynonyms)
            }
            if let definitions = meaning.definitions {
                for definition in definitions {
                    if let defSynonyms = definition.synonyms {
                        collected.append(contentsOf: defSynonyms)
                    }
                }
            }
        }
        var seen = Set<String>()
        return collected.filter { seen.insert($0).inserted }
    }
}

struct PhoneticDTO: Decodable {
    let text: String?
    let audio: String?
}

struct MeaningDTO: Decodable {
    let partOfSpeech: String?
    let definitions: [DefinitionDTO]?
    let synonyms: [String]?
}

struct DefinitionDTO: Decodable {
    let definition: String?
    let example: String?
    let synonyms: [String]?
}

extension DictionaryEntryDTO {
    /// Перетворює відповідь Free Dictionary API у проміжний формат адаптера
    func toRawDictionaryWord(translation: String) -> RawDictionaryWord {
        RawDictionaryWord(
            term: word,
            translation: translation,
            transcription: resolvedTranscription,
            synonyms: resolvedSynonyms.joined(separator: ", ")
        )
    }
}