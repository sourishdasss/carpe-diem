import CoreLocation
import Foundation
import MapKit

/// One row in the city-scoped place search list (backed by a resolved `MKMapItem`).
struct CityPlaceSearchResult: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let mapItem: MKMapItem
}

/// MapKit place search limited to an area around a geocoded city (distance filter + regional query).
/// Replaces `MKLocalSearchCompleter`, which can return famous global POIs (e.g. CN Tower) even when the map region is Dubai.
final class AttractionPOISearchCompleter: ObservableObject {
    @Published private(set) var suggestions: [CityPlaceSearchResult] = []
    @Published private(set) var isLoading = false
    /// True once we have a city center and search region (strict filtering).
    @Published private(set) var isCityScoped: Bool = false

    private var debounceTask: Task<Void, Never>?
    private var cityName: String = ""
    private var country: String = ""
    private var cityCenter: CLLocationCoordinate2D?
    private var searchRegion: MKCoordinateRegion?
    /// Max straight-line distance from city center for a result to be shown.
    private(set) var maxRadiusMeters: CLLocationDistance = 55_000

    var searchRadiusKilometers: Int { Int(maxRadiusMeters / 1000) }

    init(regionCenter: CLLocationCoordinate2D, spanDegrees: Double = 0.45) {
        cityCenter = regionCenter
        searchRegion = MKCoordinateRegion(
            center: regionCenter,
            span: MKCoordinateSpan(
                latitudeDelta: spanDegrees,
                longitudeDelta: spanDegrees * 1.15
            )
        )
        isCityScoped = true
    }

