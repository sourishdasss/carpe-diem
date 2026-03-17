import SwiftUI

struct FutureRecommendationsView: View {
    let recommendations: [DestinationRecommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Where to Next")
                .font(.georgiaBold(20))
                .foregroundStyle(Color.sonderTextPrimary)
                .padding(.horizontal, 0)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(recommendations) { rec in
                        RecommendationCard(recommendation: rec)
                    }
                }
                .padding(.horizontal, 1) // prevents shadow clipping
                .padding(.vertical, 4)
            }
        }
    }
}

struct RecommendationCard: View {
    let recommendation: DestinationRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Match score badge (top right)
            HStack {
                Spacer()
                if recommendation.matchScore > 0 {
                    Text(String(format: "%.0f%% match", recommendation.matchScore * 10))
                        .font(.georgiaBold(11))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.sonderAccent)
                        .clipShape(Capsule())
                }
            }

            // Destination
            Text(recommendation.destination)
                .font(.georgiaBold(18))
                .foregroundStyle(Color.sonderTextPrimary)
                .lineLimit(2)

            // Match reason
            Text(recommendation.matchReason)
                .font(.georgia(13))
                .foregroundStyle(Color.sonderTextSecond)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            // Vibe tags (sage green)
            if !recommendation.vibeTags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(recommendation.vibeTags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.georgia(11))
                            .foregroundStyle(Color.sonderSage)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color.sonderSage.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 240, alignment: .leading)
        .background(Color.sonderSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
    }
}
