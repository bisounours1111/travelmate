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
                // Onglets tout en haut
                Picker("Section", selection: $selectedTab) {
                    Text("Aperçu").tag(0)
                    Text("Activités").tag(1)
                    Text("Carte").tag(2)
                    Text("Avis").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 150)

                // Contenu des onglets
                TabView(selection: $selectedTab) {
                    OverviewTab(destination: destination)
                        .tag(0)
                        .padding()
                    ActivitiesTab(destination: destination, activityService: activityService)
                        .tag(1)
                    MapTab(destination: destination, activities: activityService.activities)
                        .tag(2)
                    ReviewsTab(destination: destination)
                        .tag(3)
                }
                .frame(height: 550)
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
    @State private var categoryName: String = "Chargement..."
    @StateObject private var categoryService = CategoryService()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Description
                Text(destination.description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(.horizontal)

                // Carrousel d'images
                if !destination.imageURLs.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Photos")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        ZStack {
                            Color.white
                                .cornerRadius(18)
                                .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 4)
                            ImageCarousel(imageURLs: destination.imageURLs)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .frame(height: 250)
                        .padding(.horizontal)
                    }
                }

                // Sections d'infos
                VStack(spacing: 14) {
                    InfoSection(title: "Localisation", content: destination.location)
                    InfoSection(title: "Catégorie", content: categoryName)
                    // Affichage du prix avec promo
                    if let price = destination.price {
                        if let promo = destination.promo, promo < 1 {
                            let promoPrice = Int(Double(price) * promo)
                            let originalPrice = Int(price)
                            InfoSection(title: "Prix", content: "\(originalPrice)€  →  \(promoPrice)€ (-\(Int((1-promo)*100))%)")
                        } else {
                            InfoSection(title: "Prix", content: "\(Int(price))€")
                        }
                    }
                    if let notes = destination.notes, !notes.isEmpty {
                        InfoSection(title: "Notes", content: notes)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                .background(Color.clear)
            }
            .padding(.top, 16)
        }
        .onAppear {
            Task {
                if let id = destination.categoryId {
                    categoryName = await CategoryService().getCategoryName(for: id)
                } else {
                    categoryName = "Aucune catégorie"
                }
            }
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
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(content)
                .font(.body)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
    }
}

struct BookingBar: View {
    @Binding var showingBookingSheet: Bool
    let destination: Destination
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("À partir de")
                        .font(.caption)
                        .foregroundColor(.gray)
                    if let promo = destination.promo, promo < 1 {
                        Text("\(Int(destination.price!))€")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                            .strikethrough()
                        Text("\(Int(destination.price!*promo))€")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    } else {
                        Text("\(Int(destination.price!))€")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
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
    @State private var numberOfChamber = 1
    @State private var isProcessing = false
    @State private var showingStripePayment = false
    @State private var createdReservation: Reservation?
    @State private var errorMessage: String?
    
    private var pricePerChamber: Int { Int(destination.price ?? 799) * numberOfDays }
    private var totalPrice: Int { pricePerChamber * numberOfChamber }

    private var numberOfDays: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: selectedStartDate)
        let end = calendar.startOfDay(for: selectedEndDate)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Section du calendrier de disponibilité
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Sélectionnez vos dates")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        AvailabilityCalendarView(
                            destinationId: destination.id,
                            selectedStartDate: $selectedStartDate,
                            selectedEndDate: $selectedEndDate
                        )
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                    }
                    
                    // Dates sélectionnées
                    if selectedStartDate != selectedEndDate {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Dates sélectionnées")
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Date de départ")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(formatDate(selectedStartDate))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Date de retour")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(formatDate(selectedEndDate))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Section voyageurs
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Voyageurs")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Nombre de chambres")
                                    .font(.subheadline)
                                Text("\(numberOfChamber) chambre\(numberOfChamber > 1 ? "s" : "")")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 15) {
                                Button(action: {
                                    if numberOfChamber > 1 {
                                        numberOfChamber -= 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(numberOfChamber > 1 ? .blue : .gray)
                                }
                                .disabled(numberOfChamber <= 1)
                                
                                Text("\(numberOfChamber)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .frame(minWidth: 30)
                                
                                Button(action: {
                                    if numberOfChamber < 10 {
                                        numberOfChamber += 1
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(numberOfChamber < 10 ? .blue : .gray)
                                }
                                .disabled(numberOfChamber >= 10)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 3)
                        .padding(.horizontal)
                    }
                    
                    // Récapitulatif des prix
                    if numberOfDays > 0 {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Récapitulatif")
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            VStack(spacing: 10) {
                                HStack {
                                    Text("Prix par chambre (\(numberOfDays) nuit\(numberOfDays > 1 ? "s" : ""))")
                                    Spacer()
                                    Text("\(pricePerChamber)€")
                                }
                                
                                HStack {
                                    Text("\(numberOfChamber) chambre\(numberOfChamber > 1 ? "s" : "")")
                                    Spacer()
                                    Text("x \(numberOfChamber)")
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Total")
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("\(totalPrice)€")
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 3)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Message d'erreur
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    // Bouton de réservation
                    Button(action: {
                        Task {
                            await createReservation()
                        }
                    }) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Création de la réservation...")
                            } else {
                                Text("Procéder au paiement")
                                    .fontWeight(.medium)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(isProcessing || numberOfDays <= 0 ? Color.gray : Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(isProcessing || numberOfDays <= 0)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
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
            numberOfChamber: numberOfChamber,
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
                numberOfChamber: numberOfChamber,
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
