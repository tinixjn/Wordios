import SwiftUI

@MainActor
final class FlashcardSessionViewModel: ObservableObject {
    @Published private(set) var cards: [WordCard]
    @Published private(set) var currentIndex: Int = 0
    @Published var isSessionCompleted: Bool = false
    
    init(cards: [WordCard] = FlashcardSessionViewModel.sampleCards) {
        self.cards = cards
    }
    
    var currentCard: WordCard? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }
    
    var progressText: String {
        guard !cards.isEmpty else { return "0 з 0" }
        let displayIndex = min(currentIndex + 1, cards.count)
        return "\(displayIndex) з \(cards.count)"
    }
    
    var progressValue: Double {
        guard !cards.isEmpty else { return 0 }
        return Double(currentIndex) / Double(cards.count)
    }
    
    func markAsLearning() {
        updateCurrentCardStatus(to: .learning)
        advanceToNextCard()
    }
    
    func markAsMastered() {
        updateCurrentCardStatus(to: .mastered)
        advanceToNextCard()
    }
    
    func restartSession() {
        currentIndex = 0
        isSessionCompleted = false
    }
    
    private func updateCurrentCardStatus(to newStatus: LearningStatus) {
        guard currentIndex < cards.count else { return }
        cards[currentIndex].updateStatus(to: newStatus)
    }
    
    private func advanceToNextCard() {
        if currentIndex + 1 < cards.count {
            currentIndex += 1
        } else {
            isSessionCompleted = true
        }
    }
    
    static var sampleCards: [WordCard] {
        [
            WordCard(
                term: "Itinerary",
                translation: "Маршрут подорожі",
                transcription: "/aɪˈtɪn.ə.rer.i/",
                synonyms: [
                    "Route — загальний напрямок руху",
                    "Schedule — розклад поїздки за часом",
                    "Travel plan — детальний план подорожі"
                ],
                status: .new
            ),
            WordCard(
                term: "Departure",
                translation: "Відправлення, виліт",
                transcription: "/dɪˈpɑːr.tʃər/",
                synonyms: [
                    "Takeoff — момент зльоту літака",
                    "Leaving — виїзд із місця перебування"
                ],
                status: .learning
            ),
            WordCard(
                term: "Accommodation",
                translation: "Житло, розміщення",
                transcription: "/əˌkɑː.məˈdeɪ.ʃən/",
                synonyms: [
                    "Lodging — тимчасове житло на час поїздки",
                    "Housing — загальне поняття житла"
                ],
                status: .new
            )
        ]
    }
}

struct FlashcardSessionView: View {
    @StateObject private var viewModel: FlashcardSessionViewModel
    @State private var isCardFlipped: Bool = false
    
    init(viewModel: FlashcardSessionViewModel = FlashcardSessionViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
        NavigationView {
            FlashcardSessionView()
        }
    }
}