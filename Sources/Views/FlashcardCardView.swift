import SwiftUI

struct FlashcardCardView: View {
    let card: WordCard
    @Binding var isFlipped: Bool
    
    var body: some View {
        ZStack {
            frontSide
                .opacity(isFlipped ? 0.0 : 1.0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
            
           backSide
                .opacity(isFlipped ? 1.0 : 0.0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )
        }
        .frame(maxWidth: .infinity, minHeight: 320, maxHeight: 420)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                isFlipped.toggle()
            }
        }
    }
    
    private var frontSide: some View {
        VStack(spacing: 16) {
            HStack {
                Text(statusBadgeText)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusBadgeColor.opacity(0.15))
                    .foregroundColor(statusBadgeColor)
                    .clipShape(Capsule())
                
                Spacer()
                
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(card.term)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
            
            if let transcription = card.transcription, !transcription.isEmpty {
                Text(transcription)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Text("Натисніть, щоб побачити переклад")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var backSide: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Переклад")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(card.translation)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.75)
                .lineLimit(3)
            
            Divider()
            
            Text("Синоніми та відтінки значення")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            
            if card.synonyms.isEmpty {
                Text("Синоніми для цього слова не вказані.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(card.synonyms, id: \.self) { synonym in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)
                                
                                Text(synonym)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        }
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.accentColor.opacity(0.35), lineWidth: 1.5)
        )
    }
    
    
    private var statusBadgeText: String {
        switch card.status {
        case .new: return "Нове"
        case .learning: return "Ще вчу"
        case .mastered: return "Вивчено"
        }
    }
    
    private var statusBadgeColor: Color {
        switch card.status {
        case .new: return .blue
        case .learning: return .orange
        case .mastered: return .green
        }
    }
}