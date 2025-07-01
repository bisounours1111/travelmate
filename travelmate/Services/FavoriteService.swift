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

                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
            
        } catch {
            errorMessage = "Erreur lors du chargement des favoris: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func addToFavorites(userId: String, destinationId: String) async -> Bool {
        // Normaliser les IDs pour la vérification
        let normalizedUserId = userId.lowercased()
        let normalizedDestinationId = destinationId.lowercased()
        
        // Vérifier si le favori existe déjà
        if isFavorite(userId: normalizedUserId, destinationId: normalizedDestinationId) {
            return true
        }
        
        do {
            let response = try await supabase
                .from("favorites")
                .insert([
                    "user_id": userId,
                    "destination_id": destinationId
                ])
                .execute()
            
            
            // Ajouter le favori localement pour une mise à jour immédiate
            let newFavorite = Favorite(
                id: UUID().uuidString, // ID temporaire
                userId: userId,
                destinationId: destinationId,
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
            
            DispatchQueue.main.async {
                self.favorites.append(newFavorite)
                self.objectWillChange.send()
            }
            
            await fetchFavorites(for: userId)
            
            return true
            
        } catch {
            if let postgrestError = error as? PostgrestError,
               postgrestError.code == "23505" {
                await fetchFavorites(for: userId)
                return true
            }
            
            errorMessage = "Erreur lors de l'ajout aux favoris: \(error.localizedDescription)"
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
            
            let normalizedUserId = userId.lowercased()
            let normalizedDestinationId = destinationId.lowercased()
            
            // Supprimer le favori localement pour une mise à jour immédiate
            DispatchQueue.main.async {
                self.favorites.removeAll { favorite in
                    favorite.userId.lowercased() == normalizedUserId && 
                    favorite.destinationId.lowercased() == normalizedDestinationId
                }
                self.objectWillChange.send()
            }
            
            // Recharger les favoris depuis la base de données
            await fetchFavorites(for: userId)
            
            return true
            
        } catch {
            errorMessage = "Erreur lors de la suppression des favoris: \(error.localizedDescription)"
            return false
        }
    }
    
    func isFavorite(userId: String, destinationId: String) -> Bool {
        let normalizedUserId = userId.lowercased()
        let normalizedDestinationId = destinationId.lowercased()
        
        let isFav = favorites.contains { favorite in
            let userMatch = favorite.userId.lowercased() == normalizedUserId
            let destinationMatch = favorite.destinationId.lowercased() == normalizedDestinationId
            return userMatch && destinationMatch
        }
        return isFav
    }
    
    func getFavoriteCount(for destinationId: String) async -> Int {
        do {
            let response = try await supabase
                .from("favorites")
                .select("id", count: .exact)
                .eq("destination_id", value: destinationId)
                .execute()
            
            return response.count ?? 0
            
        } catch {
            return 0
        }
    }
    
    func toggleFavorite(userId: String, destinationId: String) async -> Bool {
        let isCurrentlyFavorite = isFavorite(userId: userId, destinationId: destinationId)
        
        if isCurrentlyFavorite {
            let success = await removeFromFavorites(userId: userId, destinationId: destinationId)
            return success
        } else {
            let success = await addToFavorites(userId: userId, destinationId: destinationId)
            return success
        }
    }
    
    func forceRefreshFavorites(for userId: String) async {
        await fetchFavorites(for: userId)
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
