import Foundation

struct Destination: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let type: String
    let location: String
    let notes: String?
    let lat: Double
    let long: Double
    let categoryId: String?
    let imagePaths: [String]?
    let price: Double?
    let promo: Double?
    
    // Implémentation de Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Destination, rhs: Destination) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Propriétés calculées pour la compatibilité avec l'interface existante
    var name: String { title }
    var description: String { notes ?? "" }
    
    // Propriété pour la compatibilité avec l'ancien système (première image)
    var imageURL: String { 
        if let imagePaths = imagePaths, !imagePaths.isEmpty, !imagePaths[0].isEmpty {
            return "https://etzdkvwucgaznmolqdyj.supabase.co/storage/v1/object/public/products/\(imagePaths[0])"
        }
        return ""
    }
    
    // Propriété pour obtenir toutes les URLs d'images
    var imageURLs: [String] {
        guard let imagePaths = imagePaths else { return [] }
        return imagePaths.compactMap { path in
            if !path.isEmpty {
                return "https://etzdkvwucgaznmolqdyj.supabase.co/storage/v1/object/public/products/\(path)"
            }
            return nil
        }
    }
    
    var climate: String { "Tempéré" } // Valeur par défaut
    var culture: String { "Locale" } // Valeur par défaut
    var activities: [Activity] { [] } // À adapter selon vos besoins
    var priceRange: PriceRange { 
        guard let price = price else { return .moderate }
        switch price {
        case 0..<500: return .budget
        case 500..<1500: return .moderate
        default: return .luxury
        }
    }
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
        case imagePaths = "image_path"
        case price
        case promo
    }
    
    // Propriété calculée pour la compatibilité avec l'interface existante
    var coordinateLocation: Location {
        Location(latitude: lat, longitude: long, country: location, city: title)
    }
} 
