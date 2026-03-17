import SwiftUI

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

    private var availableCities: [CityData] {
        let ratedIds = Set(store.ratedCities.map { $0.cityData.id })
        let all = Attractions.allCities.filter { !ratedIds.contains($0.id) }
        if searchText.isEmpty { return all }
        return all.filter {
            $0.city.localizedCaseInsensitiveContains(searchText) ||
            $0.country.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonderBackground.ignoresSafeArea()
                List(availableCities, id: \.id) { city in
                    Button {
                        selectedCity = city
                    } label: {
                        HStack(spacing: 12) {
                            Text(city.flag).font(.system(size: 26))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(city.city)
                                    .font(.georgiaBold(16))
                                    .foregroundStyle(Color.sonderTextPrimary)
                                Text(city.country)
                                    .font(.georgia(13))
                                    .foregroundStyle(Color.sonderTextSecond)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color.sonderDivider)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.sonderSurface)
                    .listRowSeparatorTint(Color.sonderDivider)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, prompt: "Search destinations")
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
                }
            }
        }
    }
}
