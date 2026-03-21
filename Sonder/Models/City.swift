import Foundation

enum AttractionCategory: String, Codable, CaseIterable {
    case culture = "Museums & Culture"
    case nature = "Parks & Nature"
    case food = "Food & Markets"
    case neighbourhood = "Neighbourhoods & Walks"
    case experience = "Experiences & Activities"
    case landmark = "Viewpoints & Landmarks"
    case general = "General Appeal"

    var weight: Double {
        switch self {
        case .neighbourhood: return 1.5
        case .food: return 1.2
        case .culture, .nature, .experience: return 1.0
        case .landmark: return 0.8
        case .general: return 1.5
        }
    }

    var icon: String {
        switch self {
        case .culture: return "building.2"
        case .nature: return "leaf"
        case .food: return "fork.knife"
        case .neighbourhood: return "figure.walk"
        case .experience: return "theatermasks"
        case .landmark: return "binoculars"
        case .general: return "star"
        }
    }
}

struct Attraction: Identifiable, Hashable {
    let id: UUID
    let name: String
    let category: AttractionCategory
    var weight: Double { category.weight }

    init(id: UUID = UUID(), name: String, category: AttractionCategory) {
        self.id = id
        self.name = name
        self.category = category
    }
}

// MARK: - Visit sentiment (replaces 1–5 stars)

enum VisitSentiment: String, Codable, CaseIterable, Hashable {
    case wouldReturn = "would_return"
    case decent = "decent"
    case waste = "waste"

    var shortLabel: String {
        switch self {
        case .wouldReturn: return "Would return"
        case .decent: return "Decent"
        case .waste: return "Waste of time"
        }
    }

    var detailLine: String {
        switch self {
        case .wouldReturn: return "Loved it — you’d go out of your way to do this again."
        case .decent: return "Fine, not a miss — but not the main reason you’d come back."
        case .waste: return "Wouldn’t repeat — felt like a poor use of time or money."
        }
    }

    /// Base signal on 0–10 before within-category rank adjustment.
    var baseScore10: Double {
        switch self {
        case .wouldReturn: return 8.2
        case .decent: return 5.4
        case .waste: return 2.1
        }
    }

    var sortTier: Int {
        switch self {
        case .wouldReturn: return 0
        case .decent: return 1
        case .waste: return 2
        }
    }

    /// Derive sentiment from rank position in a category (Beli-style pure ranking).
    /// rank is 1-based (1 = best). top ~33% → wouldReturn, middle → decent, bottom → waste.
    static func fromRankPosition(rank: Int, total: Int) -> VisitSentiment {
        guard total > 2 else { return rank == 1 ? .wouldReturn : .decent }
        let fraction = Double(rank - 1) / Double(total - 1)
        if fraction <= 0.33 { return .wouldReturn }
        if fraction <= 0.7 { return .decent }
        return .waste
    }
}

/// One attraction the user is logging for a city visit (before submit).
struct CityVisitAttractionEntry: Hashable {
    let attraction: Attraction
    let sentiment: VisitSentiment
    /// 1 = best in this category for this visit (drag to reorder).
    let rankInCategory: Int
    let categoryCount: Int
}

struct CityData: Identifiable, Hashable {
    let id: UUID
    let city: String
    let country: String
    let flag: String
    let photoURL: String
    let attractions: [Attraction]

    init(id: UUID = UUID(), city: String, country: String, flag: String, photoURL: String, attractions: [Attraction]) {
        self.id = id
        self.city = city
        self.country = country
        self.flag = flag
        self.photoURL = photoURL
        self.attractions = attractions
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: CityData, rhs: CityData) -> Bool { lhs.id == rhs.id }
}

struct AttractionRating: Identifiable, Hashable {
    let id: UUID
    let attractionId: UUID
    let sentiment: VisitSentiment
    /// Best = 1 within the same category for that city visit; used with other trips for comparison copy.
    let rankAmongSimilar: Int

    init(id: UUID = UUID(), attractionId: UUID, sentiment: VisitSentiment, rankAmongSimilar: Int) {
        self.id = id
        self.attractionId = attractionId
        self.sentiment = sentiment
        self.rankAmongSimilar = max(1, rankAmongSimilar)
    }

    /// Numeric strength for aggregates (0–10), blending sentiment + how you ordered vs siblings in the same category.
    func effectiveScore10(categoryCount: Int) -> Double {
        let base = sentiment.baseScore10
        guard categoryCount > 1 else { return min(10, max(0, base)) }
        let spread = 1.35
        let norm = Double(categoryCount - rankAmongSimilar) / Double(max(1, categoryCount - 1))
        let bump = norm * spread * (sentiment == .waste ? 0.35 : 1.0)
        return min(10, max(0, base + bump))
    }
}

struct RatedCity: Identifiable {
    let id: UUID
    let cityData: CityData
    var cumulativeScore: Double
    var summary: String
    var highlight: String
    var wouldRecommendIf: String
    var scoreBreakdown: [String: Double]?
    var ratings: [AttractionRating]
    var topAttractionName: String?

    init(
        id: UUID = UUID(),
        cityData: CityData,
        cumulativeScore: Double,
        summary: String,
        highlight: String,
        wouldRecommendIf: String,
        scoreBreakdown: [String: Double]? = nil,
        ratings: [AttractionRating] = [],
        topAttractionName: String? = nil
    ) {
        self.id = id
        self.cityData = cityData
        self.cumulativeScore = cumulativeScore
        self.summary = summary
        self.highlight = highlight
        self.wouldRecommendIf = wouldRecommendIf
        self.scoreBreakdown = scoreBreakdown
        self.ratings = ratings
        self.topAttractionName = topAttractionName
    }
}
