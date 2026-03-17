import Foundation

enum Attractions {
    static let tokyo = CityData(
        city: "Tokyo",
        country: "Japan",
        flag: "🇯🇵",
        photoURL: "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=1200",
        attractions: [
            Attraction(name: "Senso-ji Temple", category: .culture),
            Attraction(name: "Shibuya Crossing", category: .landmark),
            Attraction(name: "Shinjuku Gyoen", category: .nature),
            Attraction(name: "Tsukiji Outer Market", category: .food),
            Attraction(name: "Yanaka Neighbourhood", category: .neighbourhood),
            Attraction(name: "teamLab Planets", category: .experience),
            Attraction(name: "Harajuku & Takeshita Street", category: .neighbourhood),
            Attraction(name: "Tokyo Skytree", category: .landmark),
            Attraction(name: "Depachika Food Halls", category: .food),
            Attraction(name: "General Appeal", category: .general)
        ]
    )

    static let paris = CityData(
        city: "Paris",
        country: "France",
        flag: "🇫🇷",
        photoURL: "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=1200",
        attractions: [
            Attraction(name: "Louvre Museum", category: .culture),
            Attraction(name: "Eiffel Tower", category: .landmark),
            Attraction(name: "Luxembourg Gardens", category: .nature),
            Attraction(name: "Marché des Enfants Rouges", category: .food),
            Attraction(name: "Le Marais", category: .neighbourhood),
            Attraction(name: "Seine River Cruise", category: .experience),
            Attraction(name: "Montmartre", category: .neighbourhood),
            Attraction(name: "Arc de Triomphe", category: .landmark),
            Attraction(name: "Parisian Cafés", category: .food),
            Attraction(name: "General Appeal", category: .general)
        ]
    )

    static let lisbon = CityData(
        city: "Lisbon",
        country: "Portugal",
        flag: "🇵🇹",
        photoURL: "https://images.unsplash.com/photo-1585208798174-6cedd86e019a?w=1200",
        attractions: [
            Attraction(name: "Museu Calouste Gulbenkian", category: .culture),
            Attraction(name: "Belém Tower", category: .landmark),
            Attraction(name: "Estufa Fria", category: .nature),
            Attraction(name: "Time Out Market", category: .food),
            Attraction(name: "Alfama", category: .neighbourhood),
            Attraction(name: "Tram 28", category: .experience),
            Attraction(name: "Bairro Alto", category: .neighbourhood),
            Attraction(name: "Miradouro da Senhora do Monte", category: .landmark),
            Attraction(name: "Pastéis de Belém", category: .food),
            Attraction(name: "General Appeal", category: .general)
        ]
    )

    static let newYork = CityData(
        city: "New York",
        country: "USA",
        flag: "🇺🇸",
        photoURL: "https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=1200",
        attractions: [
            Attraction(name: "MET Museum", category: .culture),
            Attraction(name: "Statue of Liberty", category: .landmark),
            Attraction(name: "Central Park", category: .nature),
            Attraction(name: "Chelsea Market", category: .food),
            Attraction(name: "West Village", category: .neighbourhood),
            Attraction(name: "Broadway Show", category: .experience),
            Attraction(name: "Brooklyn Bridge & DUMBO", category: .neighbourhood),
            Attraction(name: "Top of the Rock", category: .landmark),
            Attraction(name: "Pizza & Bagels", category: .food),
            Attraction(name: "General Appeal", category: .general)
        ]
    )

    static let bali = CityData(
        city: "Bali",
        country: "Indonesia",
        flag: "🇮🇩",
        photoURL: "https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=1200",
        attractions: [
            Attraction(name: "Ubud Art & Rice Terraces", category: .culture),
            Attraction(name: "Tanah Lot", category: .landmark),
            Attraction(name: "Tegallalang Rice Terraces", category: .nature),
            Attraction(name: "Ubud Market", category: .food),
            Attraction(name: "Canggu", category: .neighbourhood),
            Attraction(name: "Balinese Cooking Class", category: .experience),
            Attraction(name: "Seminyak", category: .neighbourhood),
            Attraction(name: "Uluwatu Temple", category: .landmark),
            Attraction(name: "Warungs (Local Eateries)", category: .food),
            Attraction(name: "General Appeal", category: .general)
        ]
    )

