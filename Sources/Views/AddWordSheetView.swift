import SwiftUI
import Foundation

// MARK: - Dictionary and translation lookup states

enum DictionaryLookupState: Equatable {
    case idle
    case loading
    case success
    case noSynonyms
    case failure(String)
}

enum TranslationLookupState: Equatable {
    case idle
    case loading
    case success
    case failure(String)
}

struct DictionaryLookupResult: Equatable {
    let transcription: String?
    let synonyms: [String]
    let translation: String?
}

// These helpers swallow failures independently: one API may still succeed if the other fails.
private func dictionaryAttempt(
    service: any DictionaryAPIServiceProtocol,
    word: String
) async -> Result<DictionaryEntryDTO, Error> {
    do { return .success(try await service.fetchWordDetails(for: word)) }
    catch { return .failure(error) }
}

private func translationAttempt(
    service: any TranslationServiceProtocol,
    word: String
) async -> Result<String, Error> {
    do { return .success(try await service.translateToUkrainian(word)) }
    catch { return .failure(error) }
}

@MainActor
final class DictionaryLookupViewModel: ObservableObject {
    @Published private(set) var state: DictionaryLookupState = .idle
    @Published private(set) var translationState: TranslationLookupState = .idle
    @Published private(set) var result: DictionaryLookupResult? = nil

    private let service: any DictionaryAPIServiceProtocol
    private let translationService: any TranslationServiceProtocol
    private var requestID = UUID()

    init(
        service: any DictionaryAPIServiceProtocol = DictionaryAPIService(),
        translationService: any TranslationServiceProtocol = MyMemoryTranslationService()
    ) {
        self.service = service
        self.translationService = translationService
    }

    func reset() {
        requestID = UUID()
        result = nil
        state = .idle
        translationState = .idle
    }

    func lookup(
        word: String,
        overrideService: (any DictionaryAPIServiceProtocol)? = nil,
        overrideTranslationService: (any TranslationServiceProtocol)? = nil
    ) async {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            reset()
            return
        }

        let thisRequest = UUID()
        requestID = thisRequest
        state = .loading
        translationState = .loading
        result = nil

        // Resolve actor-owned dependencies before starting concurrent operations.
        let selectedDictionaryService = overrideService ?? service
        let selectedTranslationService = overrideTranslationService ?? translationService
        // The two requests run concurrently, but failures are handled separately.
        async let dictionaryResponse = dictionaryAttempt(
            service: selectedDictionaryService,
            word: trimmed
        )
        async let translatedResponse = translationAttempt(
            service: selectedTranslationService,
            word: trimmed
        )
        let (dictionaryOutcome, translationOutcome) = await (dictionaryResponse, translatedResponse)
        guard requestID == thisRequest, !Task.isCancelled else { return }

        var ipa: String? = nil
        var synonyms: [String] = []
        var translatedText: String? = nil

        switch dictionaryOutcome {
        case .success(let entry):
            let rawIPA = entry.resolvedTranscription?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            ipa = (rawIPA?.isEmpty == false) ? rawIPA : nil
            synonyms = DictionaryWordAdapter()
                .parseSynonyms(entry.resolvedSynonyms.joined(separator: ", "))
            state = synonyms.isEmpty ? .noSynonyms : .success
        case .failure(let error):
            state = .failure((error as? LocalizedError)?.errorDescription
                ?? "Не вдалося отримати словникові дані. Перевірте інтернет.")
        }

        switch translationOutcome {
        case .success(let translation):
            let clean = translation.trimmingCharacters(in: .whitespacesAndNewlines)
            if clean.isEmpty {
                translationState = .failure(TranslationServiceError.emptyTranslation.errorDescription
                    ?? "Переклад порожній.")
            } else {
                translatedText = clean
                translationState = .success
            }
        case .failure(let error):
            translationState = .failure((error as? LocalizedError)?.errorDescription
                ?? "Не вдалося отримати переклад українською.")
        }

        // Keep whichever API succeeded. The form can still save manually supplied fields.
        if ipa != nil || !synonyms.isEmpty || translatedText != nil {
            result = DictionaryLookupResult(
                transcription: ipa,
                synonyms: synonyms,
                translation: translatedText
            )
        }
    }
}

#if DEBUG
// MARK: - Reproducible demo scenarios (Debug only)

private enum DictionaryDebugScenario: String, CaseIterable, Identifiable {
    case live = "Реальний API"
    case success = "Успішна відповідь"
    case noSynonyms = "Немає синонімів"
    case notFound = "HTTP 404"
    case badJSON = "Помилка JSON"
    case offline = "Мережевий збій"

    var id: String { rawValue }

