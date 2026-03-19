import CoreLocation
import Foundation
import MapKit

/// Maps-style city search: debounced `MKLocalSearchCompleter` suggestions + resolving a pick to city/country.
final class CitySearchCompleterService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published private(set) var suggestions: [MKLocalSearchCompletion] = []
    @Published private(set) var completerIsLoading = false

    private let completer = MKLocalSearchCompleter()
    private var debounceTask: Task<Void, Never>?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address]
        completer.pointOfInterestFilter = .excludingAll
        completer.region = Self.worldRegion
    }

    private static var worldRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 140, longitudeDelta: 360)
        )
    }

    /// Optional: bias completions toward a map region (e.g. visible map / user location).
    func setSearchRegion(_ region: MKCoordinateRegion) {
        completer.region = region
    }

    func reset() {
        debounceTask?.cancel()
        debounceTask = nil
        completer.queryFragment = ""
        suggestions = []
        completerIsLoading = false
    }

    func updateQueryFragment(_ text: String) {
        debounceTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            suggestions = []
            completer.queryFragment = ""
            completerIsLoading = false
            return
        }
        completerIsLoading = true
        debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 240_000_000)
            guard !Task.isCancelled else { return }
            completer.queryFragment = trimmed
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.suggestions = completer.results
            self.completerIsLoading = false
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.suggestions = []
            self.completerIsLoading = false
        }
    }

    // MARK: - Resolve like Apple Maps (completion → map item)

    static func resolveCompletion(
        _ completion: MKLocalSearchCompletion,
        completionHandler: @escaping (ResolvedCityPlace?) -> Void
    ) {
        let request = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: request).start { response, _ in
            DispatchQueue.main.async {
                guard let item = response?.mapItems.first else {
                    completionHandler(nil)
                    return
                }
                completionHandler(ResolvedCityPlace(mapItem: item))
            }
        }
    }

    /// Full query search when the user hits the keyboard “Search” button.
    static func searchPlaces(query: String, completionHandler: @escaping ([ResolvedCityPlace]) -> Void) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            completionHandler([])
            return
        }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = q
        request.region = Self.worldRegion
        MKLocalSearch(request: request).start { response, _ in
            DispatchQueue.main.async {
                guard let items = response?.mapItems else {
                    completionHandler([])
                    return
                }
                var seen = Set<String>()
                var out: [ResolvedCityPlace] = []
                for item in items {
                    guard let place = ResolvedCityPlace(mapItem: item) else { continue }
                    let key = "\(place.city)|\(place.country)"
                    guard !seen.contains(key) else { continue }
                    seen.insert(key)
                    out.append(place)
                    if out.count >= 20 { break }
                }
                completionHandler(out)
            }
        }
    }
}

/// A resolved place suitable for `Attractions.templateCity`.
struct ResolvedCityPlace: Hashable {
    let city: String
    let country: String
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: ResolvedCityPlace, rhs: ResolvedCityPlace) -> Bool {
        lhs.city == rhs.city && lhs.country == rhs.country
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(city)
        hasher.combine(country)
    }

    init?(mapItem: MKMapItem) {
        let p = mapItem.placemark
        let locality = p.locality?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let admin = p.administrativeArea?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = p.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let subAdmin = p.subAdministrativeArea?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let rawCountry = (p.country ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let country: String
        if !rawCountry.isEmpty {
            country = rawCountry
        } else if let code = p.isoCountryCode {
            country = Locale.current.localizedString(forRegionCode: code) ?? code
        } else {
            country = ""
        }

        let city: String
        if !locality.isEmpty {
            city = locality
        } else if !admin.isEmpty {
            city = admin
        } else if !subAdmin.isEmpty {
            city = subAdmin
        } else if !name.isEmpty {
            city = name
        } else {
            return nil
        }

        self.city = city
        self.country = country
        self.coordinate = p.coordinate
    }
}