    /// Sets city/country used in the search query immediately (before geocode finishes).
    func setCityContextForQuery(cityName: String, country: String) {
        self.cityName = cityName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.country = country.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Call after geocoding the city (tightens map search + distance cap).
    func configure(
        cityName: String,
        country: String,
        center: CLLocationCoordinate2D?,
        searchRegion: MKCoordinateRegion?,
        maxRadiusMeters radiusCap: CLLocationDistance = 55_000
    ) {
        setCityContextForQuery(cityName: cityName, country: country)
        self.cityCenter = center
        self.searchRegion = searchRegion
        self.maxRadiusMeters = max(15_000, min(radiusCap, 90_000))
        self.isCityScoped = center != nil && searchRegion != nil
    }

    /// Legacy helper used before full `configure` — tight urban span.
    func setRegion(center: CLLocationCoordinate2D, spanDegrees: Double = 0.38) {
        cityCenter = center
        searchRegion = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: spanDegrees,
                longitudeDelta: spanDegrees * max(0.8, 1 / max(0.25, cos(center.latitude * .pi / 180)))
            )
        )
        isCityScoped = true
    }

    func reset() {
        debounceTask?.cancel()
        debounceTask = nil
        suggestions = []
        isLoading = false
    }

    func updateQueryFragment(_ text: String) {
        debounceTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            suggestions = []
            isLoading = false
            return
        }
        isLoading = true
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 280_000_000)
            guard let self, !Task.isCancelled else { return }
            await self.performSearch(userQuery: trimmed)
        }
    }

    private func performSearch(userQuery: String) async {
        let cityLine = [cityName, country].filter { !$0.isEmpty }.joined(separator: ", ")
        let naturalLanguage: String = {
            if cityLine.isEmpty { return userQuery }
            return "\(userQuery), \(cityLine)"
        }()

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = naturalLanguage
        if let region = searchRegion {
            request.region = region
        }

        let items: [MKMapItem] = await withCheckedContinuation { continuation in
            MKLocalSearch(request: request).start { response, _ in
                continuation.resume(returning: response?.mapItems ?? [])
            }
        }

        guard !Task.isCancelled else {
            await MainActor.run { self.isLoading = false }
            return
        }

        let originLocation: CLLocation? = cityCenter.map {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude)
        }

        var filtered = items
        if let origin = originLocation {
            filtered = items.filter { item in
                let c = item.placemark.coordinate
                guard c.latitude >= -90, c.latitude <= 90, c.longitude >= -180, c.longitude <= 180 else {
                    return false
                }
                let loc = CLLocation(latitude: c.latitude, longitude: c.longitude)
                return loc.distance(from: origin) <= maxRadiusMeters
            }
        }

        var seen = Set<String>()
        let results: [CityPlaceSearchResult] = filtered.prefix(28).compactMap { item in
            let name = (item.name ?? item.placemark.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            let c = item.placemark.coordinate
            let key = String(format: "%.4f|%.4f|%@", c.latitude, c.longitude, name.lowercased())
            guard !seen.contains(key) else { return nil }
            seen.insert(key)
            let subtitle = Self.formatPlacemarkSubtitle(item.placemark)
            return CityPlaceSearchResult(title: name, subtitle: subtitle, mapItem: item)
        }

        await MainActor.run {
            self.suggestions = results
            self.isLoading = false
        }
    }

    private static func formatPlacemarkSubtitle(_ p: MKPlacemark) -> String {
        [p.locality, p.administrativeArea, p.country].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    }

    static func attractionFromMapItem(_ item: MKMapItem) -> Attraction? {
        let name = (item.name ?? item.placemark.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let cat = inferredCategory(for: item)
        return Attraction(name: name, category: cat)
    }

    /// MapKit added many `MKPointOfInterestCategory` cases in iOS 18; keep two paths for iOS 17 deployment.
    static func inferredCategory(for item: MKMapItem) -> AttractionCategory {
        guard let c = item.pointOfInterestCategory else { return .landmark }
        if #available(iOS 18.0, *) {
            switch c {
            case .museum, .library, .university, .school:
                return .culture
            case .nationalPark, .park, .beach, .campground:
                return .nature
            case .restaurant, .cafe, .bakery, .brewery, .winery, .distillery, .foodMarket, .store:
                return .food
            case .landmark, .castle, .fortress:
                return .landmark
            case .movieTheater, .nightlife, .amusementPark, .marina, .fitnessCenter, .stadium, .zoo, .aquarium:
                return .experience
            default:
                return .landmark
            }
        } else {
            switch c {
            case .museum, .library, .university, .school:
                return .culture
            case .nationalPark, .park, .beach, .campground:
                return .nature
            case .restaurant, .cafe, .bakery, .brewery, .winery, .store:
                return .food
            case .movieTheater, .nightlife, .amusementPark, .marina, .fitnessCenter, .stadium, .zoo, .aquarium:
                return .experience
            default:
                return .landmark
            }
        }
    }
}

// MARK: - Region helper (from geocode)

enum CitySearchRegionBuilder {
    /// Prefer the geocoder’s circular region; otherwise a compact box around the coordinate.
    static func region(
        placemark: CLPlacemark?,
        coordinate: CLLocationCoordinate2D,
        fallbackSpanDegrees: Double = 0.38
    ) -> (region: MKCoordinateRegion, radiusCap: CLLocationDistance) {
        if let circle = placemark?.region as? CLCircularRegion {
            let r = min(max(circle.radius, 8_000), 80_000)
            let latDelta = min(1.4, max(0.14, (r * 2.4) / 111_000))
            let cosLat = max(0.25, cos(coordinate.latitude * .pi / 180))
            let lonDelta = min(1.8, latDelta / cosLat)
            let reg = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            )
            return (reg, r)
        }
        let span = MKCoordinateSpan(
            latitudeDelta: fallbackSpanDegrees,
            longitudeDelta: fallbackSpanDegrees * max(0.9, 1 / max(0.3, cos(coordinate.latitude * .pi / 180)))
        )
        let reg = MKCoordinateRegion(center: coordinate, span: span)
        let approxRadius = (fallbackSpanDegrees * 111_000) / 2
        return (reg, min(approxRadius, 70_000))
    }
}
