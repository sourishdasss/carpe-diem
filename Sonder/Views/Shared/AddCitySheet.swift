import SwiftUI

struct AddCitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: AppStore
    let cityData: CityData
    var onDismiss: (() -> Void)?

    @State private var ratings: [UUID: Int] = [:]
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonderBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        Text("Rate attractions you've visited (1–5). Skip ones you haven't been to.")
                            .font(.georgia(14))
                            .foregroundStyle(Color.sonderTextSecond)
                        ForEach(cityData.attractions) { att in
                            AttractionRaterView(attraction: att, score: Binding(
                                get: { ratings[att.id] },
                                set: { ratings[att.id] = $0 }
                            ))
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
        }
        .onDisappear { store.errorMessage = nil }
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
                await store.submitCityRatings(cityData: cityData, ratings: ratings)
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
