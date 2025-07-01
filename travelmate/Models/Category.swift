import Foundation

struct Category: Identifiable, Codable {
    let id: String
    let name: String
    let imagePath: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case imagePath = "image_path"
    }
    
    // Propriété calculée pour l'icône SF Symbol basée sur le nom
    var systemIcon: String {
        switch name.lowercased() {
        case let name where name.contains("plage"):
            return "beach.umbrella"
        case let name where name.contains("montagne"):
            return "mountain.2"
        case let name where name.contains("ville"):
            return "building.2"
        case let name where name.contains("culture"):
            return "building.columns"
        case let name where name.contains("nature"):
            return "leaf"
        case let name where name.contains("aventure"):
            return "figure.hiking"
        case let name where name.contains("relax"):
            return "sparkles"
        case let name where name.contains("gastronomie"):
            return "fork.knife"
        case let name where name.contains("sport"):
            return "sportscourt"
        default:
            return "tag"
        }
    }
    
    // Propriété calculée pour la couleur basée sur le nom
    var categoryColor: String {
        switch name.lowercased() {
        case let name where name.contains("plage"):
            return "blue"
        case let name where name.contains("montagne"):
            return "green"
        case let name where name.contains("ville"):
            return "purple"
        case let name where name.contains("culture"):
            return "orange"
        case let name where name.contains("nature"):
            return "green"
        case let name where name.contains("aventure"):
            return "red"
        case let name where name.contains("relax"):
            return "pink"
        case let name where name.contains("gastronomie"):
            return "brown"
        case let name where name.contains("sport"):
            return "yellow"
        default:
            return "blue"
        }
    }
} 