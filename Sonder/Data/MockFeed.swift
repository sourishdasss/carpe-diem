import Foundation

struct FeedItem: Identifiable {
    let id: UUID
    let userName: String
    let userAvatar: String? // SF Symbol or emoji for mock
    let action: FeedAction
    let city: String
    let country: String
    let cityPhotoURL: String?
    let score: Double?
    let review: String?
    let timestamp: Date

    init(
        id: UUID = UUID(),
        userName: String,
        userAvatar: String? = nil,
        action: FeedAction,
        city: String,
        country: String,
        cityPhotoURL: String? = nil,
        score: Double? = nil,
        review: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.userName = userName
        self.userAvatar = userAvatar
        self.action = action
        self.city = city
        self.country = country
        self.cityPhotoURL = cityPhotoURL
        self.score = score
        self.review = review
        self.timestamp = timestamp
    }
}

enum FeedAction {
    case ratedAttraction(attractionName: String, score: Int)
    case visitedCity(attractionCount: Int)
    case addedToFavourites(city: String)

    var displayText: String {
        switch self {
        case .ratedAttraction(let name, let score):
            return "rated \(name) ★\(score)/5"
        case .visitedCity(let count):
            return "visited \(count) attractions"
        case .addedToFavourites(let city):
            return "added \(city) to Favourites"
        }
    }
}

enum MockFeed {
    static let items: [FeedItem] = [
        FeedItem(
            userName: "Maya",
            userAvatar: "person.circle.fill",
            action: .ratedAttraction(attractionName: "Eiffel Tower", score: 5),
            city: "Paris",
            country: "France",
            cityPhotoURL: "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800",
            score: 5,
            review: "Absolutely magical at sunset.",
            timestamp: Date().addingTimeInterval(-3600)
        ),
        FeedItem(
            userName: "Alex",
            userAvatar: "person.circle.fill",
            action: .visitedCity(attractionCount: 4),
            city: "Tokyo",
            country: "Japan",
            cityPhotoURL: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800",
            score: 9.1,
            review: nil,
            timestamp: Date().addingTimeInterval(-7200)
        ),
        FeedItem(
            userName: "Jordan",
            userAvatar: "person.circle.fill",
            action: .addedToFavourites(city: "Kyoto"),
            city: "Kyoto",
            country: "Japan",
            cityPhotoURL: "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=800",
            score: nil,
            review: nil,
            timestamp: Date().addingTimeInterval(-86400)
        ),
        FeedItem(
            userName: "Sam",
            userAvatar: "person.circle.fill",
            action: .ratedAttraction(attractionName: "Time Out Market", score: 5),
            city: "Lisbon",
            country: "Portugal",
            cityPhotoURL: "https://images.unsplash.com/photo-1585208798174-6cedd86e019a?w=800",
            score: 5,
            review: "Best food hall in Europe.",
            timestamp: Date().addingTimeInterval(-172800)
        ),
        FeedItem(
            userName: "Riley",
            userAvatar: "person.circle.fill",
            action: .visitedCity(attractionCount: 6),
            city: "Marrakech",
            country: "Morocco",
            cityPhotoURL: "https://images.unsplash.com/photo-1489749798305-4fea3ae63d43?w=800",
            score: 8.2,
            review: nil,
            timestamp: Date().addingTimeInterval(-259200)
        )
    ]
}
