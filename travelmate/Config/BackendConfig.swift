import Foundation

struct BackendConfig {
    // Configuration du backend selon l'environnement
    static let baseURL: String = {
        #if DEBUG
        // URL pour le développement local
        return "http://localhost:8000"
        #else
        // URL pour la production (à remplacer par votre URL de production)
        return "http://localhost:8000"
        #endif
    }()
    
    // Endpoints
    static let createPaymentIntent = "\(baseURL)/create-payment-intent"
    static let paymentStatus = "\(baseURL)/payment-status"
    static let confirmPaymentIntent = "\(baseURL)/confirm-payment-intent"
    
    // Configuration des timeouts
    static let requestTimeout: TimeInterval = 30.0
    static let resourceTimeout: TimeInterval = 60.0
}

// Extension pour les erreurs réseau
extension BackendConfig {
    enum NetworkError: Error, LocalizedError {
        case invalidURL
        case noData
        case decodingError
        case serverError(String)
        case networkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "URL invalide"
            case .noData:
                return "Aucune donnée reçue"
            case .decodingError:
                return "Erreur de décodage des données"
            case .serverError(let message):
                return "Erreur serveur: \(message)"
            case .networkError(let error):
                return "Erreur réseau: \(error.localizedDescription)"
            }
        }
    }
} 