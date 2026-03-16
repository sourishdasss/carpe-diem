# Sonder — Claude Code Build Instructions

## What We're Building
A "Beli for Travel" **iOS app** where users rate individual attractions within cities, building a personal travel taste profile and a cumulative city score. Think Letterboxd meets Google Maps — personal, social, and opinionated.

## Core Concept
Instead of rating destinations as a whole, users rate **individual attractions** (museums, neighbourhoods, restaurants, viewpoints, experiences) within a city. Sonder then:
- Aggregates those attraction ratings into a **cumulative city score** (weighted by category)
- Infers a **personal travel taste profile** from rating patterns
- Surfaces a **social feed** of what people in your network have been experiencing

---

## Tech Stack
- **Platform**: iOS native (Swift + SwiftUI)
- **Minimum Deployment Target**: iOS 17+
- **AI**: Anthropic Claude API (`claude-sonnet-4-20250514`) via `URLSession` / `async await`
- **Images**: `AsyncImage` loading from Unsplash URLs (no API key needed)
- **No backend required** — all state managed in-app via `@StateObject` / `@EnvironmentObject`
- **Navigation**: SwiftUI `TabView` with a custom styled bottom tab bar (Feed / Lists / Profile)
- **Storage**: `UserDefaults` or in-memory for the hackathon — no CoreData needed

---

### Tab 1: Profile
- User's **Travel Personality Type** (e.g. "The Slow Wanderer", "The Culture Vulture")
- Inferred **taste traits** as tags (e.g. "Walkable Streets", "Hidden Gems", "Street Food", "Architecture")
- **Top Cities** — the user's highest-rated destinations with their cumulative scores
- **Stats** — total attractions rated, cities visited, favourite category

### Tab 2: Feed
- A scrollable social feed of activity from other users (can be mocked for the demo)
- Each feed item shows: user avatar, what they rated, the city, their score, and a short review/reaction
- Feed items are visual — destination photo as background, card-style layout
- Filter feed by: Everyone / Friends / Trending This Week
- Example feed items:
  - "Maya rated the Eiffel Tower ★★★★★ in Paris 🇫🇷"
  - "Alex visited 4 attractions in Tokyo this week"
  - "Jordan added Kyoto to their Favourites list"

### Tab 3: Lists
- User's personal collection of rated places, organized two ways:

**Rankings View** — a ranked list of every city the user has visited, sorted by cumulative score (highest to lowest). Each city entry shows:
  - City name + country flag
  - Cumulative score (e.g. 8.4 / 10)
  - Number of attractions rated
  - Top-rated attraction in that city

**Categories View** — attractions grouped by type across all cities:
  - 🏛️ Museums & Culture
  - 🌿 Parks & Nature
  - 🍜 Food & Markets
  - 🏘️ Neighbourhoods & Walks
  - 🎭 Experiences & Activities
  - 👁️ Viewpoints & Landmarks

---

## Attraction Rating System

When a user adds a city, they rate its individual attractions across categories. Each attraction gets a score of 1–5. The **cumulative city score** is calculated as:

- Weighted average across all rated attractions
- General appeal (walkability, vibe, safety, ease of getting around) counts as its own "attraction" with a weight of 1.5x
- Formula: `city_score = (sum of attraction scores × category weights) / total weighted count`, scaled to 10

### Category Weights
- Neighbourhoods & Walks: 1.5x (high signal for overall city vibe)
- Food & Markets: 1.2x
- Culture & Museums: 1.0x
- Viewpoints & Landmarks: 0.8x (often touristy, lower signal)
- Experiences & Activities: 1.0x

---

## Adding a City + Rating Attractions Flow

1. User taps **"+ Add City"** from the Lists tab
2. Searches for or selects a city
3. Presented with a pre-populated list of ~10 top attractions for that city (seeded from a static data file)
4. User rates each attraction they've visited (1–5 stars), skips ones they haven't
5. Also rates **General Appeal** (walkability, atmosphere, ease of navigation) on the same scale
6. On submit → Claude API call generates the cumulative score + a short AI-written city summary based on the ratings
7. City is added to their Lists tab with the final score

---

## Claude API Usage

### 1. City Score + Summary Generation
After a user rates attractions in a city, send ratings to Claude using `URLSession` with `async/await` to generate a summary.

**System prompt:**
You are a travel analyst. Given a user's attraction ratings for a city, calculate a weighted cumulative score and write a personalized city summary. Respond in valid JSON only — no markdown, no preamble.

**User message format:**
The user visited [City, Country] and rated the following attractions:
[Category: Attraction Name — X/5 stars]
...
General Appeal (walkability, vibe, atmosphere): X/5

Return this exact JSON shape:
```json
{
  "cumulative_score": 7.8,
  "score_breakdown": {
    "culture": 8.5,
    "food": 9.0,
    "neighbourhoods": 7.0,
    "landmarks": 6.5,
    "general_appeal": 8.0
  },
  "summary": "2-3 sentence personalized summary of their experience in this city, referencing their specific ratings",
  "highlight": "The single best thing about this city based on their ratings (1 sentence)",
  "would_recommend_if": "1 sentence — the type of traveller who would love this city based on what they rated highly"
}
```

