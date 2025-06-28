import Foundation

struct Reservation: Identifiable, Codable {
    let id: String
    let userId: String
    let destinationId: String
    let startDate: String
    let endDate: String
    let numberOfPeople: Int
    let totalPrice: Double
    let status: ReservationStatus
    let stripePaymentIntentId: String?
    let createdAt: String
    
    enum ReservationStatus: String, Codable {
        case pending = "pending"
        case confirmed = "confirmed"
        case cancelled = "cancelled"
        case completed = "completed"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case destinationId = "destination_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case numberOfPeople = "number_of_people"
        case totalPrice = "total_price"
        case status
        case stripePaymentIntentId = "stripe_payment_intent_id"
        case createdAt = "created_at"
    }
} 