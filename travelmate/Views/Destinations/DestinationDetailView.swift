import SwiftUI
import MapKit

struct DestinationDetailView: View {
    let destination: Destination
    @State private var selectedTab = 0
    @State private var showingBookingSheet = false
    @StateObject private var favoriteService = FavoriteService()
    @StateObject private var reservationService = ReservationService()
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Image principale
                ImageHeaderView(destination: destination, favoriteService: favoriteService, authService: authService)
                
                // Informations principales
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text(destination.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // Bouton favori
                        if let currentUser = authService.currentUser {
                            Button(action: {
                                Task {
                                    if favoriteService.isFavorite(userId: currentUser.id, destinationId: destination.id) {
                                        await favoriteService.removeFromFavorites(userId: currentUser.id, destinationId: destination.id)
                                    } else {
                                        await favoriteService.addToFavorites(userId: currentUser.id, destinationId: destination.id)
                                    }
                                }
                            }) {
                                Image(systemName: favoriteService.isFavorite(userId: currentUser.id, destinationId: destination.id) ? "heart.fill" : "heart")
                                    .foregroundColor(favoriteService.isFavorite(userId: currentUser.id, destinationId: destination.id) ? .red : .gray)
                                    .font(.title2)
                            }
                        }
                    }
                    
                    HStack {
                        Text(destination.type)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        
                        Spacer()
                        
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", destination.rating))
                        Text("(\(Int.random(in: 50...200)) avis)")
                            .foregroundColor(.gray)
                    }
                    
                    Text(destination.description)
                        .font(.body)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                // Sélecteur d'onglets
                Picker("Section", selection: $selectedTab) {
                    Text("Aperçu").tag(0)
                    Text("Activités").tag(1)
                    Text("Carte").tag(2)
                    Text("Avis").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Contenu des onglets
                TabView(selection: $selectedTab) {
                    OverviewTab(destination: destination)
                        .tag(0)
                    
                    ActivitiesTab(destination: destination)
                        .tag(1)
                    
                    MapTab(destination: destination)
                        .tag(2)
                    
                    ReviewsTab()
                        .tag(3)
                }
                .frame(height: 400)
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .ignoresSafeArea(edges: .top)
        .overlay(
            VStack {
                Spacer()
                
                // Barre de réservation
                BookingBar(showingBookingSheet: $showingBookingSheet)
            }
        )
        .sheet(isPresented: $showingBookingSheet) {
            BookingView(destination: destination, reservationService: reservationService, authService: authService)
        }
        .onAppear {
            if let currentUser = authService.currentUser {
                Task {
                    await favoriteService.fetchFavorites(for: currentUser.id)
                }
            }
        }
    }
}

struct ImageHeaderView: View {
    let destination: Destination
    let favoriteService: FavoriteService
    let authService: AuthService
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if !destination.imageURL.isEmpty {
                AsyncImage(url: URL(string: destination.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                        .clipped()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                        )
                }
            } else {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
            }
            
            // Overlay avec le titre
            VStack(alignment: .leading) {
                Spacer()
                Text(destination.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                    .padding()
            }
        }
    }
}

struct OverviewTab: View {
    let destination: Destination
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Type
                InfoSection(title: "Type", content: destination.type)
                
                // Localisation
                InfoSection(title: "Localisation", content: destination.location)
                
                // Climat
                InfoSection(title: "Climat", content: destination.climate)
                
                // Culture
                InfoSection(title: "Culture", content: destination.culture)
                
                // Meilleure période
                InfoSection(title: "Meilleure période", content: "Avril à Octobre")
                
                // Informations pratiques
                InfoSection(title: "Informations pratiques", content: "Visa requis pour les séjours de plus de 90 jours")
            }
            .padding()
        }
    }
}

struct ActivitiesTab: View {
    let destination: Destination
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(destination.activities) { activity in
                    ActivityCard(activity: activity)
                }
            }
            .padding()
        }
    }
}

