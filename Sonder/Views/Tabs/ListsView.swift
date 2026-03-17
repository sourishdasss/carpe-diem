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
    @State private var selectedCity: CityData?
    @State private var searchText = ""
    @State private var manualCity = ""
    @State private var manualCountry = ""
    @State private var isSearchingCities = false
    @State private var citySearchResults: [CitySearchResult] = []

    private var availableCities: [CityData] {
        let ratedIds = Set(store.ratedCities.map { $0.cityData.id })
        let all = Attractions.allCities.filter { !ratedIds.contains($0.id) }
        if searchText.isEmpty || !citySearchResults.isEmpty {
            // When using real city search, suggested list is independent.
            return all
        }
        return all.filter {
            $0.city.localizedCaseInsensitiveContains(searchText) ||
            $0.country.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonderBackground.ignoresSafeArea()
                List {
                    Section("Any city in the world") {
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("Search for a city (e.g. Paris, Tokyo)", text: $manualCity)
                                .textInputAutocapitalization(.words)
                                .font(.georgia(15))
                            Button {
                                runCitySearch()
                            } label: {
                                HStack(spacing: 8) {
                                    if isSearchingCities {
                                        ProgressView().scaleEffect(0.8)
                                    }
                                    Text(isSearchingCities ? "Searching…" : "Search cities")
                                }
                                    .font(.georgiaBold(15))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(manualCity.trimmingCharacters(in: .whitespaces).isEmpty ? Color.sonderDivider : Color.sonderAccent)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .disabled(manualCity.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.sonderSurface)

                        if !citySearchResults.isEmpty {
                            ForEach(citySearchResults, id: \.id) { result in
                                Button {
                                    let cityData = Attractions.templateCity(city: result.city, country: result.country)
                                    selectedCity = cityData
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.city)
                                            .font(.georgiaBold(16))
                                            .foregroundStyle(Color.sonderTextPrimary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text(result.country)
                                            .font(.georgia(13))
                                            .foregroundStyle(Color.sonderTextSecond)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.vertical, 6)
                                }
                                .listRowBackground(Color.sonderSurface)
                            }
                        } else if !manualCity.trimmingCharacters(in: .whitespaces).isEmpty && !isSearchingCities {
                            // Fallback: let user proceed with whatever they typed if search has no results
                            Button {
                                let cityData = Attractions.templateCity(city: manualCity, country: manualCountry)
                                selectedCity = cityData
                            } label: {
                                Text("Use \"\(manualCity.trimmingCharacters(in: .whitespaces))\" as typed")
                                    .font(.georgia(14))
                                    .foregroundStyle(Color.sonderAccent)
                            }
                            .listRowBackground(Color.sonderSurface)
                        }
                    }

                    Section("Suggested cities") {
                        ForEach(availableCities, id: \.id) { city in
                            Button {
                                selectedCity = city
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(city.city)
                                        .font(.georgiaBold(16))
                                        .foregroundStyle(Color.sonderTextPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(city.country)
                                        .font(.georgia(13))
                                        .foregroundStyle(Color.sonderTextSecond)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 8)
                            }
                            .listRowBackground(Color.sonderSurface)
                            .listRowSeparatorTint(Color.sonderDivider)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, prompt: "Search suggested cities")
            }
            .navigationTitle("Add City")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.sonderBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .font(.georgia(15))
                        .foregroundStyle(Color.sonderAccent)
                }
            }
            .sheet(item: $selectedCity) { city in
                AddCitySheet(cityData: city) {
                    selectedCity = nil
                    isPresented = false
                    manualCity = ""
                    manualCountry = ""
                    searchText = ""
                    citySearchResults = []
                }
            }
        }
    }
}

// MARK: - City search result for MapKit-based lookup

fileprivate struct CitySearchResult {
    let id = UUID()
    let city: String
    let country: String
}

fileprivate extension AddCityPickerView {
    func runCitySearch() {
        let query = manualCity.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isSearchingCities = true
        citySearchResults = []
        var request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        MKLocalSearch(request: request).start { response, _ in
            DispatchQueue.main.async {
                isSearchingCities = false
                guard let response = response else { return }
                var seen = Set<String>()
                let results: [CitySearchResult] = response.mapItems.compactMap { item in
                    let p = item.placemark
                    let city = p.locality ?? p.administrativeArea ?? p.name ?? ""
                    let country = p.country ?? ""
                    guard !city.isEmpty else { return nil }
                    let key = "\(city)|\(country)"
                    guard !seen.contains(key) else { return nil }
                    seen.insert(key)
                    return CitySearchResult(city: city, country: country)
                }
                self.citySearchResults = Array(results.prefix(20))
            }
        }
    }
}
