import Foundation

struct Favorite: Identifiable, Codable {
    let id: String
    let userId: String
    let destinationId: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case destinationId = "destination_id"
        case createdAt = "created_at"
    }
} 