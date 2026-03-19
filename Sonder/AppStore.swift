import Foundation
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published var ratedCities: [RatedCity] = []
    @Published var travelProfile: TravelProfile = .placeholder
    @Published var feedItems: [FeedItem] = []
    @Published var selectedTab: Tab = .lists
    @Published var isLoadingProfile = false
    @Published var isLoadingCityScore = false
    @Published var isLoadingFeed = false
    @Published var errorMessage: String?

    private var aiService: ClaudeService?
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

    func setAIBackend(goBaseURL: String) {
        // AI is currently disabled by default (Config.aiEnabled == false).
        // We keep this as a no-op to avoid instantiating ClaudeService when its initializer
        // no longer matches our previous Go-backend client wiring.
        aiService = nil
    }

    func configureSupabase(url: String, anonKey: String) {
        supabase.configure(url: url, anonKey: anonKey)
    }

    /// Load rated cities, travel profile, and feed from Supabase. Call on launch.
    func loadFromSupabase() async {
        guard supabase.isConfigured else { return }
        guard await supabase.isSignedIn() else { return }

        do {
            ratedCities = try await supabase.fetchRatedCities()
            ratedCities.sort { $0.cumulativeScore > $1.cumulativeScore }
            if let profile = try await supabase.fetchTravelProfile() {
                travelProfile = profile
            }
            if Config.feedEnabled {
                feedItems = try await supabase.fetchFeedActivities()
            } else {
                feedItems = []
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetForSignedOut() {
        ratedCities = []
        travelProfile = .placeholder
        feedItems = []
        errorMessage = nil
        isLoadingProfile = false
        isLoadingCityScore = false
        isLoadingFeed = false
    }

    func refreshFeed() async {
        guard Config.feedEnabled else { return }
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
                if Config.feedEnabled {
                    await postFeedActivityForNewCity(city)
                }
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
        isLoadingCityScore = true
        errorMessage = nil
        defer { isLoadingCityScore = false }

        let ratedAttractions: [(attraction: Attraction, score: Int)] = cityData.attractions.compactMap { att in
            guard let score = ratings[att.id] else { return nil }
            return (att, score)
        }
        guard !ratedAttractions.isEmpty else {
            errorMessage = "Rate at least one attraction"
            return
        }

        if Config.aiEnabled, let service = aiService {
            do {
                let lines: [(attractionName: String, category: String, score: Int)] = ratedAttractions.map {
                    (attractionName: $0.attraction.name, category: $0.attraction.category.rawValue, score: $0.score)
                }
                let response = try await service.generateCityScore(
                    city: cityData.city,
                    country: cityData.country,
                    ratings: lines
                )
                let attractionRatings = ratings.map { AttractionRating(attractionId: $0.key, score: $0.value) }
                let topAttractionName = ratedAttractions.max(by: { $0.score < $1.score })?.attraction.name
                let rated = RatedCity(
                    cityData: cityData,
                    cumulativeScore: response.cumulativeScore,
                    summary: response.summary,
                    highlight: response.highlight,
                    wouldRecommendIf: response.wouldRecommendIf,
                    scoreBreakdown: response.scoreBreakdown,
                    ratings: attractionRatings,
                    topAttractionName: topAttractionName
                )
                addRatedCity(rated)
            } catch {
                errorMessage = error.localizedDescription
            }
            return
        }

        // Local fallback (AI disabled): deterministic scoring + summary.
        let computed = computeCityScore(cityData: cityData, ratedAttractions: ratedAttractions)
        let attractionRatings = ratings.map { AttractionRating(attractionId: $0.key, score: $0.value) }
        let rated = RatedCity(
            cityData: cityData,
            cumulativeScore: computed.cumulativeScore,
            summary: computed.summary,
            highlight: computed.highlight,
            wouldRecommendIf: computed.wouldRecommendIf,
            scoreBreakdown: computed.scoreBreakdown,
            ratings: attractionRatings,
            topAttractionName: computed.topAttractionName
        )
        addRatedCity(rated)
    }

    func refreshTravelProfile() async {
        guard ratedCities.count >= profileRefreshThreshold else { return }
        isLoadingProfile = true
        defer { isLoadingProfile = false }

        if Config.aiEnabled, let service = aiService {
            do {
                let input: [(city: String, score: Double, topCategories: [String], lowCategories: [String])] = ratedCities.prefix(10).map { rc in
                    let breakdown = rc.scoreBreakdown ?? [:]
                    let sorted = breakdown.sorted { $0.value > $1.value }
                    let top = Array(sorted.prefix(2).map(\.key))
                    let low = Array(sorted.suffix(2).map(\.key))
                    return (rc.cityData.city, rc.cumulativeScore, top, low)
                }
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
            return
        }

        // Local fallback profile (AI disabled)
        travelProfile = computeTravelProfile(ratedCities: ratedCities)
        do {
            try await supabase.upsertTravelProfile(travelProfile)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private struct ComputedCityScore {
        let cumulativeScore: Double
        let scoreBreakdown: [String: Double]
        let summary: String
        let highlight: String
        let wouldRecommendIf: String
        let topAttractionName: String?
    }

    private func computeCityScore(
        cityData: CityData,
        ratedAttractions: [(attraction: Attraction, score: Int)]
    ) -> ComputedCityScore {
        var byCategoryScores: [AttractionCategory: [Int]] = [:]
        var weightedSum = 0.0
        var weightSum = 0.0

        for item in ratedAttractions {
            byCategoryScores[item.attraction.category, default: []].append(item.score)
            weightedSum += Double(item.score) * item.attraction.category.weight
            weightSum += item.attraction.category.weight
        }

        let weightedAvg1to5 = weightSum > 0 ? (weightedSum / weightSum) : 0
        let cumulativeScore10 = max(0, min(10, (weightedAvg1to5 / 5.0) * 10.0))

        var scoreBreakdown: [String: Double] = [:]
        for (cat, scores) in byCategoryScores {
            let avg = Double(scores.reduce(0, +)) / Double(max(1, scores.count))
            scoreBreakdown[cat.rawValue] = max(0, min(10, (avg / 5.0) * 10.0))
        }

        let sortedCats = scoreBreakdown.sorted { $0.value > $1.value }
        let top1Key = sortedCats.first?.key
        let top2Key = sortedCats.dropFirst().first?.key
        let bottomKey = sortedCats.last?.key

        let topAttractionName = ratedAttractions.max(by: { $0.score < $1.score })?.attraction.name

        let topA = top1Key ?? "your favorite vibes"
        let topB = top2Key ?? "the city's energy"
        let low = bottomKey ?? "less matching categories"

        let summary = "In \(cityData.city), your strongest pull was \(topA) and \(topB). You clicked the most with the parts that feel natural to you, while \(low) landed a bit differently."
        let highlight = "Your strongest signal was \(topA)."
        let wouldRecommendIf = "You'll probably love \(cityData.city) if you're into \(topA) and \(topB)."

        return ComputedCityScore(
            cumulativeScore: cumulativeScore10,
            scoreBreakdown: scoreBreakdown,
            summary: summary,
            highlight: highlight,
            wouldRecommendIf: wouldRecommendIf,
            topAttractionName: topAttractionName
        )
    }

    private func computeTravelProfile(ratedCities: [RatedCity]) -> TravelProfile {
        var totals: [String: (sum: Double, count: Int)] = [:]
        for city in ratedCities {
            for (cat, score10) in city.scoreBreakdown ?? [:] {
                let current = totals[cat] ?? (sum: 0, count: 0)
                totals[cat] = (sum: current.sum + score10, count: current.count + 1)
            }
        }

        let sorted = totals.map { key, val in
            (key: key, avg: val.count > 0 ? (val.sum / Double(val.count)) : 0)
        }.sorted { $0.avg > $1.avg }

        let topKeys = sorted.prefix(5).map(\.key)
        let top1 = topKeys.first ?? AttractionCategory.general.rawValue
        let top2 = topKeys.dropFirst().first ?? AttractionCategory.neighbourhood.rawValue

        let primaryCategory = AttractionCategory(rawValue: top1)
        let personalityType: String = {
            guard let primaryCategory else { return "The Explorer" }
            switch primaryCategory {
            case .neighbourhood: return "The Slow Wanderer"
            case .food: return "The Street Food Seeker"
            case .culture: return "The Culture Curator"
            case .nature: return "The Nature Hunter"
            case .landmark: return "The Icon Chaser"
            case .experience: return "The Experience Seeker"
            case .general: return "The Balanced Voyager"
            }
        }()

        let personalityDescription = "You tend to gravitate toward \(top1) and \(top2), and you’re most satisfied when a city offers the right mix of mood and activities. Your taste pattern suggests you’ll enjoy planning trips around walkable rhythm and local experiences."

        let ratedKeySet = Set(ratedCities.map { "\($0.cityData.city)|\($0.cityData.country)" })
        let candidates = Attractions.allCities.filter { !ratedKeySet.contains("\($0.city)|\($0.country)") }

        func userCategoryAvg(_ catRawValue: String) -> Double {
            guard let v = totals[catRawValue], v.count > 0 else { return 0 }
            return v.sum / Double(v.count)
        }

        func recommendationScore(for city: CityData) -> Double {
            var sum = 0.0
            var wsum = 0.0
            for att in city.attractions {
                sum += userCategoryAvg(att.category.rawValue) * att.category.weight
                wsum += att.category.weight
            }
            guard wsum > 0 else { return 0 }
            return max(0, min(10, sum / wsum))
        }

        let ranked = candidates
            .map { (city: $0, score: recommendationScore(for: $0)) }
            .sorted { $0.score > $1.score }
            .prefix(5)

        let recs: [DestinationRecommendation] = ranked.map { item in
            let cityCats = Set(item.city.attractions.map { $0.category.rawValue })
            let intersect = [top1, top2].filter { cityCats.contains($0) }
            let primaryTag = intersect.first ?? top1
            let vibeTags = intersect.isEmpty ? [primaryTag] : Array(intersect.prefix(3))
            let matchReason = "Because your taste leans into \(primaryTag), \(item.city.city) aligns with the kinds of \(primaryTag.lowercased()) experiences you tend to love."
            return DestinationRecommendation(
                destination: "\(item.city.city), \(item.city.country)",
                matchReason: matchReason,
                vibeTags: vibeTags,
                matchScore: item.score
            )
        }

        return TravelProfile(
            personalityType: personalityType,
            personalityDescription: personalityDescription,
            tasteTraits: topKeys,
            recommendations: recs
        )
    }
}