struct ActivityCard: View {
    let activity: Destination.Activity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Image de l'activité
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 150)
                .overlay(
                    Text(activity.name)
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 5) {
                Text(activity.name)
                    .font(.headline)
                
                Text(activity.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    Text("\(Int(activity.price))€")
                        .fontWeight(.bold)
                    
                    Text("•")
                    
                    Text(activity.duration)
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct MapTab: View {
    let destination: Destination
    
    var body: some View {
        Map(coordinateRegion: .constant(MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: destination.lat,
                longitude: destination.long
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )))
        .overlay(
            VStack {
                Spacer()
                
                HStack {
                    VStack(alignment: .leading) {
                        Text(destination.title)
                            .font(.headline)
                        Text(destination.location)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Text("Itinéraire")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding()
            }
        )
    }
}

struct ReviewsTab: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(0..<5) { _ in
                    ReviewCard()
                }
            }
            .padding()
        }
    }
}

struct ReviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading) {
                    Text("Jean Dupont")
                        .font(.headline)
                    
                    HStack {
                        ForEach(0..<5) { _ in
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                }
                
                Spacer()
                
                Text("Il y a 2 mois")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text("Excellent séjour ! Les activités étaient bien organisées et le personnel était très accueillant. Je recommande vivement cette destination.")
                .font(.body)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct InfoSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
            
            Text(content)
                .font(.body)
                .foregroundColor(.gray)
        }
    }
}

struct BookingBar: View {
    @Binding var showingBookingSheet: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("À partir de")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("799€")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("par personne")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: { showingBookingSheet = true }) {
                Text("Réserver")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .shadow(radius: 5)
    }
}

struct BookingView: View {
    let destination: Destination
    let reservationService: ReservationService
    let authService: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var selectedStartDate = Date()
    @State private var selectedEndDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // +7 jours
    @State private var numberOfPeople = 2
    @State private var isProcessing = false
    @State private var showingStripePayment = false
    @State private var createdReservation: Reservation?
    @State private var errorMessage: String?
    
    private var pricePerPerson: Int { Int.random(in: 500...2000) }
    private var totalPrice: Int { pricePerPerson * numberOfPeople }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Dates")) {
                    DatePicker("Date de départ", selection: $selectedStartDate, displayedComponents: .date)
                    DatePicker("Date de retour", selection: $selectedEndDate, displayedComponents: .date)
                }
                
                Section(header: Text("Voyageurs")) {
                    Stepper("Nombre de personnes: \(numberOfPeople)", value: $numberOfPeople, in: 1...10)
                }
                
                Section(header: Text("Récapitulatif")) {
                    HStack {
                        Text("Prix par personne")
                        Spacer()
                        Text("\(pricePerPerson)€")
                    }
                    
                    HStack {
                        Text("Total")
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(totalPrice)€")
                            .fontWeight(.bold)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await createReservation()
                        }
                    }) {
                        if isProcessing {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Création de la réservation...")
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        } else {
                            Text("Procéder au paiement")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(isProcessing)
                }
            }
            .navigationTitle("Réservation")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingStripePayment) {
                if let reservation = createdReservation {
                    StripePaymentView(
                        reservation: reservation,
                        destination: destination,
                        onSuccess: {
                            dismiss()
                        },
                        onFailure: { error in
                            errorMessage = error
                        },
                        onReservationConfirmed: {
                            Task {
                                if let currentUser = authService.currentUser {
                                    await reservationService.fetchReservations(for: currentUser.id)
                                }
                            }
                        }
                    )
                }
            }
        }
    }
    
    private func createReservation() async {
        guard let currentUser = authService.currentUser else {
            errorMessage = "Utilisateur non connecté"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        let result = await reservationService.createReservation(
            userId: currentUser.id,
            destinationId: destination.id,
            startDate: selectedStartDate,
            endDate: selectedEndDate,
            numberOfPeople: numberOfPeople,
            totalPrice: Double(totalPrice)
        )
        
        isProcessing = false
        
        if result.success {
            // Créer un objet Reservation temporaire pour la vue de paiement
            let tempReservation = Reservation(
                id: result.reservationId ?? UUID().uuidString,
                userId: currentUser.id,
                destinationId: destination.id,
                startDate: ISO8601DateFormatter().string(from: selectedStartDate),
                endDate: ISO8601DateFormatter().string(from: selectedEndDate),
                numberOfPeople: numberOfPeople,
                totalPrice: Double(totalPrice),
                status: .pending,
                stripePaymentIntentId: result.paymentIntentId,
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
            
            createdReservation = tempReservation
            showingStripePayment = true
        } else {
            errorMessage = "Erreur lors de la création de la réservation"
        }
    }
}
