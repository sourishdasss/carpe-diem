# Sonder — Travel that fits you

iOS app (SwiftUI) where you rate **attractions** inside cities, get a cumulative city score, and a personal travel taste profile. Data is stored in **Supabase** (no sample data).

## Supabase setup

1. Create a project at [supabase.com](https://supabase.com).
2. In the SQL Editor, run the schema: copy and run the contents of **`supabase/schema.sql`**.
3. In Project Settings → API, copy your **Project URL** and **anon public** key.

## Open in Xcode and run

1. Open the project:  
   `open Sonder.xcodeproj`  
   (The project is generated from `project.yml`; you can run `xcodegen generate` after editing it.)

2. **Environment variables** (Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables):
   - `CLAUDE_API_KEY` — your Anthropic API key (for city score and travel profile).
   - `SUPABASE_URL` — your Supabase project URL (e.g. `https://xxxx.supabase.co`).
   - `SUPABASE_ANON_KEY` — your Supabase anon/public key.

3. **Run** on an iOS 17+ simulator (⌘R).

The app uses **anonymous auth** so each device gets a user without sign-up. Rated cities, travel profile, and feed are stored in Supabase.

## Demo flow

1. **Feed** — Empty until you or others add cities (activities appear here).
2. **Lists** — Tap **+ Add City** → pick a city → rate attractions → submit. City is saved to Supabase and appears with an AI-generated score.
3. **Profile** — After 3+ cities, your travel personality is generated via Claude and saved to Supabase.

## Project layout

```
Sonder/
  SonderApp.swift       # @main, configures Supabase + Claude
  AppStore.swift        # State; loads/saves via SupabaseService
  Views/                # Feed, Lists, Profile + shared components
  Models/               # City, TravelProfile
  Data/                 # Attractions (static list), FeedItem types
  Services/             # ClaudeService, SupabaseService
  Theme/                # Colors
supabase/
  schema.sql            # Tables + RLS (run in Supabase SQL Editor)
```

## Requirements

- Xcode 15+
- iOS 17+
- Supabase project (schema applied)
- Anthropic API key (for city score and profile)
