import Foundation
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published var ratedCities: [RatedCity] = []
    @Published var travelProfile: TravelProfile = .placeholder
    @Published var selectedTab: Tab = .feed
    @Published var isLoadingProfile = false
    @Published var isLoadingCityScore = false
    @Published var errorMessage: String?

    private var claudeService: ClaudeService?
    private let profileRefreshThreshold = 3

    enum Tab: String, CaseIterable {
        case feed = "Feed"
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

    func addRatedCity(_ city: RatedCity) {
        ratedCities.append(city)
        ratedCities.sort { $0.cumulativeScore > $1.cumulativeScore }
        if ratedCities.count >= profileRefreshThreshold {
            Task { await refreshTravelProfile() }
        }
    }

    func submitCityRatings(
        cityData: CityData,
        ratings: [UUID: Int]
    ) async {
        guard let service = claudeService else {
            errorMessage = "API key not set"
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
                        vibeTags: r.vibeTags
                    )
                }
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Demo: pre-seed 2 cities so Lists and Profile look populated
    func seedDemoCities() {
        guard ratedCities.isEmpty else { return }
        let tokyo = Attractions.tokyo
        let lisbon = Attractions.lisbon
        ratedCities = [
            RatedCity(
                cityData: tokyo,
                cumulativeScore: 9.1,
                summary: "Tokyo blew you away — the mix of tradition and tech, neighbourhood walks, and food culture matched your taste perfectly.",
                highlight: "Neighbourhood vibes and depachika food halls.",
                wouldRecommendIf: "You love walkable cities, great food, and a balance of culture and buzz.",
                ratings: [],
                topAttractionName: "Yanaka Neighbourhood"
            ),
            RatedCity(
                cityData: lisbon,
                cumulativeScore: 8.4,
                summary: "Lisbon's hills, trams, and tiled neighbourhoods gave you exactly the kind of character and views you look for.",
                highlight: "Alfama and the miradouros.",
                wouldRecommendIf: "You're into walkable cities with strong local flavour and viewpoints.",
                ratings: [],
                topAttractionName: "Alfama"
            )
        ]
        selectedTab = .lists
    }
}
