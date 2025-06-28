import Foundation
import Supabase

@MainActor
class DestinationService: ObservableObject {
    @Published var destinations: [Destination] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseConfig.client
    
    init() {
        Task {
            await fetchDestinations()
        }
    }
    
    func fetchDestinations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabase
                .from("destinations")
                .select()
                .execute()
            
            // Les données sont au format Data, il faut d'abord les décoder en JSON
            let data = response.data
            
            // Décodage des données Data en JSON
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                print("Destinations récupérées: \(jsonArray.count)")
                var decodedDestinations: [Destination] = []
                
                for destinationDict in jsonArray {
                    if let destination = try? decodeDestination(from: destinationDict) {
                        decodedDestinations.append(destination)
                    }
                }
                
                self.destinations = decodedDestinations
                print("Destinations décodées avec succès: \(decodedDestinations.count)")
            } else {
                throw NSError(domain: "DestinationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Impossible de décoder les données JSON"])
            }
            
        } catch {
            errorMessage = "Erreur lors du chargement des destinations: \(error.localizedDescription)"
            print("Erreur Supabase: \(error)")
        }
        
        isLoading = false
    }
    
    private func decodeDestination(from dict: [String: Any]) throws -> Destination {
        guard let id = dict["id"] as? String,
              let title = dict["title"] as? String,
              let type = dict["type"] as? String,
              let location = dict["location"] as? String,
              let lat = dict["lat"] as? Double,
              let lng = dict["lng"] as? Double else {
            throw NSError(domain: "DestinationService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Données de destination incomplètes"])
        }
        
        let notes = dict["notes"] as? String
        let categoryId = dict["category_id"] as? String
        let imagePath = dict["image_path"] as? String
        
        return Destination(
            id: id,
            title: title,
            type: type,
            location: location,
            notes: notes,
            lat: lat,
            long: lng,
            categoryId: categoryId,
            imagePath: imagePath
        )
    }
    
    func fetchDestination(by id: String) async -> Destination? {
        do {
            let response = try await supabase
                .from("destinations")
                .select()
                .eq("id", value: id)
                .single()
                .execute()
            
            let data = response.data
            if let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return try decodeDestination(from: jsonDict)
            }
            
        } catch {
            print("Erreur lors de la récupération de la destination: \(error)")
        }
        
        return nil
    }
    
    func searchDestinations(query: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabase
                .from("destinations")
                .select()
                .ilike("title", value: "%\(query)%")
                .execute()
            
            let data = response.data
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var decodedDestinations: [Destination] = []
                
                for destinationDict in jsonArray {
                    if let destination = try? decodeDestination(from: destinationDict) {
                        decodedDestinations.append(destination)
                    }
                }
                
                self.destinations = decodedDestinations
            }
            
        } catch {
            errorMessage = "Erreur lors de la recherche: \(error.localizedDescription)"
            print("Erreur Supabase: \(error)")
        }
        
        isLoading = false
    }
    
    func getDestinationsByCategory(categoryId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabase
                .from("destinations")
                .select()
                .eq("category_id", value: categoryId)
                .execute()
            
            let data = response.data
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var decodedDestinations: [Destination] = []
                
                for destinationDict in jsonArray {
                    if let destination = try? decodeDestination(from: destinationDict) {
                        decodedDestinations.append(destination)
                    }
                }
                
                self.destinations = decodedDestinations
            }
            
        } catch {
            errorMessage = "Erreur lors du filtrage par catégorie: \(error.localizedDescription)"
            print("Erreur Supabase: \(error)")
        }
        
        isLoading = false
    }
    
    func getDestinationsByType(type: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabase
                .from("destinations")
                .select()
                .eq("type", value: type)
                .execute()
            
            let data = response.data
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var decodedDestinations: [Destination] = []
                
                for destinationDict in jsonArray {
                    if let destination = try? decodeDestination(from: destinationDict) {
                        decodedDestinations.append(destination)
                    }
                }
                
                self.destinations = decodedDestinations
            }
            
        } catch {
            errorMessage = "Erreur lors du filtrage par type: \(error.localizedDescription)"
            print("Erreur Supabase: \(error)")
        }
        
        isLoading = false
    }
} 