import SwiftUI

struct FeedView: View {
    @EnvironmentObject var store: AppStore
    @State private var filter: FeedFilter = .everyone

    enum FeedFilter: String, CaseIterable {
        case everyone = "Everyone"
        case friends = "Friends"
        case trending = "Trending This Week"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.night900.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 16) {
                        filterBar
                        if store.isLoadingFeed {
                            ProgressView()
                                .tint(Color.accentAmber)
                                .padding()
                        } else if store.feedItems.isEmpty {
                            Text("No activity yet. Add a city from Lists to see it here.")
                                .font(.subheadline)
                                .foregroundStyle(Color.slate400)
                                .padding(.vertical, 32)
                        } else {
                            ForEach(store.feedItems) { item in
                                FeedCardView(item: item)
                            }
                        }
                    }
                    .padding()
                }
                .refreshable { await store.refreshFeed() }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.night900)
        }
    }

    private var filterBar: some View {
        HStack(spacing: 12) {
            ForEach(FeedFilter.allCases, id: \.rawValue) { f in
                Button(f.rawValue) { filter = f }
                    .font(.caption.weight(filter == f ? .semibold : .regular))
                    .foregroundStyle(filter == f ? Color.accentAmber : Color.slate400)
            }
            Spacer()
        }
        .padding(.bottom, 8)
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
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Color.night700
                    }
                }
                .frame(height: 140)
            } else {
                Color.night700
                    .frame(height: 140)
            }
            LinearGradient(colors: [.clear, .black.opacity(0.9)], startPoint: .top, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: item.userAvatar ?? "person.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                    Text("\(item.userName) \(item.action.displayText)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                }
                HStack {
                    Text("\(item.city) \(item.country)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                    if let score = item.score {
                        Text("•")
                        Text(String(format: "%.1f", score))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.accentAmber)
                    }
                }
                if let review = item.review, !review.isEmpty {
                    Text(review)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                }
            }
            .padding()
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