    var service: (any DictionaryAPIServiceProtocol)? {
        switch self {
        case .live: return nil
        case .success: return DemoDictionaryService(withSynonyms: true)
        case .noSynonyms: return DemoDictionaryService(withSynonyms: false)
        case .notFound:
            return FailingDictionaryService(error: .httpError(statusCode: 404))
        case .badJSON:
            return FailingDictionaryService(error: .decodingError)
        case .offline:
            return FailingDictionaryService(error: .transportError("Демонстрація"))
        }
    }
}

struct FailingDictionaryService: DictionaryAPIServiceProtocol {
    let error: NetworkError

    func fetchWordDetails(for word: String) async throws -> DictionaryEntryDTO {
        try await Task.sleep(nanoseconds: 800_000_000) // видно спінер під час демонстрації
        throw error
    }
}

private struct DemoDictionaryService: DictionaryAPIServiceProtocol {
    let withSynonyms: Bool

    func fetchWordDetails(for word: String) async throws -> DictionaryEntryDTO {
        try await Task.sleep(nanoseconds: 800_000_000)
        return DictionaryEntryDTO(
            word: word,
            phonetic: "/ˈdɛm.əʊ/",
            phonetics: nil,
            meanings: [MeaningDTO(
                partOfSpeech: "noun",
                definitions: nil,
                synonyms: withSynonyms ? ["example", "sample"] : []
            )]
        )
    }
}

private enum TranslationDebugScenario: String, CaseIterable, Identifiable {
    case live = "Реальний переклад"
    case success = "Успішний переклад"
    case noTranslation = "Порожній переклад"
    case unavailable = "Помилка перекладу (429)"

    var id: String { rawValue }

    var service: (any TranslationServiceProtocol)? {
        switch self {
        case .live: return nil
        case .success: return DemoTranslationService(error: nil)
        case .noTranslation: return DemoTranslationService(error: .emptyTranslation)
        case .unavailable: return DemoTranslationService(error: .httpError(429))
        }
    }
}

private struct DemoTranslationService: TranslationServiceProtocol {
    let error: TranslationServiceError?

    func translateToUkrainian(_ word: String) async throws -> String {
        try await Task.sleep(nanoseconds: 800_000_000)
        if let error = error { throw error }
        // A clearly artificial sample, not a claim about what the live API returns.
        return "демонстраційний переклад"
    }
}
#endif

// MARK: - Add-word sheet

@MainActor
struct AddWordSheetView: View {
    let module: WordModule
    let onSave: (WordCard) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @StateObject private var lookupModel = DictionaryLookupViewModel()
    @State private var lookupTask: Task<Void, Never>? = nil

    @State private var term = ""
    @State private var translation = ""
    @State private var transcription = ""
    @State private var synonyms = ""
    @State private var errorMessage: String? = nil

    #if DEBUG
    @State private var demoScenario: DictionaryDebugScenario = .live
    @State private var translationDemoScenario: TranslationDebugScenario = .live
    #endif

    private enum Field: Hashable {
        case term, translation, transcription, synonyms
    }

    private var isValid: Bool {
        !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasLookupTerm: Bool {
        !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Модуль: \(module.title) · \(module.level.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Англійське слово *")
                            .font(.subheadline.weight(.semibold))
                        TextField("Наприклад, Journey", text: $term)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($focusedField, equals: .term)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .translation }
                            .onChange(of: term) { _ in
                                // New word = new form data; never keep stale API values.
                                invalidateLookup(clearFields: true)
                            }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            fetchDictionaryData()
                        } label: {
                            Label("Автозаповнити дані слова",
                                  systemImage: "arrow.down.doc")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!hasLookupTerm || lookupModel.state == .loading ||
                                  lookupModel.translationState == .loading)

                        #if DEBUG
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Демонстрація API (Debug)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            // Explicit menu actions work even when the same scenario is selected
                            // again after an error (Picker.onChange would not run in that case).
                            Menu {
                                ForEach(DictionaryDebugScenario.allCases) { scenario in
                                    Button {
                                        selectDictionaryScenario(scenario)
                                    } label: {
                                        Label(scenario.rawValue,
                                              systemImage: demoScenario == scenario
                                                  ? "checkmark.circle.fill" : "circle")
                                    }
                                }
                            } label: {
                                Label("Словник: \(demoScenario.rawValue)",
                                      systemImage: "chevron.down.circle")
                                    .font(.subheadline)
                            }

                            Menu {
                                ForEach(TranslationDebugScenario.allCases) { scenario in
                                    Button {
                                        selectTranslationScenario(scenario)
                                    } label: {
                                        Label(scenario.rawValue,
                                              systemImage: translationDemoScenario == scenario
                                                  ? "checkmark.circle.fill" : "circle")
                                    }
                                }
                            } label: {
                                Label("Переклад: \(translationDemoScenario.rawValue)",
                                      systemImage: "chevron.down.circle")
                                    .font(.subheadline)
                            }

                            Button {
                                invalidateLookup(clearFields: true)
                            } label: {
                                Label("Очистити результати (слово залишиться)",
                                      systemImage: "arrow.counterclockwise")
                                    .font(.caption)
                            }
                            .disabled(!hasLookupTerm && translation.isEmpty &&
                                      transcription.isEmpty && synonyms.isEmpty)

                        }
                        #endif

