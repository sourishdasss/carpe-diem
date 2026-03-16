import SwiftUI

struct AttractionRaterView: View {
    let attraction: Attraction
    @Binding var score: Int?

    private let maxStars = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: attraction.category.icon)
                    .font(.subheadline)
                    .foregroundStyle(Color.accentAmber)
                Text(attraction.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
            }
            HStack(spacing: 6) {
                ForEach(1...maxStars, id: \.self) { value in
                    Button {
                        score = value
                    } label: {
                        Image(systemName: (score ?? 0) >= value ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundStyle((score ?? 0) >= value ? Color.accentAmber : Color.slate500)
                    }
                    .buttonStyle(.plain)
                }
                Button("Skip") {
                    score = nil
                }
                .font(.caption)
                .foregroundStyle(Color.slate400)
                .padding(.leading, 8)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.night800)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
