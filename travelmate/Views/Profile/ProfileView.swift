import SwiftUI

struct ProfileView: View {
    @State private var selectedTab = 0
    @StateObject private var favoriteService = FavoriteService()
    @StateObject private var reservationService = ReservationService()
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack {
            // En-tête du profil
            ProfileHeader()
            
            // Sélecteur d'onglets
            Picker("Section", selection: $selectedTab) {
                Text("Réservations").tag(0)
                Text("Favoris").tag(1)
                Text("Paramètres").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Contenu des onglets
            TabView(selection: $selectedTab) {
                ReservationsView(reservationService: reservationService, authService: authService)
                    .tag(0)
                
                FavoritesView(favoriteService: favoriteService, authService: authService)
                    .tag(1)
                
                SettingsView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EmptyView()
            }
        }
        .onAppear {
            if let currentUser = authService.currentUser {
                Task {
                    await favoriteService.fetchFavorites(for: currentUser.id)
                    await reservationService.fetchReservations(for: currentUser.id)
                }
            }
        }
    }
}

struct ProfileHeader: View {
    @EnvironmentObject var authService: AuthService
    @State private var user: AuthUser?

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)
            
            VStack(spacing: 5) {
                let firstName = user?.firstName ?? "Nom"
                let lastName = user?.lastName ?? "Prénom"
                let email = user?.email ?? "Email"
                Text("\(firstName) \(lastName)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 30) {
                StatisticView(value: "\(user?.age ?? 0)", label: "Âge")
                StatisticView(value: "\(user?.role ?? "User")", label: "Rôle")
                StatisticView(value: "4.8", label: "Avis")
            }
            .padding(.top, 10)
        }
        .padding()
        .onAppear {
            Task {
                await authService.setUserConnected()
                user = authService.currentUser
            }
        }
    }
}

struct StatisticView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct ReservationsView: View {
    let reservationService: ReservationService
    let authService: AuthService
    
    var body: some View {
        if reservationService.isLoading {
            Spacer()
            ProgressView("Chargement des réservations...")
            Spacer()
        } else if let errorMessage = reservationService.errorMessage {
            Spacer()
            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text("Erreur")
                    .font(.headline)
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            Spacer()
        } else if reservationService.reservations.isEmpty {
            Spacer()
            VStack {
                Image(systemName: "calendar")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                Text("Aucune réservation")
                    .font(.headline)
                Text("Vos réservations apparaîtront ici")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(reservationService.reservations) { reservation in
                        ReservationCard(reservation: reservation)
                    }
                }
                .padding()
            }
        }
    }
}

