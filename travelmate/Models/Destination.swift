import Foundation

struct Destination: Identifiable, Codable {
    let id: String
    let title: String
    let type: String
    let location: String
    let notes: String?
    let lat: Double
    let long: Double
    let categoryId: String?
    let imagePath: String?
    
    // Propriétés calculées pour la compatibilité avec l'interface existante
    var name: String { title }
    var description: String { notes ?? "" }
    var imageURL: String { 
        if let imagePath = imagePath, !imagePath.isEmpty {
            return "https://etzdkvwucgaznmolqdyj.supabase.co/storage/v1/object/public/products/\(imagePath)"
        }
        return ""
    }
    var climate: String { "Tempéré" } // Valeur par défaut
    var culture: String { "Locale" } // Valeur par défaut
    var activities: [Activity] { [] } // À adapter selon vos besoins
    var priceRange: PriceRange { .moderate } // Valeur par défaut
    var rating: Double { 4.5 } // Valeur par défaut
    
    struct Location: Codable {
        let latitude: Double
        let longitude: Double
        let country: String
        let city: String
        
        init(latitude: Double, longitude: Double, country: String = "", city: String = "") {
            self.latitude = latitude
            self.longitude = longitude
            self.country = country
            self.city = city
        }
    }
    
    struct Activity: Identifiable, Codable {
        let id: UUID
        let name: String
        let description: String
        let price: Double
        let duration: String
        let imageURL: String
    }
    
    enum PriceRange: String, Codable {
        case budget = "Budget"
        case moderate = "Modéré"
        case luxury = "Luxe"
    }
    
    // CodingKeys pour mapper les champs Supabase
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case type
        case location
        case notes
        case lat
        case long
        case categoryId = "category_id"
        case imagePath = "image_path"
    }
    
    // Propriété calculée pour la compatibilité avec l'interface existante
    var coordinateLocation: Location {
        Location(latitude: lat, longitude: long, country: location, city: title)
    }
} 