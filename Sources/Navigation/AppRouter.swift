import SwiftUI

/// Єдина точка керування переходами між SwiftUI-екранами (iOS 15.5).
/// View повідомляють про дії через callback, не створюючи NavigationLink самостійно.
@MainActor
struct AppRouter: View {
    private let repository: any DictionaryRepositoryProtocol
    @StateObject private var modulesViewModel: ModulesListViewModel

    @State private var selectedModuleId: UUID? = nil
    @State private var isModulePresented = false
    @State private var isTrainingPresented = false
    @State private var addWordModule: WordModule? = nil

    init(repository: any DictionaryRepositoryProtocol = JSONDictionaryRepository()) {
        self.repository = repository
        _modulesViewModel = StateObject(
            wrappedValue: ModulesListViewModel(repository: repository)
        )
    }

    var body: some View {
        NavigationView {
            ZStack {
                ModulesListView(viewModel: modulesViewModel) { module in
                    selectedModuleId = module.id
                    isModulePresented = true
                }

                NavigationLink(
                    destination: moduleDestination,
                    isActive: $isModulePresented
                ) {
                    EmptyView()
                }
                .hidden()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(item: $addWordModule) { module in
            AddWordSheetView(module: module) { card in
                modulesViewModel.addCard(card, to: module.id)
            }
        }
    }

    @ViewBuilder
    private var moduleDestination: some View {
        if let moduleId = selectedModuleId {
            ZStack {
                ModuleDetailView(
                    moduleId: moduleId,
                    viewModel: modulesViewModel,
                    onStartTraining: {
                        isTrainingPresented = true
                    },
                    onAddWord: {
                        addWordModule = repository.fetchModule(by: moduleId)
                    }
                )

                NavigationLink(
                    destination: trainingDestination(for: moduleId),
                    isActive: $isTrainingPresented
                ) {
                    EmptyView()
                }
                .hidden()
            }
            .onAppear {
                modulesViewModel.refresh()
            }
        } else {
            Text("Модуль не вибрано")
        }
    }

    private func trainingDestination(for moduleId: UUID) -> some View {
        FlashcardSessionView(
            viewModel: FlashcardSessionViewModel(
                moduleId: moduleId,
                repository: repository,
                strategy: SequentialStrategy()
            ),
            onSessionChange: {
                modulesViewModel.refresh()
            }
        )
    }
}
