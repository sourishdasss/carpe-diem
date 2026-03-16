# Sonder — Travel that fits you

iOS app (SwiftUI) where you rate **attractions** inside cities, get a cumulative city score, and a personal travel taste profile. Letterboxd meets Google Maps.

## Open in Xcode and run

1. **Create a new iOS App project**
   - Xcode → File → New → Project
   - Choose **App**, Next
   - Product Name: **Sonder**
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployments: **iOS 17.0**
   - Create and save (e.g. in this repo root or in a subfolder)

2. **Replace default source with Sonder**
   - Delete the default `ContentView.swift` (and any boilerplate) from the new target.
   - In the Project Navigator, right‑click the app target’s group → **Add Files to "Sonder"…**
   - Select the **`Sonder`** folder (the one containing `SonderApp.swift`, `AppStore.swift`, `Views/`, etc.).
   - Check **Copy items if needed** and **Create groups**, and ensure your app target is checked.
   - Click Add.

3. **Set the app entry point**
   - Ensure **`SonderApp.swift`** is in the target and contains `@main`.
   - If Xcode created its own `*_App.swift` with `@main`, remove `@main` from that file or delete it and keep only `SonderApp.swift` as the entry.

4. **Claude API key (for city score & profile)**
   - In Xcode: Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables, add:
     - Name: `CLAUDE_API_KEY`
     - Value: your Anthropic API key
   - Or in `SonderApp.swift` `onAppear` you can temporarily set the key (do not commit real keys).

5. **Run**
   - Select the **iPhone 15 Pro** (or any iOS 17+) simulator.
   - Build and run (⌘R).

## Demo flow (from CLAUDE.md)

1. Open app → **Feed** tab (mock social activity).
2. **Lists** tab → 2 pre-seeded cities (Tokyo 9.1, Lisbon 8.4).
3. Tap **+ Add City** → pick **Paris** → rate attractions → submit → Paris appears with AI score + summary.
4. **Profile** tab → personality type and traits (after 3+ cities, profile is generated via Claude).

## Project layout

```
Sonder/
  SonderApp.swift       # @main
  AppStore.swift        # Central state
  Views/
    ContentRootView.swift
    Tabs/               # Feed, Lists, Profile
    Shared/              # CityCard, AttractionRater, AddCitySheet, BottomTabBar
  Models/               # City, TravelProfile
  Data/                 # Attractions (seed cities), MockFeed
  Services/             # ClaudeService
  Theme/                # Colors
```

## Requirements

- Xcode 15+
- iOS 17+
- Anthropic API key for live city score and travel profile generation