### 2. Travel Profile Generation
When the user has rated attractions across 3+ cities, generate their taste profile.

**System prompt:**
You are a travel taste expert. Based on a user's attraction ratings across multiple cities, infer their travel personality. Respond in valid JSON only.

**User message format:**
The user has rated attractions across the following cities:
[City]: cumulative score [X], highest rated categories: [list], lowest rated: [list]
...

Return this exact JSON shape:
```json
{
  "personality_type": "The Slow Wanderer",
  "personality_description": "2 sentences describing their travel style and what they seek.",
  "taste_traits": ["trait1", "trait2", "trait3", "trait4", "trait5"],
  "recommendations": [
    {
      "destination": "City, Country",
      "match_reason": "Why this matches their taste specifically, referencing their rating patterns",
      "vibe_tags": ["tag1", "tag2", "tag3"]
    }
  ]
}
```
Return exactly 5 recommendations.

---

## Static Data — Seed Attractions Per City

Each city in `Data/Attractions.swift` should have ~10 pre-seeded attractions across categories. Example:

```swift
struct Attraction: Identifiable {
    let id = UUID()
    let name: String
    let category: AttractionCategory
    let weight: Double
}

struct CityData {
    let city: String
    let country: String
    let flag: String
    let photoURL: String
    let attractions: [Attraction]
}

let tokyo = CityData(
    city: "Tokyo",
    country: "Japan",
    flag: "🇯🇵",
    photoURL: "https://source.unsplash.com/featured/?tokyo,travel",
    attractions: [
        Attraction(name: "Senso-ji Temple", category: .culture, weight: 1.0),
        Attraction(name: "Shibuya Crossing", category: .landmark, weight: 0.8),
        Attraction(name: "Shinjuku Gyoen", category: .nature, weight: 1.0),
        Attraction(name: "Tsukiji Outer Market", category: .food, weight: 1.2),
        Attraction(name: "Yanaka Neighbourhood", category: .neighbourhood, weight: 1.5),
        Attraction(name: "teamLab Planets", category: .experience, weight: 1.0),
        Attraction(name: "Harajuku & Takeshita Street", category: .neighbourhood, weight: 1.5),
        Attraction(name: "Tokyo Skytree", category: .landmark, weight: 0.8),
        Attraction(name: "Depachika Food Halls", category: .food, weight: 1.2),
        Attraction(name: "General Appeal", category: .general, weight: 1.5)
    ]
)
```

Seed at least 8 cities: Tokyo, Paris, Lisbon, New York, Bali, Kyoto, Marrakech, New Orleans.

---

## Design Direction
- **Name:** Sonder
- **Tagline:** *Travel that fits you.*
- Dark, premium aesthetic — deep navy/charcoal backgrounds
- Warm amber/gold accent colour for ratings and scores
- Native iOS `TabView` bottom tab bar (Feed / Lists / Profile)
- Full-screen city imagery using `AsyncImage` with shimmer placeholders
- Smooth SwiftUI transitions (`matchedGeometryEffect` for city card → detail)
- Score displayed as a large, confident number (e.g. "8.4") not a star average
- Use SF Symbols for all icons to keep it feeling native

---

## File Structure
```
Sonder/
  SonderApp.swift              # App entry point, @main
  AppStore.swift               # Central @StateObject for all app state
  Views/
    Tabs/
      FeedView.swift           # Social feed of friend/global activity
      ListsView.swift          # Rankings view + categories view
      ProfileView.swift        # Travel personality, traits, top cities
    Shared/
      CityCardView.swift       # Reusable city card with score
      AttractionRaterView.swift # Attraction rating UI (1–5 stars per item)
      AddCitySheet.swift       # Sheet for searching + rating attractions
      BottomTabBar.swift       # Custom styled tab bar
  Models/
    City.swift                 # City, Attraction, Rating models
    TravelProfile.swift        # Personality type, traits, recommendations
  Data/
    Attractions.swift          # Seeded attractions per city (static)
    MockFeed.swift             # Mock feed items for demo
  Services/
    ClaudeService.swift        # URLSession calls to Claude API
```

---

## Demo Flow (for presentation)
1. Open app → land on **Feed tab** — show social activity, looks alive
2. Switch to **Lists tab** → show 2–3 pre-seeded cities with scores (Tokyo: 9.1, Lisbon: 8.4)
3. Tap **"+ Add City"** → rate attractions in Paris live
4. Show Paris get added with its AI-generated cumulative score + summary
5. Switch to **Profile tab** → show personality type and taste traits that reflect the ratings just given
6. End on the profile card — it's the screenshot moment

---

## Constraints
- 3-hour hackathon — prioritize the demo flow above, skip edge cases
- No auth, no database — all state in `AppStore` (`@StateObject`), mock the feed with static data
- Single Claude API call per city rating submission
- Use Unsplash source URLs for photos (no API key needed): `https://source.unsplash.com/featured/?tokyo,travel`
- Target iPhone 15 Pro simulator for the demo