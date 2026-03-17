import Foundation
import Supabase

/// Supabase client and API. Configure with URL and anon key; uses anonymous auth for user_id.
@MainActor
final class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    private(set) var client: SupabaseClient?
    private var supabaseURL: URL?
    private var supabaseKey: String?

    func configure(url: String, anonKey: String) {
        guard let u = URL(string: url.trimmingCharacters(in: .whitespacesAndNewlines)),
              !anonKey.isEmpty else { return }
        supabaseURL = u
        supabaseKey = anonKey
        client = SupabaseClient(supabaseURL: u, supabaseKey: anonKey)
        Task { await signInAnonymouslyIfNeeded() }
    }

    var isConfigured: Bool { client != nil }

    /// Sign in anonymously so we have a user_id for RLS (no sign-up form).
    func signInAnonymouslyIfNeeded() async {
        guard let client = client else { return }
        do {
            let session = try await client.auth.session
            if session.user.isAnonymous { return }
        } catch {
            // No session or not anonymous — sign in anonymously
        }
        do {
            _ = try await client.auth.signInAnonymously()
        } catch {
            print("Supabase anonymous sign-in failed: \(error)")
        }
    }

    /// Fetch current user id (after anonymous sign-in).
    func currentUserId() async -> UUID? {
        guard let client = client else { return nil }
        do {
            let session = try await client.auth.session
            return session.user.id
        } catch {
            return nil
        }
    }

    // MARK: - Rated cities

    func fetchRatedCities() async throws -> [RatedCity] {
        guard let client = client else { return [] }
        let uid = await currentUserId()
        guard let uid = uid else { return [] }

        let rows: [RatedCityRow] = try await client
            .from("rated_cities")
            .select()
            .eq("user_id", value: uid.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return rows.compactMap { row in row.toRatedCity() }
    }

    func insertRatedCity(_ city: RatedCity) async throws {
        guard let client = client else { return }
        let uid = await currentUserId()
        guard let uid = uid else { return }

        let row = RatedCityRow.from(city, userId: uid)
        try await client
            .from("rated_cities")
            .insert(row)
            .execute()
    }

    // MARK: - Travel profile

    func fetchTravelProfile() async throws -> TravelProfile? {
        guard let client = client else { return nil }
        let uid = await currentUserId()
        guard let uid = uid else { return nil }

        let rows: [TravelProfileRow] = try await client
            .from("travel_profiles")
            .select()
            .eq("user_id", value: uid.uuidString)
            .execute()
            .value

        guard let row = rows.first else { return nil }
        return row.toTravelProfile()
    }

    func upsertTravelProfile(_ profile: TravelProfile) async throws {
        guard let client = client else { return }
        let uid = await currentUserId()
        guard let uid = uid else { return }

        let row = TravelProfileRow.from(profile, userId: uid)
        try await client
            .from("travel_profiles")
            .upsert(row)
            .execute()
    }

    // MARK: - Feed

    func fetchFeedActivities(limit: Int = 50) async throws -> [FeedItem] {
        guard let client = client else { return [] }

        let rows: [FeedActivityRow] = try await client
            .from("feed_activities")
            .select()
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return rows.map { $0.toFeedItem() }
    }

    func postFeedActivity(
        displayName: String,
        activityType: String,
        city: String,
        country: String,
        cityPhotoURL: String?,
        score: Double?,
        review: String?,
        data: [String: String]
    ) async throws {
        guard let client = client else { return }
        let uid = await currentUserId()
        guard let uid = uid else { return }

        let row = FeedActivityRow(
            id: UUID(),
            userId: uid,
            displayName: displayName,
            activityType: activityType,
            city: city,
            country: country,
            cityPhotoURL: cityPhotoURL,
            score: score,
            review: review,
            data: data,
            createdAt: Date()
        )
        try await client
            .from("feed_activities")
            .insert(row)
            .execute()
    }
}

// MARK: - DB row types (Codable for Supabase)

