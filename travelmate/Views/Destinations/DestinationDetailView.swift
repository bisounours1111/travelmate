import SwiftUI
import MapKit

struct DestinationDetailView: View {
    let destination: Destination
    @State private var selectedTab = 0
    @State private var showingBookingSheet = false
    @EnvironmentObject var favoriteService: FavoriteService
    @StateObject private var reservationService = ReservationService()
    @StateObject private var reviewService = ReviewService()
    @EnvironmentObject var authService: AuthService
    @State private var favoriteCount = 0
    @State private var reviewStats: ReviewStats?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var activityService = ActivityService()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Informations principales en haut
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Spacer(minLength: 0)
                        Spacer()
                        
                        // Bouton favori avec compteur
                        if let currentUser = authService.currentUser {
                            VStack(spacing: 4) {
                                Button(action: {
                                    Task {
                                        await favoriteService.toggleFavorite(userId: currentUser.id, destinationId: destination.id)
                                        // Mettre à jour le compteur après le toggle
                                        favoriteCount = await favoriteService.getFavoriteCount(for: destination.id)
                                    }
                                }) {
                                    Image(systemName: favoriteService.isFavorite(userId: currentUser.id, destinationId: destination.id) ? "heart.fill" : "heart")
                                        .foregroundColor(favoriteService.isFavorite(userId: currentUser.id, destinationId: destination.id) ? .red : .gray)
                                        .font(.title2)
                                }
                                
                                // Compteur de favoris
                                Text("\(favoriteCount)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
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
                        
                        // Statistiques d'avis réelles
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", reviewStats?.averageRating ?? destination.rating))
                            Text("(\(reviewStats?.reviewCount ?? 0) avis)")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text(destination.description)
                        .font(.body)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.top, 60)
                
                // Carrousel d'images en dessous
                if !destination.imageURLs.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Photos")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ImageCarousel(imageURLs: destination.imageURLs)
                            .frame(height: 250)
                    }
                }
                
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
                    
                    ActivitiesTab(destination: destination, activityService: activityService)
                        .tag(1)
                    
                    MapTab(destination: destination, activities: activityService.activities)
                        .tag(2)
                    
                    ReviewsTab(destination: destination)
                        .tag(3)
                }
                .frame(height: 400)
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(false)
        .navigationTitle(destination.title)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(
            VStack {
                Spacer()
                
                // Barre de réservation
                BookingBar(showingBookingSheet: $showingBookingSheet, destination: destination)
            }
        )
        .sheet(isPresented: $showingBookingSheet) {
            BookingView(destination: destination, reservationService: reservationService, authService: authService)
        }
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        if let currentUser = authService.currentUser {
            Task {
                favoriteCount = await favoriteService.getFavoriteCount(for: destination.id)
                reviewStats = await reviewService.getReviewStats(for: destination.id)
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
    @ObservedObject var activityService: ActivityService

    var body: some View {
        ScrollView {
            if activityService.activities.isEmpty {
                ProgressView("Chargement des activités...")
                    .onAppear {
                        Task {
                            await activityService.fetchNearbyActivities(
                                lat: destination.lat,
                                lon: destination.long
                            )
                        }
                    }
            } else {
                LazyVStack(spacing: 15) {
                    ForEach(activityService.activities) { activity in
                        ActivityCard(activity: activity)
                    }
                }
                .padding()
            }
        }
    }
}

struct ActivityCard: View {
    let activity: NearbyActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(activity.name)
                .font(.headline)
            Text(activity.description)
                .font(.subheadline)
                .foregroundColor(.gray)
            HStack {
                Text(activity.category)
                    .font(.caption)
                    .foregroundColor(.blue)
                Spacer()
                if activity.rating == 0 {
                    Text("Sans note")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Text("⭐️ \(String(format: "%.1f", activity.rating))")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 3)
    }
}

struct MapTab: View {
    let destination: Destination
    var activities: [NearbyActivity] = []

    @State private var region: MKCoordinateRegion

    init(destination: Destination, activities: [NearbyActivity] = []) {
        self.destination = destination
        self.activities = activities
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: destination.lat, longitude: destination.long),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ))
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: activities) { activity in
            MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: activity.position.lat, longitude: activity.position.lng)) {
                let icon = iconData(for: activity.category)
                VStack(spacing: 2) {
                    Image(systemName: icon.name)
                        .foregroundColor(icon.color)
                        .font(.title)
                    Text(activity.name)
                        .font(.caption2)
                        .fixedSize()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

func iconData(for category: String) -> (name: String, color: Color) {
    switch category {
    case "monument", "historical_landmark":
        return ("building.columns", .gray)
    case "museum", "gallery", "art_gallery":
        return ("paintpalette", .purple)
    case "park", "theme_park", "amusement_park":
        return ("leaf.fill", .green)
    case "tourist_attraction", "scenic_lookout":
        return ("binoculars.fill", .orange)
    case "church", "place_of_worship":
        return ("cross.fill", .indigo)
    case "cemetery":
        return ("leaf.arrow.circlepath", .gray)
    case "zoo", "aquarium":
        return ("pawprint.fill", .teal)
    case "stadium":
        return ("sportscourt.fill", .mint)
    case "library":
        return ("books.vertical.fill", .brown)
    case "movie_theater":
        return ("film.fill", .red)
    case "night_club", "bar":
        return ("wineglass.fill", .pink)
    case "casino":
        return ("die.face.5.fill", .yellow)
    case "bowling_alley":
        return ("figure.bowling", .orange)
    case "spa":
        return ("drop.fill", .mint)
    case "restaurant":
        return ("fork.knife", .red)
    case "cafe":
        return ("cup.and.saucer.fill", .brown)
    case "campground":
        return ("tent.fill", .green)
    case "point_of_interest":
        return ("star.circle.fill", .yellow)
    case "natural_feature", "mountain":
        return ("mountain.2.fill", .gray)
    case "hiking_area":
        return ("figure.hiking", .green)
    case "beach", "lake", "water_park":
        return ("water.waves", .cyan)
    default:
        return ("mappin.circle.fill", .black)
    }
}

struct ReviewsTab: View {
    let destination: Destination
    
    var body: some View {
        ReviewsView(destination: destination)
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
    let destination: Destination
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("À partir de")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("\(Int(destination.price ?? 799))€")
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
    
    private var pricePerPerson: Int { Int(destination.price ?? 799) }
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
