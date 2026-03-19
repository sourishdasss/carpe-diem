import SwiftUI
import MapKit

struct ListsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAddCity = false
    @State private var listMode: ListMode = .rankings

    enum ListMode: String, CaseIterable {
        case rankings   = "Rankings"
        case categories = "Categories"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonderBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        modePicker
                        if listMode == .rankings {
                            rankingsContent
                        } else {
                            categoriesContent
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Lists")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.sonderBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddCity = true } label: {
                        Label("Add City", systemImage: "plus.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.title2)
                            .foregroundStyle(Color.sonderAccent)
                    }
                }
            }
            .sheet(isPresented: $showAddCity) {
                AddCityPickerView(isPresented: $showAddCity)
            }
        }
    }

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(ListMode.allCases, id: \.rawValue) { mode in
                Button {
                    listMode = mode
                } label: {
                    Text(mode.rawValue)
                        .font(listMode == mode ? .georgiaBold(15) : .georgia(15))
                        .foregroundStyle(listMode == mode ? Color.sonderAccent : Color.sonderTextSecond)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            listMode == mode
                                ? Color.sonderAccent.opacity(0.1)
                                : Color.sonderSurface
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.sonderDivider, lineWidth: 1)
        )
    }

    private var rankingsContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if store.ratedCities.isEmpty {
                emptyRankings
            } else {
                ForEach(Array(store.ratedCities.enumerated()), id: \.element.id) { index, city in
                    HStack(alignment: .top, spacing: 14) {
                        // Rank number
                        Text("#\(index + 1)")
                            .font(.georgiaBold(18))
                            .foregroundStyle(index == 0 ? Color.sonderAccent : Color.sonderTextSecond)
                            .frame(width: 32)
                            .padding(.top, 2)

                        CityCardView(city: city)
                    }
                }
            }
        }
    }

    private var emptyRankings: some View {
        VStack(spacing: 14) {
            Image(systemName: "map")
                .font(.system(size: 40))
                .foregroundStyle(Color.sonderDivider)
            Text("No cities yet")
                .font(.georgiaBold(17))
                .foregroundStyle(Color.sonderTextPrimary)
            Text("Tap + to log your first destination.")
                .font(.georgia(14))
                .foregroundStyle(Color.sonderTextSecond)
            Button {
                showAddCity = true
            } label: {
                Text("Add your first city")
                    .font(.georgiaBold(15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 11)
                    .background(Color.sonderAccent)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var categoriesContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(AttractionCategory.allCases.filter { $0 != .general }, id: \.rawValue) { cat in
                categoryRow(cat)
            }
        }
    }

    private func categoryRow(_ cat: AttractionCategory) -> some View {
        let ratingsForCat = store.ratedCities.flatMap { city in
            city.ratings.compactMap { r -> (String, Int)? in
                guard let att = city.cityData.attractions.first(where: { $0.id == r.attractionId }),
                      att.category == cat else { return nil }
                return (att.name, r.score)
            }
        }

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: cat.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.sonderSage)
                Text(cat.rawValue)
                    .font(.georgiaBold(16))
                    .foregroundStyle(Color.sonderTextPrimary)
                Spacer()
                Text("\(ratingsForCat.count)")
                    .font(.georgiaBold(14))
                    .foregroundStyle(Color.sonderTextSecond)
            }

            if ratingsForCat.isEmpty {
                Text("No ratings yet in this category.")
                    .font(.georgia(13))
                    .foregroundStyle(Color.sonderTextSecond)
            } else {
                ForEach(ratingsForCat.prefix(3), id: \.0) { name, score in
                    HStack {
                        Text(name)
                            .font(.georgia(14))
                            .foregroundStyle(Color.sonderTextPrimary)
                        Spacer()
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= score ? "star.fill" : "star")
                                    .font(.system(size: 10))
                                    .foregroundStyle(i <= score ? Color.sonderAccent : Color.sonderDivider)
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sonderSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

struct AddCityPickerView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var store: AppStore
    @StateObject private var citySearch = CitySearchCompleterService()
    @State private var selectedCity: CityData?
    @State private var manualCity = ""
    @State private var isSearchingFullQuery = false
    @State private var isResolvingPick = false
    @State private var fullSearchResults: [ResolvedCityPlace] = []

    private var trimmedQuery: String {
        manualCity.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var showUseAsTypedFallback: Bool {
        !trimmedQuery.isEmpty
            && !citySearch.completerIsLoading
            && !isSearchingFullQuery
            && citySearch.suggestions.isEmpty
            && fullSearchResults.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonderBackground.ignoresSafeArea()
                List {
                    if citySearch.completerIsLoading && !trimmedQuery.isEmpty {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Searching…")
                                .font(.georgia(14))
                                .foregroundStyle(Color.sonderTextSecond)
                        }
                        .listRowBackground(Color.sonderSurface)
                    }

                    if !citySearch.suggestions.isEmpty {
                        Section {
                            ForEach(citySearch.suggestions.map(CityCompletionRow.init)) { row in
                                Button {
                                    selectCompletion(row.completion)
                                } label: {
                                    citySuggestionLabel(row.completion)
                                }
                                .listRowBackground(Color.sonderSurface)
                            }
                        } header: {
                            Text("Suggestions")
                                .font(.georgia(13))
                                .foregroundStyle(Color.sonderTextSecond)
                                .textCase(nil)
                        }
                    }

                    if isSearchingFullQuery {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Looking up places…")
                                .font(.georgia(14))
                                .foregroundStyle(Color.sonderTextSecond)
                        }
                        .listRowBackground(Color.sonderSurface)
                    }

                    if !fullSearchResults.isEmpty {
                        Section {
                            ForEach(fullSearchResults, id: \.self) { place in
                                Button {
                                    selectedCity = Attractions.templateCity(city: place.city, country: place.country)
                                } label: {
                                    cityResultLabel(city: place.city, country: place.country)
                                }
                                .listRowBackground(Color.sonderSurface)
                            }
                        } header: {
                            Text("Results")
                                .font(.georgia(13))
                                .foregroundStyle(Color.sonderTextSecond)
                                .textCase(nil)
                        }
                    }

                    if showUseAsTypedFallback {
                        Section {
                            Button {
                                selectedCity = Attractions.templateCity(city: trimmedQuery, country: "")
                            } label: {
                                Text("Use “\(trimmedQuery)”")
                                    .font(.georgia(14))
                                    .foregroundStyle(Color.sonderAccent)
                            }
                            .listRowBackground(Color.sonderSurface)
                        } header: {
                            Text("No matches")
                                .font(.georgia(13))
                                .foregroundStyle(Color.sonderTextSecond)
                                .textCase(nil)
                        }
                    }

                    if trimmedQuery.isEmpty {
                        Section {
                            Text("Start typing a city or town — suggestions appear as you type, like Apple Maps. Tap Search on the keyboard for a full place lookup.")
                                .font(.georgia(14))
                                .foregroundStyle(Color.sonderTextSecond)
                                .listRowBackground(Color.sonderSurface)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

                if isResolvingPick {
                    Color.black.opacity(0.12)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.15)
                }
            }
            .navigationTitle("Add City")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $manualCity,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search cities or towns"
            )
            .textInputAutocapitalization(.words)
            .submitLabel(.search)
            .onChange(of: manualCity) { _, new in
                citySearch.updateQueryFragment(new)
            }
            .onSubmit(of: .search) {
                runFullTextSearch()
            }
            .toolbarBackground(Color.sonderBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .font(.georgia(15))
                        .foregroundStyle(Color.sonderAccent)
                }
            }
            .sheet(item: $selectedCity, onDismiss: {
                citySearch.reset()
                manualCity = ""
                fullSearchResults = []
            }) { city in
                AddCitySheet(cityData: city) {
                    selectedCity = nil
                    isPresented = false
                    manualCity = ""
                    fullSearchResults = []
                    citySearch.reset()
                }
            }
        }
    }

    private func citySuggestionLabel(_ completion: MKLocalSearchCompletion) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "mappin.and.ellipse")
                .font(.body)
                .foregroundStyle(Color.sonderTextSecond)
                .frame(width: 28, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(completion.title)
                    .font(.georgiaBold(16))
                    .foregroundStyle(Color.sonderTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !completion.subtitle.isEmpty {
                    Text(completion.subtitle)
                        .font(.georgia(13))
                        .foregroundStyle(Color.sonderTextSecond)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(completion.title), \(completion.subtitle)")
    }

    private func cityResultLabel(city: String, country: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(city)
                .font(.georgiaBold(16))
                .foregroundStyle(Color.sonderTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if !country.isEmpty {
                Text(country)
                    .font(.georgia(13))
                    .foregroundStyle(Color.sonderTextSecond)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private func selectCompletion(_ completion: MKLocalSearchCompletion) {
        isResolvingPick = true
        CitySearchCompleterService.resolveCompletion(completion) { place in
            isResolvingPick = false
            guard let place else { return }
            selectedCity = Attractions.templateCity(city: place.city, country: place.country)
        }
    }

    private func runFullTextSearch() {
        let q = trimmedQuery
        guard !q.isEmpty else { return }
        isSearchingFullQuery = true
        fullSearchResults = []
        CitySearchCompleterService.searchPlaces(query: q) { places in
            isSearchingFullQuery = false
            fullSearchResults = places
        }
    }
}

// MARK: - Stable rows for MKLocalSearchCompletion

private struct CityCompletionRow: Identifiable {
    let id: String
    let completion: MKLocalSearchCompletion

    init(_ completion: MKLocalSearchCompletion) {
        self.completion = completion
        self.id = "\(completion.title)|\(completion.subtitle)"
    }
}
