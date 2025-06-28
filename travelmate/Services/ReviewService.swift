import Foundation
import Supabase

@MainActor
class ReviewService: ObservableObject {
    @Published var reviews: [Review] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseConfig.client
    
    // MARK: - Récupération des avis
    
    func fetchReviews(for destinationId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabase
                .from("reviews_with_user_info")
                .select()
                .eq("destination_id", value: destinationId)
                .order("created_at", ascending: false)
                .execute()
            
            let data = response.data
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var decodedReviews: [Review] = []
                
                for reviewDict in jsonArray {
                    if let review = try? decodeReview(from: reviewDict) {
                        decodedReviews.append(review)
                    }
                }
                
                self.reviews = decodedReviews
                print("🟢 Avis chargés: \(decodedReviews.count) avis pour la destination \(destinationId)")
            }
            
        } catch {
            errorMessage = "Erreur lors du chargement des avis: \(error.localizedDescription)"
            print("🔴 Erreur Supabase: \(error)")
        }
        
        isLoading = false
    }
    
    func fetchUserReview(for userId: String, destinationId: String) async -> Review? {
        do {
            let response = try await supabase
                .from("reviews_with_user_info")
                .select()
                .eq("user_id", value: userId)
                .eq("destination_id", value: destinationId)
                .single()
                .execute()
            
            let data = response.data
            if let reviewDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let review = try? decodeReview(from: reviewDict) {
                print("🟢 Avis utilisateur trouvé pour la destination \(destinationId)")
                return review
            }
            
        } catch {
            print("🔵 Aucun avis utilisateur trouvé pour la destination \(destinationId)")
        }
        
        return nil
    }
    
    // MARK: - Création d'avis
    
    func createReview(userId: String, destinationId: String, rating: Int, comment: String?) async -> Bool {
        do {
            let reviewRequest = CreateReviewRequest(
                userId: userId,
                destinationId: destinationId,
                rating: rating,
                comment: comment
            )
            
            let response = try await supabase
                .from("reviews")
                .insert(reviewRequest)
                .execute()
            
            print("🟢 Avis créé avec succès pour la destination \(destinationId)")
            
            // Recharger les avis pour mettre à jour l'interface
            await fetchReviews(for: destinationId)
            
            return true
            
        } catch {
            errorMessage = "Erreur lors de la création de l'avis: \(error.localizedDescription)"
            print("🔴 Erreur Supabase: \(error)")
            return false
        }
    }
    
    // MARK: - Mise à jour d'avis
    
    func updateReview(reviewId: String, rating: Int, comment: String?) async -> Bool {
        do {
            let updateRequest = UpdateReviewRequest(rating: rating, comment: comment)
            
            let response = try await supabase
                .from("reviews")
                .update(updateRequest)
                .eq("id", value: reviewId)
                .execute()
            
            print("🟢 Avis mis à jour avec succès")
            
            // Recharger les avis pour mettre à jour l'interface
            if let firstReview = reviews.first {
                await fetchReviews(for: firstReview.destinationId)
            }
            
            return true
            
        } catch {
            errorMessage = "Erreur lors de la mise à jour de l'avis: \(error.localizedDescription)"
            print("🔴 Erreur Supabase: \(error)")
            return false
        }
    }
    
    // MARK: - Suppression d'avis
    
    func deleteReview(reviewId: String) async -> Bool {
        do {
            let response = try await supabase
                .from("reviews")
                .delete()
                .eq("id", value: reviewId)
                .execute()
            
            print("🟢 Avis supprimé avec succès")
            
            // Recharger les avis pour mettre à jour l'interface
            if let firstReview = reviews.first {
                await fetchReviews(for: firstReview.destinationId)
            }
            
            return true
            
        } catch {
            errorMessage = "Erreur lors de la suppression de l'avis: \(error.localizedDescription)"
            print("🔴 Erreur Supabase: \(error)")
            return false
        }
    }
    
    // MARK: - Statistiques
    
    func getAverageRating(for destinationId: String) async -> Double {
        do {
            let response = try await supabase
                .rpc("get_destination_average_rating", params: ["dest_id": destinationId])
                .execute()
            
            let data = response.data
            if let rating = try? JSONSerialization.jsonObject(with: data) as? Double {
                return rating
            }
            
        } catch {
            print("🔴 Erreur lors du calcul de la note moyenne: \(error)")
        }
        
        return 0.0
    }
    
    func getReviewCount(for destinationId: String) async -> Int {
        do {
            let response = try await supabase
                .rpc("get_destination_review_count", params: ["dest_id": destinationId])
                .execute()
            
            let data = response.data
            if let count = try? JSONSerialization.jsonObject(with: data) as? Int {
                return count
            }
            
        } catch {
            print("🔴 Erreur lors du comptage des avis: \(error)")
        }
        
        return 0
    }
    
    func getReviewStats(for destinationId: String) async -> ReviewStats? {
        do {
            let response = try await supabase
                .rpc("get_destination_review_stats", params: ["dest_id": destinationId])
                .execute()
            
            let data = response.data
            if let statsArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let statsDict = statsArray.first {
                
                let averageRating = statsDict["average_rating"] as? Double ?? 0.0
                let reviewCount = statsDict["review_count"] as? Int ?? 0
                let ratingDistribution = statsDict["rating_distribution"] as? [String: Int] ?? [:]
                
                return ReviewStats(
                    averageRating: averageRating,
                    reviewCount: reviewCount,
                    ratingDistribution: ratingDistribution
                )
            }
            
        } catch {
            print("🔴 Erreur lors du calcul des statistiques: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Utilitaires
    
    func hasUserReviewed(userId: String, destinationId: String) async -> Bool {
        let userReview = await fetchUserReview(for: userId, destinationId: destinationId)
        return userReview != nil
    }
    
    private func decodeReview(from dict: [String: Any]) throws -> Review {
        guard let id = dict["id"] as? String,
              let userId = dict["user_id"] as? String,
              let destinationId = dict["destination_id"] as? String,
              let rating = dict["rating"] as? Int,
              let createdAt = dict["created_at"] as? String,
              let updatedAt = dict["updated_at"] as? String else {
            throw NSError(domain: "ReviewService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Données d'avis incomplètes"])
        }
        
        let comment = dict["comment"] as? String
        let userFirstName = dict["user_first_name"] as? String ?? "Utilisateur"
        let userLastName = dict["user_last_name"] as? String ?? ""
        
        return Review(
            id: id,
            userId: userId,
            destinationId: destinationId,
            rating: rating,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt,
            userFirstName: userFirstName,
            userLastName: userLastName
        )
    }
} 