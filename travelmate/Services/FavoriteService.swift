import Foundation
import Supabase

@MainActor
class FavoriteService: ObservableObject {
    @Published var favorites: [Favorite] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseConfig.client
    
    func fetchFavorites(for userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabase
                .from("favorites")
                .select()
                .eq("user_id", value: userId)
                .execute()
            
            let data = response.data
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var decodedFavorites: [Favorite] = []
                
                for favoriteDict in jsonArray {
                    if let favorite = try? decodeFavorite(from: favoriteDict) {
                        decodedFavorites.append(favorite)
                    }
                }
                
                self.favorites = decodedFavorites
            }
            
        } catch {
            errorMessage = "Erreur lors du chargement des favoris: \(error.localizedDescription)"
            print("Erreur Supabase: \(error)")
        }
        
        isLoading = false
    }
    
    func addToFavorites(userId: String, destinationId: String) async -> Bool {
        do {
            let response = try await supabase
                .from("favorites")
                .insert([
                    "user_id": userId,
                    "destination_id": destinationId
                ])
                .execute()
            
            // Recharger les favoris
            await fetchFavorites(for: userId)
            return true
            
        } catch {
            errorMessage = "Erreur lors de l'ajout aux favoris: \(error.localizedDescription)"
            print("Erreur Supabase: \(error)")
            return false
        }
    }
    
    func removeFromFavorites(userId: String, destinationId: String) async -> Bool {
        do {
            let response = try await supabase
                .from("favorites")
                .delete()
                .eq("user_id", value: userId)
                .eq("destination_id", value: destinationId)
                .execute()
            
            // Recharger les favoris
            await fetchFavorites(for: userId)
            return true
            
        } catch {
            errorMessage = "Erreur lors de la suppression des favoris: \(error.localizedDescription)"
            print("Erreur Supabase: \(error)")
            return false
        }
    }
    
    func isFavorite(userId: String, destinationId: String) -> Bool {
        return favorites.contains { favorite in
            favorite.userId == userId && favorite.destinationId == destinationId
        }
    }
    
    private func decodeFavorite(from dict: [String: Any]) throws -> Favorite {
        guard let id = dict["id"] as? String,
              let userId = dict["user_id"] as? String,
              let destinationId = dict["destination_id"] as? String,
              let createdAt = dict["created_at"] as? String else {
            throw NSError(domain: "FavoriteService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Données de favori incomplètes"])
        }
        
        return Favorite(
            id: id,
            userId: userId,
            destinationId: destinationId,
            createdAt: createdAt
        )
    }
} 