                        lookupStatusView
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Переклад *")
                            .font(.subheadline.weight(.semibold))
                        TextField("Наприклад, Подорож", text: $translation)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($focusedField, equals: .translation)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .transcription }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Транскрипція (необов'язково)")
                            .font(.subheadline.weight(.semibold))
                        TextField("/ˈdʒɜːrni/", text: $transcription)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($focusedField, equals: .transcription)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .synonyms }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Синоніми (необов'язково)")
                            .font(.subheadline.weight(.semibold))
                        TextField("trip, voyage; travel", text: $synonyms)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($focusedField, equals: .synonyms)
                            .submitLabel(.done)
                            .onSubmit { focusedField = nil }
                        Text("Відокремлюйте синоніми комою або крапкою з комою.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }

                    // Кнопка збереження лишається в прокручуваній формі.
                    Button { save() } label: {
                        Text("Зберегти слово")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid || lookupModel.state == .loading ||
                              lookupModel.translationState == .loading)
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .navigationTitle("Додати слово")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Скасувати") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") { focusedField = nil }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onDisappear { lookupTask?.cancel() }
    }

    private var lookupStatusView: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch lookupModel.state {
            case .idle:
                EmptyView()
            case .loading:
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Шукаємо транскрипцію та синоніми…")
                        .font(.subheadline)
                }
            case .success:
                Label("Словникові дані отримано.", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.green)
            case .noSynonyms:
                Label("Синонімів немає; транскрипцію додано, якщо вона доступна.",
                      systemImage: "info.circle")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            case .failure(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }

            switch lookupModel.translationState {
            case .idle:
                EmptyView()
            case .loading:
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Перекладаємо українською…")
                        .font(.subheadline)
                }
            case .success:
                Label("Український переклад отримано.", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.green)
            case .failure(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }

            if case .failure = lookupModel.state {
                Button("Спробувати ще раз") { fetchDictionaryData() }
                    .font(.subheadline.weight(.semibold))
                    .disabled(!hasLookupTerm)
            } else if case .failure = lookupModel.translationState {
                Button("Спробувати ще раз") { fetchDictionaryData() }
                    .font(.subheadline.weight(.semibold))
                    .disabled(!hasLookupTerm)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func invalidateLookup(clearFields: Bool = false) {
        lookupTask?.cancel()
        lookupTask = nil
        lookupModel.reset()
        if clearFields {
            // Keep the English word, discard values from the previous API response.
            translation = ""
            transcription = ""
            synonyms = ""
            errorMessage = nil
        }
    }

    #if DEBUG
    private func selectDictionaryScenario(_ scenario: DictionaryDebugScenario) {
        demoScenario = scenario
        invalidateLookup(clearFields: true)
    }

    private func selectTranslationScenario(_ scenario: TranslationDebugScenario) {
        translationDemoScenario = scenario
        invalidateLookup(clearFields: true)
    }
    #endif

    private func fetchDictionaryData() {
        guard hasLookupTerm else { return }
        focusedField = nil
        // Also clear the form on retry / repeated lookup of the SAME English word.
        invalidateLookup(clearFields: true)
        let queriedWord = term.trimmingCharacters(in: .whitespacesAndNewlines)

        #if DEBUG
        let fakeService = demoScenario.service
        let fakeTranslationService = translationDemoScenario.service
        #else
        let fakeService: (any DictionaryAPIServiceProtocol)? = nil
        let fakeTranslationService: (any TranslationServiceProtocol)? = nil
        #endif

        lookupTask = Task {
            await lookupModel.lookup(
                word: queriedWord,
                overrideService: fakeService,
                overrideTranslationService: fakeTranslationService
            )
            guard !Task.isCancelled else { return }
            guard term.trimmingCharacters(in: .whitespacesAndNewlines) == queriedWord else { return }
            guard let retrieved = lookupModel.result else { return }

            // Preserve edits typed while requests are in flight. Old lookup values
            // were already cleared when this request started.
            if let newTranslation = retrieved.translation,
               translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                translation = newTranslation
            }
            if let newTranscription = retrieved.transcription,
               transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                transcription = newTranscription
            }
            if !retrieved.synonyms.isEmpty,
               synonyms.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                synonyms = retrieved.synonyms.joined(separator: ", ")
            }
        }
    }

    private func save() {
        guard isValid else { return }
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        if module.findCard(term: trimmedTerm) != nil {
            errorMessage = "Це слово вже є в модулі."
            return
        }
        let card = DictionaryWordAdapter().adapt(
            RawDictionaryWord(
                term: term,
                translation: translation,
                transcription: transcription,
                synonyms: synonyms
            )
        )
        onSave(card)
        focusedField = nil
        dismiss()
    }
}