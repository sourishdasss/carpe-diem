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
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-sonnet-4-20250514"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func generateCityScore(
        city: String,
        country: String,
        ratings: [(attractionName: String, category: String, score: Int)]
    ) async throws -> CityScoreResponse {
        let lines = ratings.map { "\($0.category): \($0.attractionName) — \($0.score)/5 stars" }
        let userMessage = """
        The user visited \(city), \(country) and rated the following attractions:
        \(lines.joined(separator: "\n"))

        Return this exact JSON shape (no markdown, no preamble):
        {"cumulative_score": 7.8, "score_breakdown": {"culture": 8.5, "food": 9.0, "neighbourhoods": 7.0, "landmarks": 6.5, "general_appeal": 8.0}, "summary": "2-3 sentence personalized summary.", "highlight": "One sentence highlight.", "would_recommend_if": "One sentence for who would love this city."}
        """

        let systemPrompt = """
        You are a travel analyst. Given a user's attraction ratings for a city, calculate a weighted cumulative score (scale 0-10) and write a personalized city summary. Respond in valid JSON only — no markdown, no preamble.
        """

        let json = try await performRequest(system: systemPrompt, user: userMessage)
        let data = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(CityScoreResponse.self, from: data)
    }

    func generateTravelProfile(ratedCities: [(city: String, score: Double, topCategories: [String], lowCategories: [String])]) async throws -> TravelProfileResponse {
        let lines = ratedCities.map { city in
            "\(city.city): cumulative score \(city.score), highest rated categories: \(city.topCategories.joined(separator: ", ")), lowest rated: \(city.lowCategories.joined(separator: ", "))"
        }
        let userMessage = """
        The user has rated attractions across the following cities:
        \(lines.joined(separator: "\n"))

        Return this exact JSON shape (no markdown, no preamble):
        {"personality_type": "The Slow Wanderer", "personality_description": "2 sentences.", "taste_traits": ["trait1", "trait2", "trait3", "trait4", "trait5"], "recommendations": [{"destination": "City, Country", "match_reason": "Why it matches.", "vibe_tags": ["tag1", "tag2", "tag3"], "match_score": 9.2}]}
        Return exactly 5 recommendations, sorted by match_score descending.
        """

        let systemPrompt = """
        You are a travel taste expert. Based on a user's attraction ratings across multiple cities, infer their travel personality. Respond in valid JSON only.
        """

        let json = try await performRequest(system: systemPrompt, user: userMessage)
        let data = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(TravelProfileResponse.self, from: data)
    }

    private func performRequest(system: String, user: String) async throws -> [String: Any] {
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": system,
            "messages": [
                ["role": "user", "content": user]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "ClaudeService", code: -1, userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Unknown error"])
        }

        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let content = parsed?["content"] as? [[String: Any]],
              let first = content.first,
              let text = first["text"] as? String else {
            throw NSError(domain: "ClaudeService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        // Strip markdown code blocks if present
        var raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.hasPrefix("```") {
            raw = raw.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let json = try JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any] else {
            throw NSError(domain: "ClaudeService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Could not parse JSON"])
        }
        return json
    }
}
