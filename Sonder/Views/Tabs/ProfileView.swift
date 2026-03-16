import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationStack {
            ZStack {
                Color.night900.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        profileCard
                        topCitiesSection
                        if !store.travelProfile.recommendations.isEmpty {
                            recommendationsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Travel personality")
                .font(.caption)
                .foregroundStyle(Color.slate400)
            Text(store.travelProfile.personalityType)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text(store.travelProfile.personalityDescription)
                .font(.subheadline)
                .foregroundStyle(Color.slate300)
            if !store.travelProfile.tasteTraits.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(store.travelProfile.tasteTraits, id: \.self) { trait in
                        Text(trait)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.night700)
                            .foregroundStyle(Color.accentAmber)
                            .clipShape(Capsule())
                    }
                }
            }
            statsRow
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.night800)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var statsRow: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(store.totalAttractionsRated)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.accentAmber)
                Text("Attractions rated")
                    .font(.caption)
                    .foregroundStyle(Color.slate400)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(store.ratedCities.count)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.accentAmber)
                Text("Cities visited")
                    .font(.caption)
                    .foregroundStyle(Color.slate400)
            }
            if let cat = store.favouriteCategory {
                VStack(alignment: .leading, spacing: 2) {
                    Text(cat)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentAmber)
                        .lineLimit(1)
                    Text("Favourite category")
                        .font(.caption)
                        .foregroundStyle(Color.slate400)
                }
            }
        }
        .padding(.top, 8)
    }

    private var topCitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top cities")
                .font(.headline)
                .foregroundStyle(.white)
            if store.ratedCities.isEmpty {
                Text("Rate attractions in cities to see them here.")
                    .font(.subheadline)
                    .foregroundStyle(Color.slate400)
                    .padding(.vertical, 20)
            } else {
                ForEach(store.ratedCities.prefix(5)) { city in
                    CityCardView(city: city)
                }
            }
        }
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended for you")
                .font(.headline)
                .foregroundStyle(.white)
            ForEach(store.travelProfile.recommendations) { rec in
                VStack(alignment: .leading, spacing: 6) {
                    Text(rec.destination)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(rec.matchReason)
                        .font(.caption)
                        .foregroundStyle(Color.slate400)
                    if !rec.vibeTags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(rec.vibeTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(Color.night700)
                                    .foregroundStyle(Color.slate300)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.night800)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

extension Color {
    static let slate300 = Color(red: 0.7, green: 0.72, blue: 0.78)
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, pos) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y), proposal: .unspecified)
        }
    }
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        let totalHeight = y + rowHeight
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