    static let kyoto = CityData(
        city: "Kyoto",
        country: "Japan",
        flag: "🇯🇵",
        photoURL: "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=1200",
        attractions: [
            Attraction(name: "Fushimi Inari Taisha", category: .culture),
            Attraction(name: "Kinkaku-ji", category: .landmark),
            Attraction(name: "Arashiyama Bamboo Grove", category: .nature),
            Attraction(name: "Nishiki Market", category: .food),
            Attraction(name: "Gion", category: .neighbourhood),
            Attraction(name: "Tea Ceremony", category: .experience),
            Attraction(name: "Higashiyama", category: .neighbourhood),
            Attraction(name: "Kiyomizu-dera", category: .landmark),
            Attraction(name: "Kaiseki Dining", category: .food),
            Attraction(name: "General Appeal", category: .general)
        ]
    )

    static let marrakech = CityData(
        city: "Marrakech",
        country: "Morocco",
        flag: "🇲🇦",
        photoURL: "https://images.unsplash.com/photo-1489749798305-4fea3ae63d43?w=1200",
        attractions: [
            Attraction(name: "Bahia Palace", category: .culture),
            Attraction(name: "Koutoubia Mosque", category: .landmark),
            Attraction(name: "Majorelle Garden", category: .nature),
            Attraction(name: "Jemaa el-Fnaa Food Stalls", category: .food),
            Attraction(name: "Medina Souks", category: .neighbourhood),
            Attraction(name: "Hammam Experience", category: .experience),
            Attraction(name: "Kasbah", category: .neighbourhood),
            Attraction(name: "Saadian Tombs", category: .landmark),
            Attraction(name: "Moroccan Tagine", category: .food),
            Attraction(name: "General Appeal", category: .general)
        ]
    )

    static let newOrleans = CityData(
        city: "New Orleans",
        country: "USA",
        flag: "🇺🇸",
        photoURL: "https://images.unsplash.com/photo-1605649487212-47bdab064df7?w=1200",
        attractions: [
            Attraction(name: "New Orleans Museum of Art", category: .culture),
            Attraction(name: "Jackson Square", category: .landmark),
            Attraction(name: "City Park", category: .nature),
            Attraction(name: "French Market", category: .food),
            Attraction(name: "French Quarter", category: .neighbourhood),
            Attraction(name: "Live Jazz", category: .experience),
            Attraction(name: "Garden District", category: .neighbourhood),
            Attraction(name: "St. Louis Cathedral", category: .landmark),
            Attraction(name: "Beignets & Po'boys", category: .food),
            Attraction(name: "General Appeal", category: .general)
        ]
    )

    static var allCities: [CityData] {
        [tokyo, paris, lisbon, newYork, bali, kyoto, marrakech, newOrleans]
    }

    /// Build a generic template for any city in the world so the user can rate it,
    /// even if we don't have hand-crafted attractions.
    static func templateCity(city: String, country: String) -> CityData {
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCountry = country.trimmingCharacters(in: .whitespacesAndNewlines)
        let queryBase = trimmedCity.isEmpty ? "city" : trimmedCity
        let encoded = queryBase.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "city"
        let photoURL = "https://source.unsplash.com/featured/?\(encoded),travel"

        let displayCity = trimmedCity.isEmpty ? "Unknown city" : trimmedCity
        let displayCountry = trimmedCountry.isEmpty ? "Unknown" : trimmedCountry

        let namePrefix = trimmedCity.isEmpty ? "City" : trimmedCity

        let attractions: [Attraction] = [
            Attraction(name: "\(namePrefix) historic center", category: .neighbourhood),
            Attraction(name: "\(namePrefix) food & markets", category: .food),
            Attraction(name: "\(namePrefix) museums & culture", category: .culture),
            Attraction(name: "\(namePrefix) parks & nature", category: .nature),
            Attraction(name: "\(namePrefix) viewpoints & skyline", category: .landmark),
            Attraction(name: "\(namePrefix) neighbourhood walks", category: .neighbourhood),
            Attraction(name: "\(namePrefix) experiences & nightlife", category: .experience),
            Attraction(name: "Local everyday life in \(namePrefix)", category: .neighbourhood),
            Attraction(name: "General Appeal", category: .general)
        ]

        return CityData(
            city: displayCity,
            country: displayCountry,
            flag: "",
            photoURL: photoURL,
            attractions: attractions
        )
    }
}

