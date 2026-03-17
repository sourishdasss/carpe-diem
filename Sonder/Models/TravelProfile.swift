import Foundation

struct TravelProfile {
    var personalityType: String
    var personalityDescription: String
    var tasteTraits: [String]
    var recommendations: [DestinationRecommendation]

    static let placeholder = TravelProfile(
        personalityType: "The Explorer",
        personalityDescription: "You're still building your travel DNA. Rate attractions in a few more cities to unlock your personality.",
        tasteTraits: [],
        recommendations: []
    )
}

struct DestinationRecommendation: Identifiable {
    let id = UUID()
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
}
