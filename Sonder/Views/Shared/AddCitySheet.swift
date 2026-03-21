import SwiftUI
import CoreLocation

struct AddCitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore
    let cityData: CityData
    var onDismiss: (() -> Void)?

    /// Per-category ranked lists, best-first.
    @State private var categoryRankings: [AttractionCategory: [Attraction]] = [:]

    @StateObject private var poiSearch: AttractionPOISearchCompleter
    @State private var poiQuery = ""
    @State private var showAddAttraction = false
    @State private var isSubmitting = false

    /// Set when a new attraction needs Beli-style ranking within its category.
    @State private var pendingCompare: Attraction?

    private var supabase: SupabaseService { SupabaseService.shared }

    init(cityData: CityData, onDismiss: (() -> Void)? = nil) {
        self.cityData = cityData
        self.onDismiss = onDismiss
        let initial = CLLocationCoordinate2D(latitude: 20, longitude: 10)
        _poiSearch = StateObject(wrappedValue: AttractionPOISearchCompleter(regionCenter: initial, spanDegrees: 0.45))
    }

    private var allAttractions: [Attraction] {
        var result: [Attraction] = []
        for cat in AttractionCategory.allCases {
            if let ranked = categoryRankings[cat] {
                result.append(contentsOf: ranked)
            }
        }
        return result
    }

    private var hasAttractions: Bool {
        categoryRankings.values.contains { !$0.isEmpty }
    }

    private var activeCategories: [AttractionCategory] {
        AttractionCategory.allCases.filter { categoryRankings[$0]?.isEmpty == false }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonderBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        searchSection
                        rankingsSection

                        if let msg = store.errorMessage {
                            Text(msg)
                                .font(.georgia(13))
                                .foregroundStyle(.red)
                        }

                        submitButton
                    }
                    .padding(16)
                }
            }
            .navigationTitle("\(cityData.city), \(cityData.country)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.sonderBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onDismiss?()
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.georgia(15))
                        .foregroundStyle(Color.sonderAccent)
                    }
                }
            }
            .task {
                poiSearch.setCityContextForQuery(cityName: cityData.city, country: cityData.country)
                await geocodeCityForSearch()
            }
            .onChange(of: poiQuery) { _, new in
                poiSearch.updateQueryFragment(new)
            }
            .onChange(of: poiSearch.isCityScoped) { _, scoped in
                if scoped, !poiQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    poiSearch.updateQueryFragment(poiQuery)
                }
            }
            .sheet(item: $pendingCompare) { att in
                AttractionCompareModal(
                    newAttraction: att,
                    existingRanked: categoryRankings[att.category] ?? [],
                    cityLabel: cityData.city,
                    onComplete: { rankedList in
                        categoryRankings[att.category] = rankedList
                        pendingCompare = nil
                    },
                    onSkip: {
                        var list = categoryRankings[att.category] ?? []
                        list.append(att)
                        categoryRankings[att.category] = list
                        pendingCompare = nil
                    }
                )
            }
            .sheet(isPresented: $showAddAttraction) {
                AddAttractionSheet(
                    cityName: cityData.city,
                    country: cityData.country
                ) { newAttraction in
                    insertAttraction(newAttraction)
                    showAddAttraction = false
                }
            }
        }
        .onDisappear { store.errorMessage = nil }
    }

    // MARK: - Search

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add places")
                .font(.georgiaBold(15))
                .foregroundStyle(Color.sonderTextPrimary)

            TextField("Search restaurants, museums, parks…", text: $poiQuery)
                .font(.georgia(16))
                .padding(12)
                .background(Color.sonderSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .textInputAutocapitalization(.sentences)

            if !poiSearch.isCityScoped {
                Text("Locating \(cityData.city) on the map…")
                    .font(.georgia(12))
                    .foregroundStyle(Color.sonderTextSecond)
            }

            if poiSearch.isLoading && !poiQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.85)
                    Text("Searching…")
                        .font(.georgia(13))
                        .foregroundStyle(Color.sonderTextSecond)
                }
            }

            if !poiSearch.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(poiSearch.suggestions) { row in
                        Button {
                            selectPlaceSearchResult(row)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(Color.sonderAccent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(row.title)
                                        .font(.georgiaBold(14))
                                        .foregroundStyle(Color.sonderTextPrimary)
                                    if !row.subtitle.isEmpty {
                                        Text(row.subtitle)
                                            .font(.georgia(12))
                                            .foregroundStyle(Color.sonderTextSecond)
                                    }
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(Color.sonderSage)
                            }
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
                .padding(.horizontal, 12)
                .background(Color.sonderSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button {
                showAddAttraction = true
            } label: {
                Label("Add custom place", systemImage: "plus.circle")
                    .font(.georgia(14))
                    .foregroundStyle(Color.sonderAccent)
            }
            .padding(.top, 4)
        }
    }

    private func selectPlaceSearchResult(_ row: CityPlaceSearchResult) {
        guard let att = AttractionPOISearchCompleter.attractionFromMapItem(row.mapItem) else { return }
        insertAttraction(att)
        poiQuery = ""
        poiSearch.reset()
    }

    // MARK: - Rankings display

    private var rankingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !hasAttractions {
                VStack(spacing: 10) {
                    Image(systemName: "list.number")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.sonderDivider)
                    Text("Your rankings will appear here")
                        .font(.georgia(14))
                        .foregroundStyle(Color.sonderTextSecond)
                    Text("Search above to add the places you visited. Each new place gets ranked against others in the same category.")
                        .font(.georgia(13))
                        .foregroundStyle(Color.sonderTextSecond)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(activeCategories, id: \.rawValue) { cat in
                    categoryRankingCard(cat)
                }
            }
        }
    }

    private func categoryRankingCard(_ cat: AttractionCategory) -> some View {
        let ranked = categoryRankings[cat] ?? []
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: cat.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.sonderSage)
                Text(cat.rawValue)
                    .font(.georgiaBold(15))
                    .foregroundStyle(Color.sonderTextPrimary)
                Spacer()
                Text("\(ranked.count)")
                    .font(.georgiaBold(13))
                    .foregroundStyle(Color.sonderTextSecond)
            }

            ForEach(Array(ranked.enumerated()), id: \.element.id) { index, att in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.georgiaBold(16))
                        .foregroundStyle(index == 0 ? Color.sonderAccent : Color.sonderTextSecond)
                        .frame(width: 24, alignment: .trailing)

                    Text(att.name)
                        .font(.georgia(15))
                        .foregroundStyle(Color.sonderTextPrimary)

                    Spacer()

                    Button {
                        removeAttraction(att, from: cat)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.sonderDivider)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
            }
        }
        .padding(14)
        .background(Color.sonderSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Header & submit

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: cityData.photoURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Color.sonderDivider
                }
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            LinearGradient(
                colors: [.clear, .black.opacity(0.65)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(cityData.flag)
                    .font(.system(size: 28))
                Text(cityData.city)
                    .font(.georgiaBold(22))
                    .foregroundStyle(.white)
                Text(cityData.country)
                    .font(.georgia(14))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(14)
        }
    }

    private var submitButton: some View {
        Button {
            Task {
                isSubmitting = true
                let entries = buildVisitEntries()
                let dataToSubmit = CityData(
                    id: cityData.id,
                    city: cityData.city,
                    country: cityData.country,
                    flag: cityData.flag,
                    photoURL: cityData.photoURL,
                    attractions: allAttractions
                )
                await store.submitCityRatings(cityData: dataToSubmit, visitEntries: entries)
                isSubmitting = false
                if store.errorMessage == nil {
                    onDismiss?()
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: 8) {
                if store.isLoadingCityScore {
                    ProgressView().tint(.white)
                }
                Text(store.isLoadingCityScore ? "Building your city snapshot…" : "Save visit")
                    .font(.georgiaBold(16))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(hasAttractions ? Color.sonderAccent : Color.sonderDivider)
            .foregroundStyle(hasAttractions ? Color.white : Color.sonderTextSecond)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(!hasAttractions || store.isLoadingCityScore || isSubmitting)
        .padding(.top, 8)
    }

    // MARK: - Data

    private func geocodeCityForSearch() async {
        let query = [cityData.city, cityData.country].filter { !$0.isEmpty }.joined(separator: ", ")
        let geocoder = CLGeocoder()
        guard !query.isEmpty else {
            await MainActor.run {
                poiSearch.configure(
                    cityName: cityData.city,
                    country: cityData.country,
                    center: nil,
                    searchRegion: nil,
                    maxRadiusMeters: 55_000
                )
            }
            return
        }
        if let placemarks = try? await geocoder.geocodeAddressString(query),
           let pm = placemarks.first,
           let loc = pm.location {
            let coord = loc.coordinate
            let built = CitySearchRegionBuilder.region(placemark: pm, coordinate: coord)
            await MainActor.run {
                poiSearch.configure(
                    cityName: cityData.city,
                    country: cityData.country,
                    center: coord,
                    searchRegion: built.region,
                    maxRadiusMeters: min(built.radiusCap * 1.1, 85_000)
                )
            }
        } else {
            await MainActor.run {
                poiSearch.configure(
                    cityName: cityData.city,
                    country: cityData.country,
                    center: nil,
                    searchRegion: nil,
                    maxRadiusMeters: 55_000
                )
            }
        }
    }

    /// Beli-style: insert an attraction, opening the compare modal if the category already has entries.
    private func insertAttraction(_ att: Attraction) {
        let key = "\(att.name.lowercased())|\(att.category.rawValue)"
        let isDuplicate = allAttractions.contains {
            "\($0.name.lowercased())|\($0.category.rawValue)" == key
        }
        guard !isDuplicate else { return }

        let existing = categoryRankings[att.category] ?? []
        if existing.isEmpty {
            categoryRankings[att.category, default: []].append(att)
        } else {
            pendingCompare = att
        }
    }

    private func removeAttraction(_ att: Attraction, from cat: AttractionCategory) {
        categoryRankings[cat]?.removeAll { $0.id == att.id }
        if categoryRankings[cat]?.isEmpty == true {
            categoryRankings.removeValue(forKey: cat)
        }
    }

    private func buildVisitEntries() -> [CityVisitAttractionEntry] {
        var entries: [CityVisitAttractionEntry] = []
        for (_, ranked) in categoryRankings {
            let total = ranked.count
            for (index, att) in ranked.enumerated() {
                let rank = index + 1
                let sentiment = VisitSentiment.fromRankPosition(rank: rank, total: total)
                entries.append(CityVisitAttractionEntry(
                    attraction: att,
                    sentiment: sentiment,
                    rankInCategory: rank,
                    categoryCount: total
                ))
            }
        }
        return entries
    }
}

// MARK: - Add single attraction (name + category)

struct AddAttractionSheet: View {
    let cityName: String
    let country: String
    var onSave: (Attraction) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var category: AttractionCategory = .experience
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var supabase: SupabaseService { SupabaseService.shared }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonderBackground.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    Text("Add a place you visited in \(cityName).")
                        .font(.georgia(14))
                        .foregroundStyle(Color.sonderTextSecond)
                    TextField("Attraction name", text: $name)
                        .font(.georgia(16))
                        .padding(12)
                        .background(Color.sonderSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Text("Category")
                        .font(.georgiaBold(14))
                        .foregroundStyle(Color.sonderTextPrimary)
                    Picker("Category", selection: $category) {
                        ForEach(AttractionCategory.allCases.filter { $0 != .general }, id: \.rawValue) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    if let msg = errorMessage {
                        Text(msg)
                            .font(.georgia(13))
                            .foregroundStyle(.red)
                    }
                    Spacer()
                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView().tint(.white)
                            }
                            Text(isSaving ? "Adding…" : "Add to list")
                                .font(.georgiaBold(16))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.sonderDivider : Color.sonderAccent)
                        .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.sonderTextSecond : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
                .padding(20)
            }
            .navigationTitle("Custom place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.sonderBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.georgia(15))
                        .foregroundStyle(Color.sonderAccent)
                }
            }
        }
    }

    private func save() async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Enter a name."
            return
        }
        if supabase.isConfigured {
            isSaving = true
            errorMessage = nil
            defer { isSaving = false }
            do {
                let attraction = try await supabase.addCityAttraction(cityName: cityName, country: country, name: trimmed, category: category)
                onSave(attraction)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        } else {
            onSave(Attraction(name: trimmed, category: category))
            dismiss()
        }
    }
}
