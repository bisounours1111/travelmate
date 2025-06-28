import SwiftUI
import Stripe

struct StripePaymentView: View {
    let reservation: Reservation
    let destination: Destination
    let onSuccess: () -> Void
    let onFailure: (String) -> Void
    
    @StateObject private var stripePaymentService = StripePaymentService()
    @StateObject private var reservationService = ReservationService()
    @Environment(\.dismiss) var dismiss
    
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var cardholderName = ""
    @State private var showingPaymentSheet = false
    @State private var clientSecret: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // En-tête
                VStack(spacing: 10) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Paiement sécurisé")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Montant: \(Int(reservation.totalPrice))€")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .padding(.top)
                
                // Informations de réservation
                VStack(alignment: .leading, spacing: 10) {
                    Text("Récapitulatif de la réservation")
                        .font(.headline)
                    
                    HStack {
                        Text("Destination:")
                        Spacer()
                        Text(destination.title)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Dates:")
                        Spacer()
                        Text("\(formatDate(reservation.startDate)) - \(formatDate(reservation.endDate))")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Voyageurs:")
                        Spacer()
                        Text("\(reservation.numberOfPeople) personne\(reservation.numberOfPeople > 1 ? "s" : "")")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Total:")
                        Spacer()
                        Text("\(Int(reservation.totalPrice))€")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Formulaire de paiement
                VStack(spacing: 15) {
                    TextField("Nom du titulaire", text: $cardholderName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Numéro de carte", text: $cardNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    HStack {
                        TextField("MM/AA", text: $expiryDate)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                        TextField("CVV", text: $cvv)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                }
                .padding(.horizontal)
                
                // Bouton de paiement
                Button(action: {
                    Task {
                        await processPayment()
                    }
                }) {
                    if stripePaymentService.isLoading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Traitement en cours...")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    } else {
                        Text("Payer \(Int(reservation.totalPrice))€")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .disabled(stripePaymentService.isLoading || !isFormValid)
                .padding(.horizontal)
                
                // Message d'erreur
                if let errorMessage = stripePaymentService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Informations de sécurité
                VStack(spacing: 5) {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.green)
                        Text("Paiement sécurisé par Stripe")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text("Vos informations de paiement sont chiffrées et sécurisées")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom)
            }
            .navigationTitle("Paiement")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                createPaymentIntent()
            }
            .onChange(of: stripePaymentService.paymentStatus) { _, status in
                handlePaymentStatusChange(status)
            }
        }
    }
    
    private var isFormValid: Bool {
        !cardholderName.isEmpty &&
        cardNumber.count >= 13 &&
        expiryDate.count == 5 &&
        cvv.count >= 3
    }
    
    private func createPaymentIntent() {
        Task {
            let result = await stripePaymentService.createPaymentIntent(
                amount: Int(reservation.totalPrice * 100),
                currency: "eur"
            )
            
            if result.success {
                clientSecret = result.clientSecret
            } else {
                onFailure("Impossible de créer le paiement")
            }
        }
    }
    
    private func processPayment() async {
        guard let clientSecret = clientSecret else {
            onFailure("Erreur de configuration du paiement")
            return
        }
        
        // Créer un PaymentMethod avec les informations de carte
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = cardNumber
        cardParams.expMonth = NSNumber(value: extractExpiryMonth())
        cardParams.expYear = NSNumber(value: extractExpiryYear())
        cardParams.cvc = cvv
        
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = cardholderName
        
        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: billingDetails,
            metadata: nil
        )
        
        do {
            let paymentMethod: STPPaymentMethod = try await withCheckedThrowingContinuation { continuation in
                STPAPIClient.shared.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let paymentMethod = paymentMethod {
                        continuation.resume(returning: paymentMethod)
                    } else {
                        continuation.resume(throwing: NSError(domain: "StripePaymentView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Erreur de création du PaymentMethod"]))
                    }
                }
            }
            
            // Traiter le paiement
            let success = await stripePaymentService.processPayment(
                clientSecret: clientSecret,
                paymentMethodId: paymentMethod.stripeId
            )
            
            if success {
                // Confirmer la réservation
                let confirmed = await reservationService.confirmReservation(
                    reservationId: reservation.id,
                    paymentIntentId: extractPaymentIntentId(from: clientSecret)
                )
                
                if confirmed {
                    onSuccess()
                } else {
                    onFailure("Erreur lors de la confirmation de la réservation")
                }
            } else {
                onFailure("Paiement échoué")
            }
            
        } catch {
            onFailure("Erreur lors du paiement: \(error.localizedDescription)")
        }
    }
    
    private func handlePaymentStatusChange(_ status: StripePaymentService.PaymentStatus) {
        switch status {
        case .success:
            onSuccess()
        case .failed(let error):
            onFailure(error)
        default:
            break
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        
        if let date = formatter.date(from: dateString) {
            return displayFormatter.string(from: date)
        }
        return dateString
    }
    
    private func extractExpiryMonth() -> UInt {
        let components = expiryDate.split(separator: "/")
        return UInt(components.first ?? "0") ?? 0
    }
    
    private func extractExpiryYear() -> UInt {
        let components = expiryDate.split(separator: "/")
        let yearString = components.last ?? "0"
        let year = UInt(yearString) ?? 0
        return year < 100 ? 2000 + year : year
    }
    
    private func extractPaymentIntentId(from clientSecret: String) -> String {
        let components = clientSecret.split(separator: "_secret_")
        return String(components.first ?? "")
    }
}
