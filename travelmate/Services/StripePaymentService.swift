import Foundation
import Stripe
import UIKit

@MainActor
class StripePaymentService: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var paymentStatus: PaymentStatus = .idle
    
    enum PaymentStatus: Equatable {
        case idle
        case processing
        case success
        case failed(String)
        
        static func == (lhs: PaymentStatus, rhs: PaymentStatus) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle):
                return true
            case (.processing, .processing):
                return true
            case (.success, .success):
                return true
            case (.failed(let lhsError), .failed(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
    
    // Configuration Stripe
    private let publishableKey = "pk_test_51ReySuFMFs1dsPI2CShuVgACTBDdGXlQfZK9QjzNfFFmXZrDe7qslaK38Su9qNrWXETGKc0zzk1qdJpDRSQd6eyh0080sH3Q6Z"
    
    func createPaymentIntent(amount: Int, currency: String = "eur") async -> (success: Bool, clientSecret: String?) {
        isLoading = true
        paymentStatus = .processing
        errorMessage = nil
        
        do {
            // Créer la requête pour le Payment Intent
            guard let url = URL(string: BackendConfig.createPaymentIntent) else {
                throw BackendConfig.NetworkError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = BackendConfig.requestTimeout
            
            let requestBody: [String: Any] = [
                "amount": amount,
                "currency": currency
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendConfig.NetworkError.serverError("Réponse HTTP invalide")
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Erreur serveur"
                throw BackendConfig.NetworkError.serverError("Code \(httpResponse.statusCode): \(errorMessage)")
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let clientSecret = json["client_secret"] as? String {
                isLoading = false
                paymentStatus = .idle
                return (true, clientSecret)
            } else {
                throw BackendConfig.NetworkError.decodingError
            }
            
        } catch {
            isLoading = false
            let errorMessage = error.localizedDescription
            paymentStatus = .failed(errorMessage)
            self.errorMessage = "Erreur lors de la création du paiement: \(errorMessage)"
            return (false, nil)
        }
    }
    
    func processPayment(clientSecret: String, paymentMethodId: String) async -> Bool {
        isLoading = true
        paymentStatus = .processing
        errorMessage = nil
        
        do {
            print("🔵 Stripe: Début du traitement du paiement")
            print("🔵 Stripe: Client Secret: \(clientSecret.prefix(20))...")
            print("🔵 Stripe: Payment Method ID: \(paymentMethodId)")
            
            // Configurer le PaymentIntent avec Stripe
            let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
            paymentIntentParams.paymentMethodId = paymentMethodId
            
            let result: Bool = try await withCheckedThrowingContinuation { continuation in
                STPPaymentHandler.shared().confirmPayment(paymentIntentParams, with: self) { status, paymentIntent, error in
                    print("🔵 Stripe: Statut reçu: \(status.rawValue)")
                    
                    if let error = error {
                        print("🔴 Stripe: Erreur lors du paiement: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    } else if status == .succeeded {
                        print("🟢 Stripe: Paiement réussi")
                        continuation.resume(returning: true)
                    } else {
                        print("🔴 Stripe: Paiement échoué avec statut: \(status.rawValue)")
                        continuation.resume(throwing: NSError(domain: "StripePaymentService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Paiement échoué - Statut: \(status.rawValue)"]))
                    }
                }
            }
            
            isLoading = false
            paymentStatus = .success
            return result
            
        } catch {
            isLoading = false
            let errorMessage = error.localizedDescription
            print("🔴 Stripe: Erreur finale: \(errorMessage)")
            paymentStatus = .failed(errorMessage)
            self.errorMessage = "Erreur lors du paiement: \(errorMessage)"
            return false
        }
    }
    
    func resetPaymentStatus() {
        paymentStatus = .idle
        errorMessage = nil
    }
}

// MARK: - STPAuthenticationContext
extension StripePaymentService: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        // Retourner le contrôleur de vue principal
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return UIViewController()
        }
        
        return rootViewController
    }
} 