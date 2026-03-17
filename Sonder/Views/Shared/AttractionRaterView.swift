import SwiftUI

struct AttractionRaterView: View {
    let attraction: Attraction
    @Binding var score: Int?

    private let maxStars = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: attraction.category.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.sonderSage)
                    .frame(width: 20)
                Text(attraction.name)
                    .font(.georgiaBold(15))
                    .foregroundStyle(Color.sonderTextPrimary)
                Spacer()
                // Category badge
                Text(attraction.category.rawValue.components(separatedBy: " ").first ?? "")
                    .font(.georgia(11))
                    .foregroundStyle(Color.sonderSage)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.sonderSage.opacity(0.12))
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(1...maxStars, id: \.self) { value in
                        Button {
                            score = value
                        } label: {
                            Image(systemName: (score ?? 0) >= value ? "star.fill" : "star")
                                .font(.system(size: 22))
                                .foregroundStyle(
                                    (score ?? 0) >= value
                                        ? Color.sonderAccent
                                        : Color.sonderDivider
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                if score != nil {
                    Button("Clear") { score = nil }
                        .font(.georgia(12))
                        .foregroundStyle(Color.sonderTextSecond)
                }
            }
        }
        .padding(14)
        .background(Color.sonderSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
