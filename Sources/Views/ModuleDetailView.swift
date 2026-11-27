import SwiftUI

/// Деталі словникового модуля. Навігацією керує AppRouter.
@MainActor
struct ModuleDetailView: View {
    let moduleId: UUID
    @ObservedObject var viewModel: ModulesListViewModel
    let onStartTraining: () -> Void
    let onAddWord: () -> Void

    @State private var firstComparedCardId: UUID? = nil
    @State private var secondComparedCardId: UUID? = nil

    private var module: WordModule? {
        viewModel.modules.first(where: { $0.id == moduleId })
    }

    private var firstComparedCard: WordCard? {
        module?.cards.first(where: { $0.id == firstComparedCardId })
    }

    private var secondComparedCard: WordCard? {
        module?.cards.first(where: { $0.id == secondComparedCardId })
    }

    var body: some View {
        Group {
            if let module = module {
                List {
                    Section(header: Text("Про модуль")) {
                        HStack {
                            Label(module.level.rawValue, systemImage: "graduationcap")
                            Spacer()
                            Text("\(module.cards.count) слів")
                                .foregroundColor(.secondary)
                        }
                        ProgressView(value: module.calculateProgress(), total: 100)
                        Text("Вивчено: \(Int(module.calculateProgress()))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Section(header: Text("Слова")) {
                        if module.cards.isEmpty {
                            Text("У модулі ще немає слів. Додайте перше слово.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(module.cards) { card in
                                wordRow(card)
                            }
                        }
                    }

                    Section(header: Text("Порівняння синонімів")) {
                        if module.cards.count < 2 {
                            Text("Для порівняння потрібно щонайменше два слова.")
                                .foregroundColor(.secondary)
                        } else {
                            Text("Натисніть «Порівняти» біля двох слів.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let first = firstComparedCard,
                               let second = secondComparedCard {
                                comparisonResult(first, second)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle(module.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: onAddWord) {
                            Image(systemName: "plus")
                                .accessibilityLabel("Додати слово")
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Button(action: onStartTraining) {
                        Label("Почати тренування", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(module.cards.isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                }
            } else {
                Text("Модуль не знайдено")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear { viewModel.refresh() }
    }

    private func wordRow(_ card: WordCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(card.term)
                    .font(.headline)
                Spacer()
                Text(card.status.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(card.translation)
                .font(.subheadline)
            if let transcription = card.transcription,
               !transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(transcription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if !card.synonyms.isEmpty {
                Text("Синоніми: \(card.synonyms.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                selectForComparison(card.id)
            } label: {
                Label(comparisonButtonLabel(for: card.id), systemImage: "equal.square")
                    .font(.caption)
            }
            .disabled((module?.cards.count ?? 0) < 2)
        }
        .padding(.vertical, 5)
    }

    private func comparisonButtonLabel(for id: UUID) -> String {
        if firstComparedCardId == id { return "Слово 1 вибрано" }
        if secondComparedCardId == id { return "Слово 2 вибрано" }
        return "Порівняти"
    }

    private func selectForComparison(_ id: UUID) {
        if firstComparedCardId == id {
            firstComparedCardId = secondComparedCardId
            secondComparedCardId = nil
        } else if secondComparedCardId == id {
            secondComparedCardId = nil
        } else if firstComparedCardId == nil {
            firstComparedCardId = id
        } else {
            secondComparedCardId = id
        }
    }

    private func comparisonResult(_ first: WordCard, _ second: WordCard) -> some View {
        let adapter = DictionaryWordAdapter()
        let common = adapter.commonSynonyms(first.synonyms, second.synonyms)

        return VStack(alignment: .leading, spacing: 8) {
            Text("\(first.term) ↔ \(second.term)")
                .font(.subheadline.weight(.semibold))

            if first.synonyms.isEmpty || second.synonyms.isEmpty {
                Text("Для одного зі слів не вказані синоніми.")
                    .foregroundColor(.secondary)
            } else if adapter.synonymsMatch(first.synonyms, second.synonyms) {
                Label("Набори синонімів повністю збігаються", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if !common.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Є частковий збіг синонімів", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Спільні: \(common.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Label("Спільних синонімів не знайдено", systemImage: "info.circle")
                    .foregroundColor(.orange)
            }
        }
        .font(.subheadline)
    }
}
