import SwiftUI

struct FlashcardSessionView: View {
    @ObservedObject var viewModel: FlashcardSessionViewModel
    @State private var isCardFlipped: Bool = false
    @State private var isSessionCompleted: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            if isSessionCompleted {
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
        .navigationTitle(viewModel.module?.title ?? "Тренування")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Прогрес сесії")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(viewModel.currentPosition) з \(viewModel.totalCount)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.primary)
            }
            
            ProgressView(
                value: Double(max(viewModel.currentPosition - 1, 0)),
                total: Double(max(viewModel.totalCount, 1))
            )
            .tint(.accentColor)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 14) {
            Button {
                handleCardAction(status: .learning)
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
                handleCardAction(status: .mastered)
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
            
            Text("Ви повторили всі \(viewModel.totalCount) карток у цьому модулі.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
    
    private func handleCardAction(status: LearningStatus) {
        withAnimation(.easeInOut(duration: 0.35)) {
            isCardFlipped = false
            viewModel.markCurrentCard(as: status)
            if viewModel.canAdvance {
                viewModel.advance()
            } else {
                isSessionCompleted = true
            }
        }
    }
}

struct FlashcardSessionView_Previews: PreviewProvider {
    static var previews: some View {
        let repository = MockDictionaryRepository()
        let moduleId = repository.fetchModules().first?.id ?? UUID()
        let viewModel = FlashcardSessionViewModel(
            moduleId: moduleId,
            repository: repository,
            strategy: SequentialStrategy()
        )
        
        return NavigationView {
            FlashcardSessionView(viewModel: viewModel)
        }
    }
}