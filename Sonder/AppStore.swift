import Foundation
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published var ratedCities: [RatedCity] = []
    @Published var travelProfile: TravelProfile = .placeholder
    @Published var feedItems: [FeedItem] = []
    @Published var selectedTab: Tab = .feed
    @Published var isLoadingProfile = false
    @Published var isLoadingCityScore = false
    @Published var isLoadingFeed = false
    @Published var errorMessage: String?

    private var claudeService: ClaudeService?
    private let profileRefreshThreshold = 3
    private let supabase = SupabaseService.shared

    enum Tab: String, CaseIterable {
        case feed = "Feed"
        case map = "Map"
        case lists = "Lists"
        case profile = "Profile"
    }

    var totalAttractionsRated: Int {
        ratedCities.reduce(0) { $0 + $1.ratings.count }
    }

    var favouriteCategory: String? {
        guard !ratedCities.isEmpty else { return nil }
        var categoryCounts: [String: Int] = [:]
        for city in ratedCities {
            for rating in city.ratings {
                if let att = city.cityData.attractions.first(where: { $0.id == rating.attractionId }) {
                    categoryCounts[att.category.rawValue, default: 0] += att.category.weight > 1 ? 2 : 1
                }
            }
        }
        return categoryCounts.max(by: { $0.value < $1.value })?.key
    }

    func setAPIKey(_ key: String) {
        claudeService = ClaudeService(apiKey: key)
    }

    func configureSupabase(url: String, anonKey: String) {
        supabase.configure(url: url, anonKey: anonKey)
    }

    /// Load rated cities, travel profile, and feed from Supabase. Call on launch.
    func loadFromSupabase() async {
        guard supabase.isConfigured else { return }
        await supabase.signInAnonymouslyIfNeeded()

        do {
            ratedCities = try await supabase.fetchRatedCities()
            ratedCities.sort { $0.cumulativeScore > $1.cumulativeScore }
            if let profile = try await supabase.fetchTravelProfile() {
                travelProfile = profile
            }
            feedItems = try await supabase.fetchFeedActivities()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshFeed() async {
        guard supabase.isConfigured else { return }
        isLoadingFeed = true
        defer { isLoadingFeed = false }
        do {
            feedItems = try await supabase.fetchFeedActivities()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addRatedCity(_ city: RatedCity) {
        ratedCities.append(city)
        ratedCities.sort { $0.cumulativeScore > $1.cumulativeScore }
        Task {
            do {
                try await supabase.insertRatedCity(city)
                await postFeedActivityForNewCity(city)
                if ratedCities.count >= profileRefreshThreshold {
                    await refreshTravelProfile()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func postFeedActivityForNewCity(_ city: RatedCity) async {
        let displayName = "You"
        do {
            try await supabase.postFeedActivity(
                displayName: displayName,
                activityType: "visited_city",
                city: city.cityData.city,
                country: city.cityData.country,
                cityPhotoURL: city.cityData.photoURL,
                score: city.cumulativeScore,
                review: nil,
                data: ["attraction_count": "\(city.ratings.count)"]
            )
            await refreshFeed()
        } catch {
            // Non-fatal
        }
    }

    func submitCityRatings(
        cityData: CityData,
        ratings: [UUID: Int]
    ) async {
        guard let service = claudeService else {
            errorMessage = "Gemini API key not set"
            return
        }
        isLoadingCityScore = true
        errorMessage = nil
        defer { isLoadingCityScore = false }

        let lines: [(attractionName: String, category: String, score: Int)] = cityData.attractions.compactMap { att in
            guard let score = ratings[att.id] else { return nil }
            return (att.name, att.category.rawValue, score)
        }
        guard !lines.isEmpty else {
            errorMessage = "Rate at least one attraction"
            return
        }

        do {
            let response = try await service.generateCityScore(
                city: cityData.city,
                country: cityData.country,
                ratings: lines
            )
            let attractionRatings = ratings.map { AttractionRating(attractionId: $0.key, score: $0.value) }
            let topRating = ratings.max(by: { $0.value < $1.value })
            let topName = topRating.flatMap { id in cityData.attractions.first(where: { $0.id == id.key })?.name }
            let rated = RatedCity(
                cityData: cityData,
                cumulativeScore: response.cumulativeScore,
                summary: response.summary,
                highlight: response.highlight,
                wouldRecommendIf: response.wouldRecommendIf,
                scoreBreakdown: response.scoreBreakdown,
                ratings: attractionRatings,
                topAttractionName: topName
            )
            addRatedCity(rated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshTravelProfile() async {
        guard ratedCities.count >= profileRefreshThreshold, let service = claudeService else { return }
        isLoadingProfile = true
        defer { isLoadingProfile = false }
        let input: [(city: String, score: Double, topCategories: [String], lowCategories: [String])] = ratedCities.prefix(10).map { rc in
            let breakdown = rc.scoreBreakdown ?? [:]
            let sorted = breakdown.sorted { $0.value > $1.value }
            let top = Array(sorted.prefix(2).map(\.key))
            let low = Array(sorted.suffix(2).map(\.key))
            return (rc.cityData.city, rc.cumulativeScore, top, low)
        }
        do {
            let response = try await service.generateTravelProfile(ratedCities: input)
            travelProfile = TravelProfile(
                personalityType: response.personalityType,
                personalityDescription: response.personalityDescription,
                tasteTraits: response.tasteTraits,
                recommendations: response.recommendations.map { r in
                    DestinationRecommendation(
                        destination: r.destination,
                        matchReason: r.matchReason,
                        vibeTags: r.vibeTags,
                        matchScore: r.matchScore
                    )
                }
            )
            try await supabase.upsertTravelProfile(travelProfile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
