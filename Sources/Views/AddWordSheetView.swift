import SwiftUI

/// Форма додавання слова: валідація, перетворення через Adapter і callback збереження.
struct AddWordSheetView: View {
    let module: WordModule
    let onSave: (WordCard) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var term = ""
    @State private var translation = ""
    @State private var transcription = ""
    @State private var synonyms = ""
    @State private var errorMessage: String? = nil

    private enum Field: Hashable {
        case term, translation, transcription, synonyms
    }

    private var isValid: Bool {
        !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

                    // Кнопка є частиною форми, тому не висить над клавіатурою.
                    Button(action: { save() }) {
                        Text("Зберегти слово")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
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
