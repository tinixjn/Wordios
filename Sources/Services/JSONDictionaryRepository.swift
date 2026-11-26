import Foundation

/// Локальне JSON-сховище. Реалізує той самий протокол, що й MockDictionaryRepository.
/// Працює без інтернету; після закриття програми картки та їхній статус зберігаються.
final class JSONDictionaryRepository: DictionaryRepositoryProtocol {
    private struct StoredModule: Codable {
        let id: UUID
        let title: String
        let level: EnglishLevel
        let cards: [WordCard]

        init(_ module: WordModule) {
            id = module.id
            title = module.title
            level = module.level
            cards = module.cards
        }

        var model: WordModule {
            WordModule(id: id, title: title, level: level, cards: cards)
        }
    }

    private struct StorageFile: Codable {
        let schemaVersion: Int
        let modules: [StoredModule]
    }

    private enum StorageError: LocalizedError {
        case unsupportedVersion(Int)

        var errorDescription: String? {
            switch self {
            case .unsupportedVersion(let version):
                return "Невідома версія словника: \(version)."
            }
        }
    }

    private let fileURL: URL
    private let repository: MockDictionaryRepository
    private var canSave = true

    /// Шлях можна передати вручну для тестів — без використання реальних даних користувача.
    /// На iOS файл зберігається в Application Support/Wordios/dictionary.json.
    init(fileURL: URL? = nil, seedModules: [WordModule]? = nil) {
        let supportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        self.fileURL = fileURL ?? supportDirectory
            .appendingPathComponent("Wordios", isDirectory: true)
            .appendingPathComponent("dictionary.json")

        let samples = seedModules ?? MockDictionaryRepository().fetchModules()
        let modules: [WordModule]
        var needsWrite = false
        var recoveredFromError = false

        if FileManager.default.fileExists(atPath: self.fileURL.path) {
            do {
                let data = try Data(contentsOf: self.fileURL)
                let stored = try JSONDecoder().decode(StorageFile.self, from: data)
                guard stored.schemaVersion == 1 else {
                    throw StorageError.unsupportedVersion(stored.schemaVersion)
                }
                var existing = stored.modules.map { $0.model }
                needsWrite = Self.addMissingSeedCards(to: &existing, samples: samples)
                modules = existing
            } catch {
                // НЕ перезаписуємо пошкоджений / несумісний файл демоданими.
                NSLog("Wordios: не вдалося прочитати словник (%@). Файл не буде перезаписано.",
                      String(describing: error))
                modules = samples
                recoveredFromError = true
            }
        } else {
            modules = samples
            needsWrite = true
        }

        repository = MockDictionaryRepository(modules: modules)
        canSave = !recoveredFromError
        if needsWrite { saveToDisk() }
    }

    func fetchModules() -> [WordModule] {
        repository.fetchModules()
    }

    func fetchModule(by id: UUID) -> WordModule? {
        repository.fetchModule(by: id)
    }

    func saveModule(_ module: WordModule) {
        repository.saveModule(module)
        saveToDisk()
    }

    func addCard(_ card: WordCard, toModuleId moduleId: UUID) {
        guard repository.fetchModule(by: moduleId) != nil else { return }
        repository.addCard(card, toModuleId: moduleId)
        saveToDisk()
    }

    func updateCardStatus(cardId: UUID, inModuleId moduleId: UUID, to newStatus: LearningStatus) {
        guard let module = repository.fetchModule(by: moduleId),
              module.cards.contains(where: { $0.id == cardId }) else { return }
        repository.updateCardStatus(cardId: cardId, inModuleId: moduleId, to: newStatus)
        saveToDisk()
    }

    private func saveToDisk() {
        guard canSave else { return }
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )
            let file = StorageFile(
                schemaVersion: 1,
                modules: repository.fetchModules().map { StoredModule($0) }
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(file).write(to: fileURL, options: .atomic)
        } catch {
            NSLog("Wordios: не вдалося зберегти словник (%@)", String(describing: error))
        }
    }

    /// Після оновлення застосунку додає НОВІ демословa, але не змінює особисті картки.
    /// Зокрема новий Trip з'явиться навіть у словнику, створеному попередньою версією.
    private static func addMissingSeedCards(
        to existing: inout [WordModule],
        samples: [WordModule]
    ) -> Bool {
        var changed = false
        for sample in samples {
            if let current = existing.first(where: {
                $0.level == sample.level && $0.title == sample.title
            }) {
                for card in sample.cards where current.findCard(term: card.term) == nil {
                    current.addCard(card)
                    changed = true
                }
            } else {
                existing.append(sample)
                changed = true
            }
        }
        return changed
    }
}
