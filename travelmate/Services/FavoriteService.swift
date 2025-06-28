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
                
                print("🔍 Données brutes reçues de Supabase:")
                for (index, favoriteDict) in jsonArray.enumerated() {
                    print("  Favori \(index + 1): \(favoriteDict)")
                }
                
                for favoriteDict in jsonArray {
                    if let favorite = try? decodeFavorite(from: favoriteDict) {
                        decodedFavorites.append(favorite)
                        print("✅ Favori décodé: UserID=\(favorite.userId), DestinationID=\(favorite.destinationId)")
                    }
                }
                
                self.favorites = decodedFavorites
                print("🟢 Favoris chargés: \(decodedFavorites.count) favoris pour l'utilisateur \(userId)")
                
                // Afficher tous les favoris stockés
                print("📋 Liste complète des favoris en mémoire:")
                for (index, favorite) in self.favorites.enumerated() {
                    print("  \(index + 1). UserID: \(favorite.userId), DestinationID: \(favorite.destinationId)")
                }
                
                // Forcer la mise à jour de l'interface
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
            
        } catch {
            errorMessage = "Erreur lors du chargement des favoris: \(error.localizedDescription)"
            print("🔴 Erreur Supabase: \(error)")
        }
        
        isLoading = false
    }
    
    func addToFavorites(userId: String, destinationId: String) async -> Bool {
        // Normaliser les IDs pour la vérification
        let normalizedUserId = userId.lowercased()
        let normalizedDestinationId = destinationId.lowercased()
        
        // Vérifier si le favori existe déjà
        if isFavorite(userId: normalizedUserId, destinationId: normalizedDestinationId) {
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
            
            // Recharger les favoris depuis la base de données
            await fetchFavorites(for: userId)
            
            return true
            
        } catch {
            // Si c'est une erreur de clé dupliquée, on considère que c'est un succès
            if let postgrestError = error as? PostgrestError,
               postgrestError.code == "23505" {
                print("🟡 Favori déjà existant (erreur de contrainte): \(destinationId)")
                // Recharger les favoris pour s'assurer que l'état est cohérent
                await fetchFavorites(for: userId)
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
            
            // Normaliser les IDs pour la suppression locale
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
            print("🔴 Erreur Supabase: \(error)")
            return false
        }
    }
    
    func isFavorite(userId: String, destinationId: String) -> Bool {
        print("🔍 Vérification favori détaillée:")
        print("  - UserID recherché: \(userId)")
        print("  - DestinationID recherché: \(destinationId)")
        print("  - Nombre total de favoris en mémoire: \(favorites.count)")
        
        // Normaliser les IDs en minuscules pour la comparaison
        let normalizedUserId = userId.lowercased()
        let normalizedDestinationId = destinationId.lowercased()
        
        let isFav = favorites.contains { favorite in
            let userMatch = favorite.userId.lowercased() == normalizedUserId
            let destinationMatch = favorite.destinationId.lowercased() == normalizedDestinationId
            print("  - Comparaison: UserID=\(favorite.userId) (\(userMatch)), DestinationID=\(favorite.destinationId) (\(destinationMatch))")
            return userMatch && destinationMatch
        }
        
        print("🔍 Résultat final - Est favori: \(isFav)")
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
            print("🔴 Erreur lors du comptage des favoris: \(error)")
            return 0
        }
    }
    
    func toggleFavorite(userId: String, destinationId: String) async -> Bool {
        // Vérifier d'abord l'état actuel
        print("🔵 Début toggleFavorite - User: \(userId), Destination: \(destinationId)")
        let isCurrentlyFavorite = isFavorite(userId: userId, destinationId: destinationId)
        print("🔍 État actuel - User: \(userId), Destination: \(destinationId), Est favori: \(isCurrentlyFavorite)")
        
        if isCurrentlyFavorite {
            // Si c'est déjà un favori, on le supprime
            print("🔵 Suppression du favori pour destination: \(destinationId)")
            let success = await removeFromFavorites(userId: userId, destinationId: destinationId)
            return success
        } else {
            // Sinon on l'ajoute
            print("🔵 Ajout du favori pour destination: \(destinationId)")
            let success = await addToFavorites(userId: userId, destinationId: destinationId)
            return success
        }
    }
    
    func forceRefreshFavorites(for userId: String) async {
        print("🔄 Force refresh des favoris pour l'utilisateur: \(userId)")
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
