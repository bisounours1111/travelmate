import SwiftUI

struct LegalView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                // Sélecteur d'onglets
                Picker("Section", selection: $selectedTab) {
                    Text("Mentions légales").tag(0)
                    Text("Politique de confidentialité").tag(1)
                    Text("CGU").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Contenu des onglets
                TabView(selection: $selectedTab) {
                    LegalNoticeView()
                        .tag(0)
                    
                    PrivacyPolicyView()
                        .tag(1)
                    
                    TermsOfServiceView()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Informations légales")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView()
                }
            }
        }
    }
}

struct LegalNoticeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    LegalSection(
                        title: "Éditeur du site",
                        content: """
                        TravelMate SAS
                        123 Rue du Voyage
                        75001 Paris, France
                        
                        SIRET : 123 456 789 00000
                        RCS Paris B 123 456 789
                        """
                    )
                    
                    LegalSection(
                        title: "Directeur de la publication",
                        content: "Jean Dupont, Président"
                    )
                    
                    LegalSection(
                        title: "Hébergement",
                        content: """
                        Amazon Web Services EMEA SARL
                        38 Avenue John F. Kennedy
                        L-1855, Luxembourg
                        """
                    )
                }
                
                Group {
                    LegalSection(
                        title: "Propriété intellectuelle",
                        content: """
                        L'ensemble de ce site relève de la législation française et internationale sur le droit d'auteur et la propriété intellectuelle. Tous les droits de reproduction sont réservés, y compris pour les documents téléchargeables et les représentations iconographiques et photographiques.
                        """
                    )
                    
                    LegalSection(
                        title: "Crédits",
                        content: """
                        Design et développement : TravelMate
                        Images : Unsplash, Pexels
                        Icônes : SF Symbols
                        """
                    )
                }
            }
            .padding()
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    LegalSection(
                        title: "Collecte des données",
                        content: """
                        Nous collectons les informations que vous nous fournissez directement, notamment :
                        - Nom et prénom
                        - Adresse email
                        - Numéro de téléphone
                        - Informations de paiement
                        - Historique de réservations
                        """
                    )
                    
                    LegalSection(
                        title: "Utilisation des données",
                        content: """
                        Vos données sont utilisées pour :
                        - Traiter vos réservations
                        - Vous envoyer des confirmations
                        - Améliorer nos services
                        - Personnaliser votre expérience
                        - Communiquer avec vous
                        """
                    )
                }
                
                Group {
                    LegalSection(
                        title: "Protection des données",
                        content: """
                        Nous mettons en œuvre des mesures de sécurité appropriées pour protéger vos données personnelles contre tout accès, modification, divulgation ou destruction non autorisés.
                        """
                    )
                    
                    LegalSection(
                        title: "Vos droits",
                        content: """
                        Conformément au RGPD, vous disposez des droits suivants :
                        - Droit d'accès à vos données
                        - Droit de rectification
                        - Droit à l'effacement
                        - Droit à la portabilité
                        - Droit d'opposition
                        """
                    )
                    
                    LegalSection(
                        title: "Cookies",
                        content: """
                        Nous utilisons des cookies pour améliorer votre expérience de navigation. Vous pouvez configurer votre navigateur pour refuser les cookies ou être informé quand un cookie est envoyé.
                        """
                    )
                }
            }
            .padding()
        }
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    LegalSection(
                        title: "Acceptation des conditions",
                        content: """
                        En accédant et en utilisant TravelMate, vous acceptez d'être lié par les présentes conditions d'utilisation. Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser notre service.
                        """
                    )
                    
                    LegalSection(
                        title: "Services proposés",
                        content: """
                        TravelMate propose des services de réservation de voyages, incluant :
                        - Réservation d'hébergements
                        - Organisation d'activités
                        - Services de transport
                        - Assistance voyage
                        """
                    )
                }
                
                Group {
                    LegalSection(
                        title: "Prix et paiement",
                        content: """
                        Les prix sont indiqués en euros TTC. Le paiement est exigible immédiatement à la réservation. Nous acceptons les cartes bancaires et les paiements en ligne sécurisés.
                        """
                    )
                    
                    LegalSection(
                        title: "Annulation et remboursement",
                        content: """
                        Les conditions d'annulation varient selon le type de réservation. Veuillez consulter les conditions spécifiques lors de votre réservation. Les remboursements sont effectués selon les modalités prévues dans ces conditions.
                        """
                    )
                    
                    LegalSection(
                        title: "Responsabilité",
                        content: """
                        TravelMate s'engage à fournir les services décrits sur le site. Cependant, nous ne pouvons être tenus responsables des événements indépendants de notre volonté ou des dommages indirects.
                        """
                    )
                }
            }
            .padding()
        }
    }
}

struct LegalSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.blue)
            
            Text(content)
                .font(.body)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    LegalView()
} 