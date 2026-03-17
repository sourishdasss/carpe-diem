import Foundation

/// Feed item (from Supabase feed_activities or legacy).
struct FeedItem: Identifiable {
    let id: UUID
    let userName: String
    let userAvatar: String?
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
