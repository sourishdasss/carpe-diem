import SwiftUI

struct AddCitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore
    let cityData: CityData
    var onDismiss: (() -> Void)?

    @State private var attractions: [Attraction] = []
    @State private var ratings: [UUID: Int] = [:]
    @State private var isSubmitting = false
    @State private var isLoadingAttractions = true
    @State private var showAddAttraction = false

    private var supabase: SupabaseService { SupabaseService.shared }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonderBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        Text("Rate attractions you've visited (1–5). Add more below if you like.")
                            .font(.georgia(14))
                            .foregroundStyle(Color.sonderTextSecond)
                        if isLoadingAttractions {
                            HStack(spacing: 8) {
                                ProgressView().scaleEffect(0.9)
                                Text("Loading attractions…")
                                    .font(.georgia(14))
                                    .foregroundStyle(Color.sonderTextSecond)
                            }
                            .padding(.vertical, 8)
                        } else {
                            ForEach(attractions) { att in
                                AttractionRaterView(attraction: att, score: Binding(
                                    get: { ratings[att.id] },
                                    set: { ratings[att.id] = $0 }
                                ))
                            }
                            addAttractionButton
                        }
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
                    Button("Cancel") { dismiss() }
                        .font(.georgia(15))
                        .foregroundStyle(Color.sonderAccent)
                }
            }
            .task {
                await loadAttractions()
            }
            .sheet(isPresented: $showAddAttraction) {
                AddAttractionSheet(
                    cityName: cityData.city,
                    country: cityData.country
                ) { newAttraction in
                    attractions.append(newAttraction)
                    showAddAttraction = false
                }
            }
        }
        .onAppear {
            attractions = cityData.attractions
        }
        .onDisappear { store.errorMessage = nil }
    }

    private var addAttractionButton: some View {
        Button {
            showAddAttraction = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.sonderAccent)
                Text("Add an attraction for others to rate")
                    .font(.georgia(15))
                    .foregroundStyle(Color.sonderAccent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.sonderAccent.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.vertical, 6)
    }

    private func loadAttractions() async {
        isLoadingAttractions = true
        defer { isLoadingAttractions = false }
        attractions = cityData.attractions
        guard supabase.isConfigured else { return }
        do {
            let userAdded = try await supabase.fetchCityAttractions(cityName: cityData.city, country: cityData.country)
            let existingIds = Set(attractions.map(\.id))
            let newOnes = userAdded.filter { !existingIds.contains($0.id) }
            attractions.append(contentsOf: newOnes)
        } catch {
            // Non-fatal: keep template only
        }
    }

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
                let dataToSubmit = CityData(
                    id: cityData.id,
                    city: cityData.city,
                    country: cityData.country,
                    flag: cityData.flag,
                    photoURL: cityData.photoURL,
                    attractions: attractions
                )
                await store.submitCityRatings(cityData: dataToSubmit, ratings: ratings)
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
                Text(store.isLoadingCityScore ? "Generating score…" : "Add city & get score")
                    .font(.georgiaBold(16))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(ratings.isEmpty ? Color.sonderDivider : Color.sonderAccent)
            .foregroundStyle(ratings.isEmpty ? Color.sonderTextSecond : .white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(ratings.isEmpty || store.isLoadingCityScore)
        .padding(.top, 8)
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
                    Text("This attraction will be available for everyone to rate in \(cityName).")
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
                            Text(isSaving ? "Adding…" : "Add attraction")
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
            .navigationTitle("Add attraction")
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
        guard !trimmed.isEmpty, supabase.isConfigured else {
            errorMessage = "Enter a name."
            return
        }
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
    }
}
