import Foundation

struct Review: Identifiable, Codable {
    let id: String
    let userId: String
    let destinationId: String
    let rating: Int
    let comment: String?
    let createdAt: String
    let updatedAt: String
    let userFirstName: String
    let userLastName: String
    
    // Propriétés calculées
    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return createdAt
    }
    
    var ratingStars: String {
        return String(repeating: "★", count: rating) + String(repeating: "☆", count: 5 - rating)
    }
    
    var displayName: String {
        if !userLastName.isEmpty {
            return "\(userFirstName) \(userLastName)"
        } else {
            return userFirstName
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case destinationId = "destination_id"
        case rating
        case comment
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userFirstName = "user_first_name"
        case userLastName = "user_last_name"
    }
}

// Structure pour créer un nouvel avis
struct CreateReviewRequest: Codable {
    let userId: String
    let destinationId: String
    let rating: Int
    let comment: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case destinationId = "destination_id"
        case rating
        case comment
    }
}

// Structure pour mettre à jour un avis
struct UpdateReviewRequest: Codable {
    let rating: Int
    let comment: String?
}

// Structure pour les statistiques d'avis
struct ReviewStats: Codable {
    let averageRating: Double
    let reviewCount: Int
    let ratingDistribution: [String: Int]
    
    enum CodingKeys: String, CodingKey {
        case averageRating = "average_rating"
        case reviewCount = "review_count"
        case ratingDistribution = "rating_distribution"
    }
} 