struct RatedCityRow: Codable {
    let id: UUID
    let userId: UUID
    let cityName: String
    let country: String
    let flag: String
    let photoUrl: String
    let cumulativeScore: Double
    let summary: String
    let highlight: String
    let wouldRecommendIf: String
    let scoreBreakdown: [String: Double]?
    let topAttractionName: String?
    let ratings: [AttractionRatingDTO]
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case cityName = "city_name"
        case country
        case flag
        case photoUrl = "photo_url"
        case cumulativeScore = "cumulative_score"
        case summary
        case highlight
        case wouldRecommendIf = "would_recommend_if"
        case scoreBreakdown = "score_breakdown"
        case topAttractionName = "top_attraction_name"
        case ratings
        case createdAt = "created_at"
    }

    func toRatedCity() -> RatedCity? {
        let cityData = Attractions.allCities.first { $0.city == cityName && $0.country == country }
            ?? CityData(
                city: cityName,
                country: country,
                flag: flag,
                photoURL: photoUrl,
                attractions: []
            )
        let attractionRatings = ratings.compactMap { dto -> AttractionRating? in
            guard let aid = UUID(uuidString: dto.attractionId) else { return nil }
            return AttractionRating(attractionId: aid, score: dto.score)
        }
        return RatedCity(
            id: id,
            cityData: cityData,
            cumulativeScore: cumulativeScore,
            summary: summary,
            highlight: highlight,
            wouldRecommendIf: wouldRecommendIf,
            scoreBreakdown: scoreBreakdown,
            ratings: attractionRatings,
            topAttractionName: topAttractionName
        )
    }

    static func from(_ city: RatedCity, userId: UUID) -> RatedCityRow {
        RatedCityRow(
            id: city.id,
            userId: userId,
            cityName: city.cityData.city,
            country: city.cityData.country,
            flag: city.cityData.flag,
            photoUrl: city.cityData.photoURL,
            cumulativeScore: city.cumulativeScore,
            summary: city.summary,
            highlight: city.highlight,
            wouldRecommendIf: city.wouldRecommendIf,
            scoreBreakdown: city.scoreBreakdown,
            topAttractionName: city.topAttractionName,
            ratings: city.ratings.map { AttractionRatingDTO(attractionId: $0.attractionId.uuidString, score: $0.score) },
            createdAt: nil
        )
    }
}

struct AttractionRatingDTO: Codable {
    let attractionId: String
    let score: Int

    enum CodingKeys: String, CodingKey {
        case attractionId = "attraction_id"
        case score
    }
}

struct TravelProfileRow: Codable {
    let userId: UUID
    let personalityType: String
    let personalityDescription: String
    let tasteTraits: [String]
    let recommendations: [RecommendationDTO]
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case personalityType = "personality_type"
        case personalityDescription = "personality_description"
        case tasteTraits = "taste_traits"
        case recommendations
        case updatedAt = "updated_at"
    }

    func toTravelProfile() -> TravelProfile {
        TravelProfile(
            personalityType: personalityType,
            personalityDescription: personalityDescription,
            tasteTraits: tasteTraits,
            recommendations: recommendations.map { r in
                DestinationRecommendation(
                    destination: r.destination,
                    matchReason: r.matchReason,
                    vibeTags: r.vibeTags,
                    matchScore: r.matchScore
                )
            }
        )
    }

    static func from(_ profile: TravelProfile, userId: UUID) -> TravelProfileRow {
        TravelProfileRow(
            userId: userId,
            personalityType: profile.personalityType,
            personalityDescription: profile.personalityDescription,
            tasteTraits: profile.tasteTraits,
            recommendations: profile.recommendations.map { r in
                RecommendationDTO(
                    destination: r.destination,
                    matchReason: r.matchReason,
                    vibeTags: r.vibeTags,
                    matchScore: r.matchScore
                )
            },
            updatedAt: nil
        )
    }
}

struct RecommendationDTO: Codable {
    let destination: String
    let matchReason: String
    let vibeTags: [String]
    var matchScore: Double

    enum CodingKeys: String, CodingKey {
        case destination
        case matchReason = "match_reason"
        case vibeTags = "vibe_tags"
        case matchScore = "match_score"
    }

    init(destination: String, matchReason: String, vibeTags: [String], matchScore: Double = 0) {
        self.destination = destination
        self.matchReason = matchReason
        self.vibeTags = vibeTags
        self.matchScore = matchScore
    }
}

struct FeedActivityRow: Codable {
    let id: UUID
    let userId: UUID
    let displayName: String
    let activityType: String
    let city: String
    let country: String
    let cityPhotoURL: String?
    let score: Double?
    let review: String?
    let data: [String: String]?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case displayName = "display_name"
        case activityType = "activity_type"
        case city
        case country
        case cityPhotoURL = "city_photo_url"
        case score
        case review
        case data
        case createdAt = "created_at"
    }

    func toFeedItem() -> FeedItem {
        let action: FeedAction
        let data = data ?? [:]
        switch activityType {
        case "rated_attraction":
            let name = data["attraction_name"] ?? "an attraction"
            let s = Int(data["score"] ?? "0") ?? 0
            action = .ratedAttraction(attractionName: name, score: s)
        case "visited_city":
            let count = Int(data["attraction_count"] ?? "0") ?? 0
            action = .visitedCity(attractionCount: count)
        case "added_favourite":
            let c = data["city"] ?? city
            action = .addedToFavourites(city: c)
        default:
            action = .visitedCity(attractionCount: 0)
        }
        return FeedItem(
            id: id,
            userName: displayName,
            userAvatar: "person.circle.fill",
            action: action,
            city: city,
            country: country,
            cityPhotoURL: cityPhotoURL,
            score: score,
            review: review,
            timestamp: createdAt ?? Date()
        )
    }
}
