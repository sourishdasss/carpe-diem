import Foundation

struct CityScoreResponse: Codable {
    let cumulativeScore: Double
    let scoreBreakdown: [String: Double]?
    let summary: String
    let highlight: String
    let wouldRecommendIf: String

    enum CodingKeys: String, CodingKey {
        case cumulativeScore = "cumulative_score"
        case scoreBreakdown = "score_breakdown"
        case summary
        case highlight
        case wouldRecommendIf = "would_recommend_if"
    }
}

struct TravelProfileResponse: Codable {
    let personalityType: String
    let personalityDescription: String
    let tasteTraits: [String]
    let recommendations: [RecommendationItem]

    enum CodingKeys: String, CodingKey {
        case personalityType = "personality_type"
        case personalityDescription = "personality_description"
        case tasteTraits = "taste_traits"
        case recommendations
    }
}

struct RecommendationItem: Codable {
    let destination: String
    let matchReason: String
    let vibeTags: [String]
    var matchScore: Double

    init(destination: String, matchReason: String, vibeTags: [String], matchScore: Double = 0) {
        self.destination = destination
        self.matchReason = matchReason
        self.vibeTags = vibeTags
        self.matchScore = matchScore
    }

    enum CodingKeys: String, CodingKey {
        case destination
        case matchReason = "match_reason"
        case vibeTags = "vibe_tags"
        case matchScore = "match_score"
    }
}

@MainActor
final class ClaudeService {
    private let apiKey: String
    private let baseURL = URL(string: "https://generativelanguage.googleapis.com/v1beta")!
    private let modelPath = "models/gemini-2.0-flash" // or another Gemini model

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func generateCityScore(
        city: String,
        country: String,
        ratings: [(attractionName: String, category: String, score: Int)]
    ) async throws -> CityScoreResponse {
        let lines = ratings.map { "\($0.category): \($0.attractionName) — \($0.score)/5 stars" }
        let userText = """
        The user visited \(city), \(country) and rated the following attractions:
        \(lines.joined(separator: "\n"))

        Return JSON only with keys:
        cumulative_score (0–10),
        score_breakdown,
        summary,
        highlight,
        would_recommend_if.
        """

        let systemPrompt = """
        You are a travel analyst. Given a user's attraction ratings for a city, calculate a weighted cumulative score (0–10) and write a personalized city summary. Respond with JSON only, no markdown or commentary.
        """

        let jsonData = try await callGemini(systemPrompt: systemPrompt, userText: userText)
        return try JSONDecoder().decode(CityScoreResponse.self, from: jsonData)
    }

    func generateTravelProfile(
        ratedCities: [(city: String, score: Double, topCategories: [String], lowCategories: [String])]
    ) async throws -> TravelProfileResponse {
        let lines = ratedCities.map { cityInfo in
            let topJoined = cityInfo.topCategories.joined(separator: ", ")
            let lowJoined = cityInfo.lowCategories.joined(separator: ", ")
            return "\(cityInfo.city): cumulative score \(cityInfo.score), highest rated categories: \(topJoined), lowest rated: \(lowJoined)"
        }.joined(separator: "\n")

        let userText = """
        The user has rated attractions across the following cities:
        \(lines)

        Return JSON only with keys:
        personality_type,
        personality_description,
        taste_traits (5 items),
        recommendations (array of { destination, match_reason, vibe_tags, match_score } with exactly 5 items).
        """

        let systemPrompt = """
        You are a travel taste expert. Based on a user's attraction ratings across multiple cities, infer their travel personality. Respond with JSON only, no markdown or commentary.
        """

        let jsonData = try await callGemini(systemPrompt: systemPrompt, userText: userText)
        return try JSONDecoder().decode(TravelProfileResponse.self, from: jsonData)
    }

    // MARK: - Core Gemini call

    private func callGemini(systemPrompt: String, userText: String) async throws -> Data {
        var url = baseURL.appendingPathComponent("\(modelPath):generateContent")
        url.append(queryItems: [URLQueryItem(name: "key", value: apiKey)])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let combined = systemPrompt + "\n\n" + userText
        let body: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": [
                        ["text": combined]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(
                domain: "GeminiService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Gemini error"]
            )
        }

        let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = (root?["candidates"] as? [[String: Any]]) ?? []
        let first = candidates.first
        let content = first?["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]]
        let text = parts?.first?["text"] as? String ?? ""

        var cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.isEmpty {
            cleaned = "{}"
        }

        return Data(cleaned.utf8)
    }
}
