import Foundation
import Supabase

@MainActor
class CategoryService: ObservableObject {
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseConfig.client
    
    init() {
        Task {
            await fetchCategories()
        }
    }
    
    func fetchCategories() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabase
                .from("categories")
                .select()
                .execute()
            
            let data = response.data
            
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var decodedCategories: [Category] = []
                
                for categoryDict in jsonArray {
                    if let category = try? decodeCategory(from: categoryDict) {
                        decodedCategories.append(category)
                    }
                }
                
                self.categories = decodedCategories
            } else {
                throw NSError(domain: "CategoryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Impossible de décoder les données JSON"])
            }
            
        } catch {
            errorMessage = "Erreur lors du chargement des catégories: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func decodeCategory(from dict: [String: Any]) throws -> Category {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String else {
            throw NSError(domain: "CategoryService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Données de catégorie incomplètes"])
        }
        
        let imagePath = dict["image_path"] as? String
        
        return Category(
            id: id,
            name: name,
            imagePath: imagePath
        )
    }
    
    func fetchCategory(by id: String) async -> Category? {
        do {
            let response = try await supabase
                .from("categories")
                .select()
                .eq("id", value: id)
                .single()
                .execute()
            
            let data = response.data
            if let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return try decodeCategory(from: jsonDict)
            }
            
        } catch {
            print("Erreur lors de la récupération de la catégorie: \(error)")
        }
        
        return nil
    }
} 