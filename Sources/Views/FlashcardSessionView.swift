import SwiftUI

@MainActor
struct FlashcardSessionView: View {
    @StateObject private var viewModel: FlashcardSessionViewModel
    @State private var isCardFlipped: Bool = false
    let onSessionChange: () -> Void
    
    init(viewModel: FlashcardSessionViewModel,
         onSessionChange: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSessionChange = onSessionChange
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isSessionCompleted {
                completedView
            } else if let card = viewModel.currentCard {
                progressHeader
                
                Spacer(minLength: 4)
                
                FlashcardCardView(card: card, isFlipped: $isCardFlipped)
                    .id(card.id)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
                
                Spacer(minLength: 4)
                
                actionButtons
            } else {
                Text("У цьому модулі поки немає карток")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Тренування")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Прогрес сесії")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(viewModel.progressText)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.primary)
            }
            
            ProgressView(value: viewModel.progressValue)
                .tint(.accentColor)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 14) {
            Button {
                handleCardAction {
                    viewModel.markAsLearning()
                    onSessionChange()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Ще вчу")
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.orange.opacity(0.15))
                .foregroundColor(.orange)
                .cornerRadius(16)
            }
            
            Button {
                handleCardAction {
                    viewModel.markAsMastered()
                    onSessionChange()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Вивчено")
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
        }
    }
    
    private var completedView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "party.popper.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Тренування завершено!")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            
            Text("Ви повторили всі \(viewModel.cards.count) карток у цьому модулі.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                withAnimation {
                    isCardFlipped = false
                    viewModel.restartSession()
                }
            } label: {
                Text("Пройти ще раз")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    private func handleCardAction(_ action: @escaping () -> Void) {
        withAnimation(.easeInOut(duration: 0.35)) {
            isCardFlipped = false
            action()
        }
    }
}

struct FlashcardSessionView_Previews: PreviewProvider {
    static var previews: some View {
        let repository = MockDictionaryRepository()
        return NavigationView {
            FlashcardSessionView(
                viewModel: FlashcardSessionViewModel(
                    moduleId: repository.fetchModules().first?.id ?? UUID(),
                    repository: repository,
                    strategy: SequentialStrategy()
                )
            )
        }
    }
}