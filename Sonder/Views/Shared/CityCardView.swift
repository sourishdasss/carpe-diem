import SwiftUI

struct CityCardView: View {
    let city: RatedCity

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Photo
            AsyncImage(url: URL(string: city.cityData.photoURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .empty:
                    Color.sonderDivider.overlay(ProgressView().tint(Color.sonderAccent))
                default:
                    Color.sonderDivider
                }
            }
            .frame(height: 170)
            .clipped()

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.80)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(city.cityData.city)
                        .font(.georgiaBold(20))
                        .foregroundStyle(.white)
                    Text(city.cityData.flag)
                        .font(.system(size: 18))
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(String(format: "%.1f", city.cumulativeScore))
                        .font(.georgiaBold(30))
                        .foregroundStyle(Color.sonderAccent)
                    Text("/ 10")
                        .font(.georgia(15))
                        .foregroundStyle(.white.opacity(0.75))
                    Text("·")
                        .foregroundStyle(.white.opacity(0.5))
                    Text("\(city.ratings.count) places")
                        .font(.georgia(13))
                        .foregroundStyle(.white.opacity(0.75))
                }

                if let top = city.topAttractionName, !top.isEmpty {
                    Label(top, systemImage: "crown.fill")
                        .font(.georgia(12))
                        .foregroundStyle(.white.opacity(0.7))
                        .labelStyle(.titleAndIcon)
                }
            }
            .padding(14)
        }
        .frame(height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 4)
    }
}
