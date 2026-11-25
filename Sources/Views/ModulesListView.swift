import SwiftUI

/// Екран модулів: тільки UI, стан і фільтрація — у ModulesListViewModel.
@MainActor
struct ModulesListView: View {
    @ObservedObject var viewModel: ModulesListViewModel
    let onSelectModule: (WordModule) -> Void

    var body: some View {
        List {
            Section(header: Text("Рівень англійської")) {
                Picker("Фільтр", selection: $viewModel.selectedLevel) {
                    Text("Усі рівні").tag(Optional<EnglishLevel>.none)
                    ForEach(EnglishLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(Optional(level))
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }

            Section(header: Text("Тематичні модулі")) {
                if viewModel.visibleModules.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Модулів для цього рівня поки немає")
                            .font(.headline)
                        Text("Спробуйте вибрати інший рівень або переглянути всі модулі.")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 12)
                } else {
                    ForEach(viewModel.visibleModules) { module in
                        Button {
                            onSelectModule(module)
                        } label: {
                            moduleRow(module)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Wordios")
        .onAppear {
            viewModel.refresh()
        }
    }

    private func moduleRow(_ module: WordModule) -> some View {
        let percentage = viewModel.progress(for: module)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(module.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("\(module.level.rawValue) · \(module.cards.count) слів")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(String(format: "%.0f%%", percentage))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.accentColor)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: percentage, total: 100)
                .tint(.accentColor)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}
