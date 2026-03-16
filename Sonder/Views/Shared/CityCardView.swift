import SwiftUI

struct CityCardView: View {
    let city: RatedCity

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: city.cityData.photoURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Color.night700
                case .empty:
                    Color.night700
                        .overlay(ProgressView().tint(.white))
                @unknown default:
                    Color.night700
                }
            }
            .frame(height: 160)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(city.cityData.city)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(city.cityData.flag)
                        .font(.title3)
                }
                HStack(spacing: 12) {
                    Text(String(format: "%.1f", city.cumulativeScore))
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.accentAmber)
                    Text("/ 10")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                    Text("•")
                        .foregroundStyle(.white.opacity(0.6))
                    Text("\(city.ratings.count) attractions")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                if let top = city.topAttractionName, !top.isEmpty {
                    Text("Top: \(top)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding()
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
