import SwiftUI
import MapKit
import CoreLocation

// MARK: - Map Pin Model

struct CityMapPin: Identifiable {
    let id: String
    let city: RatedCity
    let coordinate: CLLocationCoordinate2D
}

// MARK: - World map default

private extension MapCameraPosition {
    /// Wide view so Places opens on a world-scale map (pins still visible; user can zoom).
    static var sonderWorld: MapCameraPosition {
        .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20, longitude: 10),
            span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 120)
        ))
    }
}

// MARK: - Main View

struct TravelMapView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedPin: CityMapPin?
    @State private var showAddCity = false
    @State private var cameraPosition: MapCameraPosition = .sonderWorld

    @State private var pins: [CityMapPin] = []
    @State private var coordinateCache: [String: CLLocationCoordinate2D] = [:]
    @State private var geocodeTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            mapLayer
            statsOverlay
            addButton
        }
        .ignoresSafeArea(edges: .top)
        .sheet(item: $selectedPin) { pin in
            CityPinDetailSheet(pin: pin)
        }
        .sheet(isPresented: $showAddCity) {
            AddCityPickerView(isPresented: $showAddCity)
        }
        .onAppear {
            // Tab switch recreates this view — always start from a world-scale map.
            cameraPosition = .sonderWorld
            updatePinsFromRatedCities()
        }
        .onChange(of: store.ratedCities.count) { _, _ in
            updatePinsFromRatedCities()
        }
    }

    // MARK: - Map Layer

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            ForEach(pins) { pin in
                Annotation(
                    pin.city.cityData.city,
                    coordinate: pin.coordinate,
                    anchor: .bottom
                ) {
                    CityPinView(pin: pin)
                        .onTapGesture { selectedPin = pin }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
    }

    // MARK: - Stats Overlay

    private var statsOverlay: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(pins.count) \(pins.count == 1 ? "place" : "places")")
                .font(.georgiaBold(16))
                .foregroundStyle(Color.sonderTextPrimary)
            Text("\(uniqueCountries) \(uniqueCountries == 1 ? "country" : "countries")")
                .font(.georgia(13))
                .foregroundStyle(Color.sonderTextSecond)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, 60)
        .padding(.leading, 16)
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            showAddCity = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.sonderAccent)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.sonderAccent.opacity(0.4), radius: 10, x: 0, y: 4)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 36)
    }

    private var uniqueCountries: Int {
        Set(store.ratedCities.map { $0.cityData.country }).count
    }

    // MARK: - Geocoding

    private func cityKey(_ city: RatedCity) -> String {
        "\(city.cityData.city)|\(city.cityData.country)"
    }

    private func updatePinsFromRatedCities() {
        geocodeTask?.cancel()

        geocodeTask = Task {
            var nextPins: [CityMapPin] = []

            // Geocode each city; keep it simple for MVP.
            for city in store.ratedCities {
                if Task.isCancelled { return }

                let key = cityKey(city)
                if let cached = coordinateCache[key] {
                    nextPins.append(CityMapPin(id: key, city: city, coordinate: cached))
                    continue
                }

                let coordinate = await geocode(city: city)
                if let coordinate {
                    coordinateCache[key] = coordinate
                    nextPins.append(CityMapPin(id: key, city: city, coordinate: coordinate))
                }
            }

            await MainActor.run {
                pins = nextPins
                // Do not use `.automatic` here — it zooms to fit pins. Keep world default until the user zooms.
            }
        }
    }

    private func geocode(city: RatedCity) async -> CLLocationCoordinate2D? {
        let cityName = city.cityData.city.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawCountryName = city.cityData.country.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cityName.isEmpty else { return nil }

        let countryName: String = rawCountryName.lowercased() == "unknown" ? "" : rawCountryName
        let query = [cityName, countryName].filter { !$0.isEmpty }.joined(separator: ", ")
        let geocoder = CLGeocoder()

        return await withCheckedContinuation { continuation in
            geocoder.geocodeAddressString(query) { placemarks, error in
                if let loc = placemarks?.first?.location {
                    continuation.resume(returning: loc.coordinate)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

// MARK: - Pin View

struct CityPinView: View {
    let pin: CityMapPin

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                AsyncImage(url: URL(string: pin.city.cityData.photoURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Color.sonderDivider
                    }
                }
                .frame(width: 46, height: 46)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.sonderAccent, lineWidth: 2.5))

                // Score badge
                Text(String(format: "%.1f", pin.city.cumulativeScore))
                    .font(.georgiaBold(8))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.sonderAccent)
                    .clipShape(Capsule())
                    .offset(x: 14, y: -14)
            }
            .shadow(color: .black.opacity(0.18), radius: 4, x: 0, y: 2)

            // Teardrop spike
            Triangle()
                .fill(Color.sonderAccent)
                .frame(width: 10, height: 8)
        }
    }
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Pin Detail Sheet

struct CityPinDetailSheet: View {
    let pin: CityMapPin
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.sonderDivider)
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // City photo
            AsyncImage(url: URL(string: pin.city.cityData.photoURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Color.sonderDivider
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipped()

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(pin.city.cityData.flag).font(.system(size: 26))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pin.city.cityData.city)
                            .font(.georgiaBold(22))
                            .foregroundStyle(Color.sonderTextPrimary)
                        Text(pin.city.cityData.country)
                            .font(.georgia(14))
                            .foregroundStyle(Color.sonderTextSecond)
                    }
                    Spacer()
                    // Score
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(String(format: "%.1f", pin.city.cumulativeScore))
                            .font(.georgiaBold(28))
                            .foregroundStyle(Color.sonderAccent)
                        Text("/ 10")
                            .font(.georgia(13))
                            .foregroundStyle(Color.sonderTextSecond)
                    }
                }

                if !pin.city.summary.isEmpty {
                    Text(pin.city.summary)
                        .font(.georgia(14))
                        .foregroundStyle(Color.sonderTextSecond)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let highlight = pin.city.topAttractionName, !highlight.isEmpty {
                    Label(highlight, systemImage: "star.fill")
                        .font(.georgia(13))
                        .foregroundStyle(Color.sonderAccent)
                }
            }
            .padding(20)

            Spacer()
        }
        .background(Color.sonderBackground)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}
