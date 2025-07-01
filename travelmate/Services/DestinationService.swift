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
                var decodedDestinations: [Destination] = []
                
                for destinationDict in jsonArray {
                    print("Destination brute:", destinationDict)
                    if let destination = try? decodeDestination(from: destinationDict) {
                        decodedDestinations.append(destination)
                    } else {
                        print("Erreur de décodage pour:", destinationDict)
                    }
                }
                
                self.destinations = decodedDestinations
                print("Destinations récupérées avec succès")
                print(decodedDestinations)
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
        // Conversion UUID -> String
        let id: String
        if let idString = dict["id"] as? String {
            id = idString
        } else if let idUUID = dict["id"] as? UUID {
            id = idUUID.uuidString
        } else {
            id = String(describing: dict["id"] ?? "")
        }

        guard !id.isEmpty,
              let title = dict["title"] as? String,
              let location = dict["location"] as? String,
              let lat = dict["lat"] as? Double,
              let lng = dict["lng"] as? Double else {
            throw NSError(domain: "DestinationService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Données de destination incomplètes"])
        }

        let type = dict["type"] as? String ?? "" // Si jamais le champ est optionnel
        let notes = dict["notes"] as? String
        let categoryId: String? = {
            if let cat = dict["category_id"] as? String { return cat }
            if let cat = dict["category_id"] as? UUID { return cat.uuidString }
            if let cat = dict["category_id"] { return String(describing: cat) }
            return nil
        }()
        let imagePaths = dict["image_path"] as? [String]
        let price = dict["price"] as? Double
        let promo = dict["promo"] as? Double

        return Destination(
            id: id,
            title: title,
            type: type,
            location: location,
            notes: notes,
            lat: lat,
            long: lng,
            categoryId: categoryId,
            imagePaths: imagePaths,
            price: price,
            promo: promo
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
            print("Destination récupérée avec succès")
            print(data)
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
                    print("Destination brute:", destinationDict)
                    if let destination = try? decodeDestination(from: destinationDict) {
                        decodedDestinations.append(destination)
                    } else {
                        print("Erreur de décodage pour:", destinationDict)
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
                    print("Destination brute:", destinationDict)
                    if let destination = try? decodeDestination(from: destinationDict) {
                        decodedDestinations.append(destination)
                    } else {
                        print("Erreur de décodage pour:", destinationDict)
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
                    print("Destination brute:", destinationDict)
                    if let destination = try? decodeDestination(from: destinationDict) {
                        decodedDestinations.append(destination)
                    } else {
                        print("Erreur de décodage pour:", destinationDict)
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
