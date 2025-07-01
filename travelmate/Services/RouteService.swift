import Foundation

struct Address: Identifiable, Codable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let fullAddress: String
}

struct RouteInfo: Codable, Equatable {
    let overview_polyline: OverviewPolyline
    let legs: [RouteLeg]
}

struct OverviewPolyline: Codable, Equatable {
    let points: String
}

struct RouteLeg: Codable, Equatable {
    let distance: Distance
    let duration: Duration
    let steps: [RouteStep]
}

struct RouteStep: Codable, Equatable {
    let polyline: OverviewPolyline
    let distance: Distance
    let duration: Duration
}

struct Distance: Codable, Equatable {
    let text: String
    let value: Int
}

struct Duration: Codable, Equatable {
    let text: String
    let value: Int
}

// Structure temporaire pour parser la réponse du backend
struct BackendActivity: Codable {
    let position: BackendPosition
    let name: String
    let description: String
    let category: [String]
    let rating: Double?
    let place_id: String
}

struct BackendPosition: Codable {
    let lat: Double
    let lng: Double
}

struct BackendRouteResponse: Codable {
    let route: RouteInfo
    let activities: [BackendActivity]
}

struct Activity: Identifiable, Codable, Equatable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let type: String
    let rating: Double?
    let vicinity: String?
    
    // Initialiseur pour convertir depuis BackendActivity
    init(from backendActivity: BackendActivity) {
        self.name = backendActivity.name
        self.latitude = backendActivity.position.lat
        self.longitude = backendActivity.position.lng
        self.type = backendActivity.category.first ?? "unknown"
        self.rating = backendActivity.rating
        self.vicinity = backendActivity.description
    }
}

struct RouteWithActivities: Codable, Equatable {
    let route: RouteInfo
    let activities: [Activity]
}

enum ActivityType: String, CaseIterable, Codable {
    case restaurant = "restaurant"
    case tourist_attraction = "tourist_attraction"
    case gas_station = "gas_station"
    case lodging = "lodging"
    case hospital = "hospital"
    case pharmacy = "pharmacy"
    case bank = "bank"
    case atm = "atm"
    case park = "park"
    case museum = "museum"
    case church = "church"
    case shopping_mall = "shopping_mall"
    case supermarket = "supermarket"
    case cafe = "cafe"
    case bar = "bar"
    
    var displayName: String {
        switch self {
        case .restaurant: return "Restaurants"
        case .tourist_attraction: return "Attractions touristiques"
        case .gas_station: return "Stations-service"
        case .lodging: return "Hébergements"
        case .hospital: return "Hôpitaux"
        case .pharmacy: return "Pharmacies"
        case .bank: return "Banques"
        case .atm: return "Distributeurs"
        case .park: return "Parcs"
        case .museum: return "Musées"
        case .church: return "Églises"
        case .shopping_mall: return "Centres commerciaux"
        case .supermarket: return "Supermarchés"
        case .cafe: return "Cafés"
        case .bar: return "Bars"
        }
    }
}

// Ajout des structures pour parser la réponse Google Maps
struct GoogleMapsResponse: Codable {
    let formatted_address: String
    let geometry: GMapsGeometry
    let place_id: String
}

struct GMapsGeometry: Codable {
    let location: GMapsLocation
}

struct GMapsLocation: Codable {
    let lat: Double
    let lng: Double
}

