import Foundation

struct AuthUser: Codable {
    let id: String
    let email: String?
    let createdAt: String?
    let updatedAt: String?
    let firstName: String?
    let lastName: String?
    let age: Int?
    let preferences: [String]?
    let role: String?

    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case firstName
        case lastName
        case age
        case preferences
        case role
    }
}
