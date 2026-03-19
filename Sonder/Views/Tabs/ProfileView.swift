import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var auth: AuthStore
    @State private var displayName: String = "Sonder Traveller"
    private let supabase = SupabaseService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonderBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 28) {
                        avatarHeader
                        followStats
                        personalityCard
                        statsRow
                        topCitiesSection
                        if !store.travelProfile.recommendations.isEmpty {
                            FutureRecommendationsView(recommendations: store.travelProfile.recommendations)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
            .task {
                if let name = try? await supabase.fetchResolvedDisplayName() {
                    if !name.isEmpty {
                        displayName = name
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.sonderBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await auth.signOut()
                            store.resetForSignedOut()
                        }
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
        }
    }

    // MARK: - Avatar + Name

    private var avatarHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.sonderAccent.opacity(0.15))
                Text("S")
                    .font(.georgiaBold(28))
                    .foregroundStyle(Color.sonderAccent)
            }
            .frame(width: 68, height: 68)
            .overlay(Circle().stroke(Color.sonderAccent, lineWidth: 2))

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.georgiaBold(20))
                    .foregroundStyle(Color.sonderTextPrimary)
                Text("Travel that fits you.")
                    .font(.georgiaItalic(14))
                    .foregroundStyle(Color.sonderTextSecond)
            }

            Spacer()
        }
    }

    // MARK: - Follow Stats

    private var followStats: some View {
        FollowStatsView(followerCount: 47, followingCount: 31)
    }

    // MARK: - Personality Card

    private var personalityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Travel Personality", systemImage: "sparkles")
                .font(.georgia(12))
                .foregroundStyle(Color.sonderTextSecond)
                .labelStyle(.titleAndIcon)

            Text(store.travelProfile.personalityType)
                .font(.georgiaBold(22))
                .foregroundStyle(Color.sonderTextPrimary)

            Text(store.travelProfile.personalityDescription)
                .font(.georgia(15))
                .foregroundStyle(Color.sonderTextSecond)
                .fixedSize(horizontal: false, vertical: true)

            if !store.travelProfile.tasteTraits.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(store.travelProfile.tasteTraits, id: \.self) { trait in
                        Text(trait)
                            .font(.georgia(12))
                            .foregroundStyle(Color.sonderSage)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.sonderSage.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            } else {
                Text("Rate attractions in 3+ cities to unlock your personality type.")
                    .font(.georgia(13))
                    .foregroundStyle(Color.sonderTextSecond)
                    .italic()
            }

            if store.isLoadingProfile {
                HStack(spacing: 8) {
                    ProgressView().tint(Color.sonderAccent)
                    Text("Analysing your travel taste…")
                        .font(.georgia(13))
                        .foregroundStyle(Color.sonderTextSecond)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sonderSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(value: "\(store.totalAttractionsRated)", label: "Attractions rated")
            dividerLine
            statCell(value: "\(store.ratedCities.count)", label: "Cities visited")
            if let cat = store.favouriteCategory {
                dividerLine
                statCell(value: cat.components(separatedBy: " ").first ?? cat, label: "Top category")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.sonderSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.georgiaBold(22))
                .foregroundStyle(Color.sonderAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.georgia(11))
                .foregroundStyle(Color.sonderTextSecond)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.sonderDivider)
            .frame(width: 1, height: 36)
    }

    // MARK: - Top Cities

    private var topCitiesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Top Cities")
                .font(.georgiaBold(20))
                .foregroundStyle(Color.sonderTextPrimary)

            if store.ratedCities.isEmpty {
                Text("Rate attractions in cities to build your rankings.")
                    .font(.georgia(14))
                    .foregroundStyle(Color.sonderTextSecond)
                    .padding(.vertical, 12)
            } else {
                ForEach(store.ratedCities.prefix(5)) { city in
                    CityCardView(city: city)
                }
            }
        }
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
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
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
