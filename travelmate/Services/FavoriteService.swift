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
        // Vérifier si le favori existe déjà
        if isFavorite(userId: userId, destinationId: destinationId) {
            print("🔵 Favori déjà existant pour destination: \(destinationId)")
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
            
            print("🟢 Favori ajouté avec succès pour destination: \(destinationId)")
            
            // Recharger les favoris
            await fetchFavorites(for: userId)
            
            // Forcer la mise à jour de l'interface
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            
            return true
            
        } catch {
            // Si c'est une erreur de clé dupliquée, on considère que c'est un succès
            if let postgrestError = error as? PostgrestError,
               postgrestError.code == "23505" {
                print("🟡 Favori déjà existant (erreur de contrainte): \(destinationId)")
                // Recharger les favoris pour s'assurer que l'état est cohérent
                await fetchFavorites(for: userId)
                
                // Forcer la mise à jour de l'interface
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
                
                return true
            }
            
            errorMessage = "Erreur lors de l'ajout aux favoris: \(error.localizedDescription)"
            print("🔴 Erreur Supabase: \(error)")
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
            
            print("🟢 Favori supprimé avec succès pour destination: \(destinationId)")
            
            // Recharger les favoris
            await fetchFavorites(for: userId)
            
            // Forcer la mise à jour de l'interface
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            
            return true
            
        } catch {
            errorMessage = "Erreur lors de la suppression des favoris: \(error.localizedDescription)"
            print("🔴 Erreur Supabase: \(error)")
            return false
        }
    }
    
    func isFavorite(userId: String, destinationId: String) -> Bool {
        return favorites.contains { favorite in
            favorite.userId == userId && favorite.destinationId == destinationId
        }
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
            print("🔴 Erreur lors du comptage des favoris: \(error)")
            return 0
        }
    }
    
    func toggleFavorite(userId: String, destinationId: String) async -> Bool {
        // Vérifier d'abord l'état actuel
        let isCurrentlyFavorite = isFavorite(userId: userId, destinationId: destinationId)
        
        if isCurrentlyFavorite {
            // Si c'est déjà un favori, on le supprime
            print("🔵 Suppression du favori pour destination: \(destinationId)")
            let success = await removeFromFavorites(userId: userId, destinationId: destinationId)
            if success {
                // Forcer la mise à jour de l'interface
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
            return success
        } else {
            // Sinon on l'ajoute
            print("🔵 Ajout du favori pour destination: \(destinationId)")
            let success = await addToFavorites(userId: userId, destinationId: destinationId)
            if success {
                // Forcer la mise à jour de l'interface
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
            return success
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