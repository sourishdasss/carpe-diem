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

struct AttractionRating: Identifiable {
    let id: UUID
    let attractionId: UUID
    let score: Int // 1-5

    init(id: UUID = UUID(), attractionId: UUID, score: Int) {
        self.id = id
        self.attractionId = attractionId
        self.score = min(5, max(1, score))
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