struct ReservationCard: View {
    let reservation: Reservation
    @StateObject private var destinationService = DestinationService()
    @State private var destination: Destination?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Image de la destination
            if let destination = destination, !destination.imageURL.isEmpty {
                AsyncImage(url: URL(string: destination.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 150)
                        .clipped()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 150)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
                .cornerRadius(10)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 150)
                    .overlay(
                        Text("Image de destination")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(destination?.title ?? "Destination")
                    .font(.title3)
                    .fontWeight(.bold)
                
                HStack {
                    Image(systemName: "calendar")
                    Text("\(formatDate(reservation.startDate)) - \(formatDate(reservation.endDate))")
                }
                .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "person.2")
                    Text("\(reservation.numberOfPeople) personne\(reservation.numberOfPeople > 1 ? "s" : "")")
                }
                .foregroundColor(.gray)
                
                HStack {
                    Text("Total:")
                    Text("\(Int(reservation.totalPrice))€")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Statut:")
                    Text(reservation.status.rawValue.capitalized)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor(reservation.status))
                }
                
                HStack {
                    Button(action: {}) {
                        Text("Voir les détails")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    if reservation.status == .pending {
                        Button(action: {}) {
                            Text("Annuler")
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .onAppear {
            Task {
                destination = await destinationService.fetchDestination(by: reservation.destinationId)
            }
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
    
    private func statusColor(_ status: Reservation.ReservationStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .confirmed:
            return .green
        case .cancelled:
            return .red
        case .completed:
            return .blue
        }
    }
}

struct FavoritesView: View {
    let favoriteService: FavoriteService
    let authService: AuthService
    @StateObject private var destinationService = DestinationService()
    
    var body: some View {
        if favoriteService.isLoading {
            Spacer()
            ProgressView("Chargement des favoris...")
            Spacer()
        } else if let errorMessage = favoriteService.errorMessage {
            Spacer()
            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text("Erreur")
                    .font(.headline)
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            Spacer()
        } else if favoriteService.favorites.isEmpty {
            Spacer()
            VStack {
                Image(systemName: "heart")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                Text("Aucun favori")
                    .font(.headline)
                Text("Vos destinations favorites apparaîtront ici")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(favoriteService.favorites) { favorite in
                        FavoriteCard(favorite: favorite, destinationService: destinationService)
                    }
                }
                .padding()
            }
        }
    }
}

struct FavoriteCard: View {
    let favorite: Favorite
    let destinationService: DestinationService
    @State private var destination: Destination?
    @StateObject private var favoriteService = FavoriteService()
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        HStack {
            // Image de la destination
            if let destination = destination, !destination.imageURL.isEmpty {
                AsyncImage(url: URL(string: destination.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipped()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
                .cornerRadius(10)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text("Image")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(destination?.title ?? "Destination")
                    .font(.headline)
                
                Text("À partir de \(Int.random(in: 500...2000))€")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("4.8")
                    Text("(150 avis)")
                        .foregroundColor(.gray)
                }
            }
            .padding(.leading)
            
            Spacer()
            
            Button(action: {
                Task {
                    if let currentUser = authService.currentUser {
                        await favoriteService.removeFromFavorites(userId: currentUser.id, destinationId: favorite.destinationId)
                    }
                }
            }) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .onAppear {
            Task {
                destination = await destinationService.fetchDestination(by: favorite.destinationId)
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @State private var language = "Français"
    @State private var showingLogoutAlert = false
    
    var body: some View {
        List {
            Section(header: Text("Préférences")) {
                Toggle("Notifications", isOn: $notificationsEnabled)
                Toggle("Mode sombre", isOn: $darkModeEnabled)
                
                Picker("Langue", selection: $language) {
                    Text("Français").tag("Français")
                    Text("Anglais").tag("Anglais")
                    Text("Espagnol").tag("Espagnol")
                }
            }
            
            Section(header: Text("Compte")) {
                NavigationLink("Informations personnelles") {
                    PersonalInfoView()
                }
                
                NavigationLink("Sécurité") {
                    SecurityView()
                }
                
                NavigationLink("Paiement") {
                    PaymentView()
                }
            }
            
            Section(header: Text("À propos")) {
                NavigationLink("Mentions légales") {
                    LegalView()
                }
                
                NavigationLink("Politique de confidentialité") {
                    PrivacyPolicyView()
                }
                
                NavigationLink("Conditions d'utilisation") {
                    TermsOfServiceView()
                }
            }
            
            Section {
                Button(action: { showingLogoutAlert = true }) {
                    Text("Se déconnecter")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Déconnexion", isPresented: $showingLogoutAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Se déconnecter", role: .destructive) {
                Task {
                    try? await authService.signOut()
                }
            }
        } message: {
            Text("Êtes-vous sûr de vouloir vous déconnecter ?")
        }
    }
}

#Preview {
    ProfileView()
}

// MARK: - Vues des paramètres
struct PersonalInfoView: View {
    @State private var firstName = "Jean"
    @State private var lastName = "Dupont"
    @State private var email = "jean.dupont@email.com"
    @State private var phone = "+33 6 12 34 56 78"
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Informations personnelles")) {
                    TextField("Prénom", text: $firstName)
                    TextField("Nom", text: $lastName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Téléphone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section {
                    Button("Sauvegarder") {
                        // Action de sauvegarde
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Informations personnelles")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView()
                }
            }
        }
    }
}

struct SecurityView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Changer le mot de passe")) {
                    SecureField("Mot de passe actuel", text: $currentPassword)
                    SecureField("Nouveau mot de passe", text: $newPassword)
                    SecureField("Confirmer le nouveau mot de passe", text: $confirmPassword)
                }
                
                Section {
                    Button("Changer le mot de passe") {
                        // Action de changement de mot de passe
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Sécurité")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView()
                }
            }
        }
    }
}

struct PaymentView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Méthodes de paiement")) {
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("•••• •••• •••• 1234")
                            Text("Expire 12/25")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button("Modifier") {
                            // Action de modification
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section {
                    Button("Ajouter une carte") {
                        // Action d'ajout de carte
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Paiement")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView()
                }
            }
        }
    }
} 