@MainActor
class RouteService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentRoute: RouteWithActivities?
    
    private let baseURL = "http://172.20.10.4:8000/api"
    
    func searchAddresses(query: String) async -> [Address] {
        guard !query.isEmpty else { return [] }
        
        var components = URLComponents(string: "\(baseURL)/address")!
        components.queryItems = [
            URLQueryItem(name: "address", value: query)
        ]
        
        guard let url = components.url else { 
            print("❌ URL invalide")
            return [] 
        }

        print("🌐 Appel API: \(url.absoluteString)")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Réponse HTTP invalide")
                return []
            }
            
            print("📡 Status code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                print("❌ Erreur HTTP: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Réponse: \(responseString)")
                }
                return []
            }

            print("📄 Données reçues: \(data.count) bytes")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 JSON: \(jsonString)")
            }

            // Parser la réponse Google Maps
            let googleMapsResults = try JSONDecoder().decode([GoogleMapsResponse].self, from: data)
            
            print("✅ Parsing réussi: \(googleMapsResults.count) résultats")
            
            // Convertir en objets Address
            let addresses = googleMapsResults.map { result in
                Address(
                    name: result.formatted_address,
                    latitude: result.geometry.location.lat,
                    longitude: result.geometry.location.lng,
                    fullAddress: result.formatted_address
                )
            }
            
            print("📍 Adresses converties: \(addresses.count)")
            return addresses
            
        } catch {
            print("❌ Erreur lors de la récupération des adresses: \(error)")
            if let decodingError = error as? DecodingError {
                print("🔍 Erreur de décodage: \(decodingError)")
            }
            return []
        }
    }
    
    func getRouteWithActivities(
        startLat: Double,
        startLon: Double,
        endLat: Double,
        endLon: Double,
        activityType: ActivityType
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        currentRoute = nil
        
        print("🌐 Appel API getRouteWithActivities:")
        print("  URL: \(baseURL)/activities-along-route")
        print("  Paramètres: start_lat=\(startLat), start_lon=\(startLon), end_lat=\(endLat), end_lon=\(endLon), activity_type=\(activityType.rawValue)")
        
        do {
            var components = URLComponents(string: "\(baseURL)/activities-along-route")!
            components.queryItems = [
                URLQueryItem(name: "start_lat", value: String(startLat)),
                URLQueryItem(name: "start_lon", value: String(startLon)),
                URLQueryItem(name: "end_lat", value: String(endLat)),
                URLQueryItem(name: "end_lon", value: String(endLon)),
                URLQueryItem(name: "activity_type", value: activityType.rawValue)
            ]
            
            guard let url = components.url else {
                print("❌ URL invalide")
                throw URLError(.badURL)
            }
            
            print("🌐 URL complète: \(url.absoluteString)")
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Réponse HTTP invalide")
                throw URLError(.badServerResponse)
            }
            
            print("📡 Status code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                print("❌ Erreur HTTP: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Réponse d'erreur: \(responseString)")
                }
                throw URLError(.badServerResponse)
            }
            
            print("📄 Données reçues: \(data.count) bytes")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 JSON reçu: \(jsonString)")
            }
            
            // Essayer de parser la réponse
            do {
                let backendResponse = try JSONDecoder().decode(BackendRouteResponse.self, from: data)
                print("✅ Parsing réussi!")
                print("  Route: \(backendResponse.route.legs.count) legs")
                print("  Activités backend: \(backendResponse.activities.count)")
                
                // Convertir les activités backend en activités standard
                let activities = backendResponse.activities.map { Activity(from: $0) }
                print("  Activités converties: \(activities.count)")
                
                // Créer la RouteWithActivities finale
                let routeWithActivities = RouteWithActivities(
                    route: backendResponse.route,
                    activities: activities
                )
                
                self.currentRoute = routeWithActivities
                isLoading = false
                return true
            } catch {
                print("❌ Erreur de parsing JSON: \(error)")
                if let decodingError = error as? DecodingError {
                    print("🔍 Détails de l'erreur de décodage: \(decodingError)")
                }
                
                // Essayer de voir la structure JSON pour debug
                if let jsonObject = try? JSONSerialization.jsonObject(with: data) {
                    print("🔍 Structure JSON reçue: \(jsonObject)")
                }
                
                throw error
            }
            
        } catch {
            isLoading = false
            errorMessage = "Erreur lors de la récupération de l'itinéraire: \(error.localizedDescription)"
            print("❌ Erreur finale: \(errorMessage ?? "Erreur inconnue")")
            return false
        }
    }
    
    func getSimpleRoute(
        startLat: Double,
        startLon: Double,
        endLat: Double,
        endLon: Double
    ) async -> RouteInfo? {
        do {
            var components = URLComponents(string: "\(baseURL)/routes/directions")!
            components.queryItems = [
                URLQueryItem(name: "start_lat", value: String(startLat)),
                URLQueryItem(name: "start_lon", value: String(startLon)),
                URLQueryItem(name: "end_lat", value: String(endLat)),
                URLQueryItem(name: "end_lon", value: String(endLon))
            ]
            
            guard let url = components.url else {
                return nil
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(RouteInfo.self, from: data)
            
        } catch {
            print("Erreur lors de la récupération de l'itinéraire simple: \(error)")
            return nil
        }
    }
} 