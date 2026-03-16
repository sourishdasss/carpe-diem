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
                Color.night900.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        Text("Rate attractions you've visited (1–5). Skip ones you haven't.")
                            .font(.subheadline)
                            .foregroundStyle(Color.slate400)
                        ForEach(cityData.attractions) { att in
                            AttractionRaterView(attraction: att, score: Binding(
                                get: { ratings[att.id] },
                                set: { ratings[att.id] = $0 }
                            ))
                        }
                        if let msg = store.errorMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        submitButton
                    }
                    .padding()
                }
            }
            .navigationTitle("\(cityData.city), \(cityData.country)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.accentAmber)
                }
            }
        }
        .onDisappear { store.errorMessage = nil }
    }

    private var header: some View {
        AsyncImage(url: URL(string: cityData.photoURL)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default:
                Color.night700
            }
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
            Text(store.isLoadingCityScore ? "Generating…" : "Add city & get score")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(ratings.isEmpty ? Color.slate700 : Color.accentAmber)
                .foregroundStyle(ratings.isEmpty ? Color.slate400 : Color.night900)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(ratings.isEmpty || store.isLoadingCityScore)
    }
}
