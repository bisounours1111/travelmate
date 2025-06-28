import Foundation
import Supabase

// Structure pour les données de réservation à insérer
struct ReservationInsertData: Encodable {
    let user_id: String
    let destination_id: String
    let start_date: String
    let end_date: String
    let number_of_people: Int
    let total_price: Double
    let status: String
}

// Structure pour les données de mise à jour
struct ReservationUpdateData: Encodable {
    let status: String
    let stripe_payment_intent_id: String?
}

@MainActor
class ReservationService: ObservableObject {
    @Published var reservations: [Reservation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseConfig.client
    
    func fetchReservations(for userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabase
                .from("reservations")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
            
            let data = response.data
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var decodedReservations: [Reservation] = []
                
                for reservationDict in jsonArray {
                    if let reservation = try? decodeReservation(from: reservationDict) {
                        decodedReservations.append(reservation)
                    }
                }
                
                self.reservations = decodedReservations
            }
            
        } catch {
            errorMessage = "Erreur lors du chargement des réservations: \(error.localizedDescription)"
            print("Erreur Supabase: \(error)")
        }
        
        isLoading = false
    }
    
    func createReservation(
        userId: String,
        destinationId: String,
        startDate: Date,
        endDate: Date,
        numberOfPeople: Int,
        totalPrice: Double
    ) async -> (success: Bool, reservationId: String?, paymentIntentId: String?) {
        do {
            let dateFormatter = ISO8601DateFormatter()
            
            let reservationData = ReservationInsertData(
                user_id: userId,
                destination_id: destinationId,
                start_date: dateFormatter.string(from: startDate),
                end_date: dateFormatter.string(from: endDate),
                number_of_people: numberOfPeople,
                total_price: totalPrice,
                status: "pending"
            )
            
            let response = try await supabase
                .from("reservations")
                .insert(reservationData)
                .execute()
            
            // Extraire l'ID de la réservation créée
            let reservationId = extractReservationId(from: response)
            
            // Créer le Payment Intent Stripe
            let paymentIntentResponse = try await createStripePaymentIntent(amount: Int(totalPrice * 100))
            
            if let paymentIntentId = paymentIntentResponse["id"] as? String {
                // Mettre à jour la réservation avec l'ID du Payment Intent
                if let reservationId = reservationId {
                    try await updateReservationPaymentIntent(reservationId: reservationId, paymentIntentId: paymentIntentId)
                }
                
                // Recharger les réservations
                await fetchReservations(for: userId)
                return (true, reservationId, paymentIntentId)
            }
            
            return (false, reservationId, nil)
            
        } catch {
            errorMessage = "Erreur lors de la création de la réservation: \(error.localizedDescription)"
            print("Erreur Supabase: \(error)")
            return (false, nil, nil)
        }
    }
    
    func confirmReservation(reservationId: String, paymentIntentId: String) async -> Bool {
        do {
            let updateData = ReservationUpdateData(
                status: "confirmed",
                stripe_payment_intent_id: paymentIntentId
            )
            
            let response = try await supabase
                .from("reservations")
                .update(updateData)
                .eq("id", value: reservationId)
                .execute()
            
            // Recharger les réservations
            if let userId = getCurrentUserId() {
                await fetchReservations(for: userId)
            }
            
            return true
            
        } catch {
            errorMessage = "Erreur lors de la confirmation de la réservation: \(error.localizedDescription)"
            print("Erreur Supabase: \(error)")
            return false
        }
    }
    
    func cancelReservation(reservationId: String) async -> Bool {
        do {
            let updateData = ReservationUpdateData(
                status: "cancelled",
                stripe_payment_intent_id: nil
            )
            
            let response = try await supabase
                .from("reservations")
                .update(updateData)
                .eq("id", value: reservationId)
                .execute()
            
            // Recharger les réservations
            if let userId = getCurrentUserId() {
                await fetchReservations(for: userId)
            }
            
            return true
            
        } catch {
            errorMessage = "Erreur lors de l'annulation de la réservation: \(error.localizedDescription)"
            print("Erreur Supabase: \(error)")
            return false
        }
    }
    
    func getReservation(by id: String) async -> Reservation? {
        do {
            let response = try await supabase
                .from("reservations")
                .select()
                .eq("id", value: id)
                .single()
                .execute()
            
            let data = response.data
            if let reservationDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let reservation = try? decodeReservation(from: reservationDict) {
                return reservation
            }
            
        } catch {
            print("Erreur lors de la récupération de la réservation: \(error)")
        }
        
        return nil
    }
    
    private func createStripePaymentIntent(amount: Int) async throws -> [String: Any] {
        // Cette fonction devrait appeler votre backend pour créer un Payment Intent Stripe
        // Pour l'instant, on simule la réponse
        return [
            "id": "pi_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))",
            "client_secret": "pi_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))_secret_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        ]
    }
    
    private func updateReservationPaymentIntent(reservationId: String, paymentIntentId: String) async throws {
        let updateData = ReservationUpdateData(
            status: "pending",
            stripe_payment_intent_id: paymentIntentId
        )
        
        try await supabase
            .from("reservations")
            .update(updateData)
            .eq("id", value: reservationId)
            .execute()
    }
    
    private func extractReservationId(from response: PostgrestResponse<()>) -> String? {
        // Extraire l'ID de la réservation créée depuis la réponse
        // Cette logique dépend de la structure de réponse de Supabase
        // Pour l'instant, on retourne nil
        return nil
    }
    
    private func getCurrentUserId() -> String? {
        // Récupérer l'ID de l'utilisateur connecté
        // Cette logique dépend de votre système d'authentification
        return nil
    }
    
    private func decodeReservation(from dict: [String: Any]) throws -> Reservation {
        guard let id = dict["id"] as? String,
              let userId = dict["user_id"] as? String,
              let destinationId = dict["destination_id"] as? String,
              let startDate = dict["start_date"] as? String,
              let endDate = dict["end_date"] as? String,
              let numberOfPeople = dict["number_of_people"] as? Int,
              let totalPrice = dict["total_price"] as? Double,
              let statusString = dict["status"] as? String,
              let status = Reservation.ReservationStatus(rawValue: statusString),
              let createdAt = dict["created_at"] as? String else {
            throw NSError(domain: "ReservationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Données de réservation incomplètes"])
        }
        
        let stripePaymentIntentId = dict["stripe_payment_intent_id"] as? String
        
        return Reservation(
            id: id,
            userId: userId,
            destinationId: destinationId,
            startDate: startDate,
            endDate: endDate,
            numberOfPeople: numberOfPeople,
            totalPrice: totalPrice,
            status: status,
            stripePaymentIntentId: stripePaymentIntentId,
            createdAt: createdAt
        )
    }
} 