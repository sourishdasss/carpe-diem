import SwiftUI

struct FeedView: View {
    @EnvironmentObject var store: AppStore
    @State private var filter: FeedFilter = .everyone

    enum FeedFilter: String, CaseIterable {
        case everyone  = "Everyone"
        case following = "Following"
        case trending  = "Trending"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonderBackground.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 16) {
                        filterBar
                        if store.isLoadingFeed {
                            ProgressView()
                                .tint(Color.sonderAccent)
                                .padding(.vertical, 32)
                        } else if store.feedItems.isEmpty {
                            emptyState
                        } else {
                            ForEach(store.feedItems) { item in
                                FeedCardView(item: item)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .refreshable { await store.refreshFeed() }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.sonderBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
        }
    }

    private var filterBar: some View {
        HStack(spacing: 4) {
            ForEach(FeedFilter.allCases, id: \.rawValue) { f in
                Button {
                    filter = f
                } label: {
                    Text(f.rawValue)
                        .font(.georgia(14))
                        .foregroundStyle(filter == f ? Color.sonderAccent : Color.sonderTextSecond)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 14)
                        .background(
                            filter == f
                                ? Color.sonderAccent.opacity(0.1)
                                : Color.clear
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.bottom, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "globe.europe.africa")
                .font(.system(size: 44))
                .foregroundStyle(Color.sonderDivider)
            Text("Nothing here yet.")
                .font(.georgiaBold(17))
                .foregroundStyle(Color.sonderTextPrimary)
            Text("Add a city from Lists and your activity will appear here.")
                .font(.georgia(14))
                .foregroundStyle(Color.sonderTextSecond)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 48)
        .padding(.horizontal, 32)
    }
}

struct FeedCardView: View {
    let item: FeedItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let urlString = item.cityPhotoURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Color.sonderDivider
                    }
                }
                .frame(height: 190)
            } else {
                Color.sonderDivider.frame(height: 190)
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.78)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle().fill(Color.sonderAccent)
                        Text(String(item.userName.prefix(1)).uppercased())
                            .font(.georgiaBold(11))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 26, height: 26)

                    Text("\(item.userName) \(item.action.displayText)")
                        .font(.georgiaBold(14))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    Text("\(item.city), \(item.country)")
                        .font(.georgia(13))
                        .foregroundStyle(.white.opacity(0.85))
                    if let score = item.score {
                        Text("·").foregroundStyle(.white.opacity(0.5))
                        Text(String(format: "%.1f", score))
                            .font(.georgiaBold(13))
                            .foregroundStyle(Color.sonderAccent)
                    }
                }

                if let review = item.review, !review.isEmpty {
                    Text(review)
                        .font(.georgia(12))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                }
            }
            .padding(14)
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}
