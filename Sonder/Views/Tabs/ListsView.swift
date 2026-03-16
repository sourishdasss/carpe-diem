import SwiftUI

struct ListsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAddCity = false
    @State private var listMode: ListMode = .rankings

    enum ListMode: String, CaseIterable {
        case rankings = "Rankings"
        case categories = "Categories"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.night900.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Picker("", selection: $listMode) {
                            ForEach(ListMode.allCases, id: \.rawValue) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        if listMode == .rankings {
                            rankingsContent
                        } else {
                            categoriesContent
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Lists")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddCity = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentAmber)
                    }
                }
            }
            .sheet(isPresented: $showAddCity) {
                AddCityPickerView(isPresented: $showAddCity)
            }
        }
    }

    private var rankingsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if store.ratedCities.isEmpty {
                Text("No cities yet. Tap + to add one.")
                    .font(.subheadline)
                    .foregroundStyle(Color.slate400)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                ForEach(store.ratedCities) { city in
                    CityCardView(city: city)
                }
            }
        }
    }

    private var categoriesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(AttractionCategory.allCases.filter { $0 != .general }, id: \.rawValue) { cat in
                VStack(alignment: .leading, spacing: 8) {
                    Label(cat.rawValue, systemImage: cat.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentAmber)
                    Text("Attractions you've rated in this category appear here.")
                        .font(.caption)
                        .foregroundStyle(Color.slate400)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.night800)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

struct AddCityPickerView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var store: AppStore
    @State private var selectedCity: CityData?

    private var availableCities: [CityData] {
        let ratedIds = Set(store.ratedCities.map { $0.cityData.id })
        return Attractions.allCities.filter { !ratedIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.night900.ignoresSafeArea()
                List(availableCities, id: \.id) { city in
                    Button {
                        selectedCity = city
                    } label: {
                        HStack {
                            Text(city.flag)
                            Text("\(city.city), \(city.country)")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color.slate400)
                        }
                    }
                    .listRowBackground(Color.night800)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundStyle(Color.accentAmber)
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

