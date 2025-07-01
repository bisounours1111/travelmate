import SwiftUI
import MapKit

// Structure pour gérer les annotations de carte
struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let marker: AnyView
}

struct DestinationsView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    )

    @EnvironmentObject var authService: AuthService
    @StateObject private var destinationService = DestinationService()
    @StateObject private var routeService = RouteService()
    @EnvironmentObject var favoriteService: FavoriteService
    
    // États pour les inputs
    @State private var startLocationText = ""
    @State private var selectedStartLocation: Address?
    @State private var selectedDestination: Destination?
    @State private var startLocationSuggestions: [Address] = []
    @State private var showStartSuggestions = false
    @State private var selectedActivityType: ActivityType = .restaurant
    
    // Timer pour la recherche retardée
    @State private var searchTimer: Timer?
    
    // Gestion du focus pour éviter que le clavier reste ouvert
    @FocusState private var isStartLocationFocused: Bool

    // Variables privées pour simplifier les expressions
    private var canSearch: Bool {
        selectedStartLocation != nil && selectedDestination != nil
    }
    
    private var hasStartSuggestions: Bool {
        showStartSuggestions && !startLocationSuggestions.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            inputSection
            mainContentSection
        }
        .navigationTitle("Destinations")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EmptyView()
            }
        }
        .refreshable {
            await destinationService.fetchDestinations()
        }
        .onTapGesture {
            showStartSuggestions = false
            isStartLocationFocused = false
        }
    }
    
    // MARK: - Sections de la vue
    
    private var inputSection: some View {
        VStack(spacing: 15) {
            startLocationInput
            destinationPicker
            activityTypePicker
            searchButton
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var startLocationInput: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Point de départ")
                .font(.headline)
                .foregroundColor(.primary)
            
            ZStack {
                TextField("Saisissez votre point de départ", text: $startLocationText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isStartLocationFocused)
                    .onChange(of: startLocationText) { newValue in
                        handleStartLocationChange(newValue)
                    }
                    .onSubmit {
                        isStartLocationFocused = false
                    }
                
                if hasStartSuggestions {
                    suggestionsList
                }
            }
        }
    }
    
    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 40)
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(startLocationSuggestions) { address in
                    suggestionButton(for: address)
                    
                    if address.id != startLocationSuggestions.last?.id {
                        Divider()
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(radius: 5)
        }
    }
    
    private func suggestionButton(for address: Address) -> some View {
        Button(action: {
            selectedStartLocation = address
            startLocationText = address.name
            showStartSuggestions = false
            isStartLocationFocused = false
        }) {
            VStack(alignment: .leading) {
                Text(address.name)
                    .font(.body)
                    .foregroundColor(.primary)
                Text(address.fullAddress)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var destinationPicker: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Destination")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("Choisissez une destination", selection: $selectedDestination) {
                Text("Sélectionnez une destination").tag(Destination?.none)
                ForEach(destinationService.destinations) { destination in
                    Text(destination.title).tag(Destination?.some(destination))
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
    
    private var activityTypePicker: some View {
        Picker("Type d'activité", selection: $selectedActivityType) {
            ForEach(ActivityType.allCases, id: \.self) { activityType in
                Text(activityType.displayName).tag(activityType)
            }
        }
        .pickerStyle(MenuPickerStyle())
    }
    
    @ViewBuilder
    private var searchButton: some View {
        if canSearch {
            Button(action: {
                Task {
                    await searchRoute()
                }
            }) {
                HStack {
                    if routeService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                    Text(routeService.isLoading ? "Recherche..." : "Rechercher l'itinéraire")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(routeService.isLoading)
        }
    }
    
    @ViewBuilder
    private var mainContentSection: some View {
        if destinationService.isLoading {
            loadingView
        } else if let errorMessage = destinationService.errorMessage {
            errorView(errorMessage)
        } else if destinationService.destinations.isEmpty {
            emptyView
        } else {
            VStack(spacing: 0) {
                mapView
                
                // Section des résultats d'itinéraire
                if let currentRoute = routeService.currentRoute {
                    routeResultsSection
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Chargement des destinations...")
            Spacer()
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack {
            Spacer()
            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text("Erreur")
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            Spacer()
        }
    }
    
    private var emptyView: some View {
        VStack {
            Spacer()
            VStack {
                Image(systemName: "map")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                Text("Aucune destination trouvée")
                    .font(.headline)
                Text("Les destinations apparaîtront ici")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
    
    private var routeResultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Activités trouvées")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(routeService.currentRoute?.activities.count ?? 0)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            if let activities = routeService.currentRoute?.activities, !activities.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(activities) { activity in
                            RouteActivityCard(activity: activity)
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                Text("Aucune activité trouvée sur cet itinéraire")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
    }
    
    private var mapView: some View {
        Group {
            if let currentRoute = routeService.currentRoute {
                // Mode GPS : afficher l'itinéraire avec polyline
                GPSMapView(
                    route: currentRoute,
                    startLocation: selectedStartLocation,
                    destination: selectedDestination,
                    region: $region
                )
            } else {
                // Mode normal : afficher toutes les destinations
                Map(coordinateRegion: $region, annotationItems: destinationService.destinations) { destination in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(
                        latitude: destination.lat,
                        longitude: destination.long
                    )) {
                        DestinationMapMarker(
                            destination: destination,
                            onDestinationSelected: { selectedDestination in
                                fillDestinationFromMap(selectedDestination)
                            }
                        )
                    }
                }
            }
        }
        .onChange(of: routeService.currentRoute) { newRoute in
            if let route = newRoute {
                updateMapRegion(for: route)
            }
        }
    }
    
    // MARK: - Propriétés calculées pour les annotations de carte
    
    private var allMapAnnotations: [MapAnnotationItem] {
        var annotations: [MapAnnotationItem] = []
        
        // Si un itinéraire est actif, afficher seulement les activités et les points de départ/arrivée
        if let currentRoute = routeService.currentRoute {
            // Ajouter le point de départ
            if let startLocation = selectedStartLocation {
                annotations.append(MapAnnotationItem(
                    coordinate: CLLocationCoordinate2D(latitude: startLocation.latitude, longitude: startLocation.longitude),
                    marker: AnyView(
                        StartLocationMarker(location: startLocation)
                    )
                ))
            }
            
            // Ajouter le point d'arrivée
            if let destination = selectedDestination {
                annotations.append(MapAnnotationItem(
                    coordinate: CLLocationCoordinate2D(latitude: destination.lat, longitude: destination.long),
                    marker: AnyView(
                        EndLocationMarker(destination: destination)
                    )
                ))
            }
            
            // Ajouter les activités le long de l'itinéraire
            for activity in currentRoute.activities {
                annotations.append(MapAnnotationItem(
                    coordinate: CLLocationCoordinate2D(latitude: activity.latitude, longitude: activity.longitude),
                    marker: AnyView(
                        ActivityMapMarker(activity: activity)
                    )
                ))
            }
        } else {
            // Si aucun itinéraire, afficher toutes les destinations
            for destination in destinationService.destinations {
                annotations.append(MapAnnotationItem(
                    coordinate: CLLocationCoordinate2D(latitude: destination.lat, longitude: destination.long),
                    marker: AnyView(
                        DestinationMapMarker(
                            destination: destination,
                            onDestinationSelected: { selectedDestination in
                                fillDestinationFromMap(selectedDestination)
                            }
                        )
                    )
                ))
            }
        }
        
        return annotations
    }
    
    // MARK: - Fonctions privées
    
    private func handleStartLocationChange(_ newValue: String) {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            Task {
                await searchStartAddresses(query: newValue)
            }
        }
    }
    
    private func searchStartAddresses(query: String) async {
        guard !query.isEmpty else {
            await MainActor.run {
                startLocationSuggestions = []
                showStartSuggestions = false
            }
            return
        }
        
        print("🔍 Recherche d'adresses pour: '\(query)'")
        
        let suggestions = await routeService.searchAddresses(query: query)
        
        print("📍 Suggestions trouvées: \(suggestions.count)")
        for (index, suggestion) in suggestions.enumerated() {
            print("  \(index + 1). \(suggestion.name) - (\(suggestion.latitude), \(suggestion.longitude))")
        }
        
        await MainActor.run {
            startLocationSuggestions = suggestions
            showStartSuggestions = !suggestions.isEmpty
            print("🎯 showStartSuggestions = \(showStartSuggestions), suggestions count = \(suggestions.count)")
        }
    }
    
    private func fillDestinationFromMap(_ destination: Destination) {
        selectedDestination = destination
    }
    
    private func searchRoute() async {
        guard let startLocation = selectedStartLocation,
              let destination = selectedDestination else {
            print("❌ Données manquantes pour la recherche d'itinéraire")
            return
        }
        
        print("🗺️ Recherche d'itinéraire:")
        print("  Départ: \(startLocation.name) (\(startLocation.latitude), \(startLocation.longitude))")
        print("  Arrivée: \(destination.title) (\(destination.lat), \(destination.long))")
        print("  Type d'activité: \(selectedActivityType.displayName)")
        
        let success = await routeService.getRouteWithActivities(
            startLat: startLocation.latitude,
            startLon: startLocation.longitude,
            endLat: destination.lat,
            endLon: destination.long,
            activityType: selectedActivityType
        )
        
        if success {
            print("✅ Itinéraire trouvé avec \(routeService.currentRoute?.activities.count ?? 0) activités")
            if let route = routeService.currentRoute {
                print("📏 Distance: \(route.route.legs.first?.distance.text ?? "N/A")")
                print("⏱️ Durée: \(route.route.legs.first?.duration.text ?? "N/A")")
                for (index, activity) in route.activities.enumerated() {
                    print("  \(index + 1). \(activity.name) (\(activity.latitude), \(activity.longitude))")
                }
            }
        } else {
            print("❌ Échec de la recherche d'itinéraire")
            if let error = routeService.errorMessage {
                print("📄 Erreur: \(error)")
            }
        }
    }
    
    private func updateMapRegion(for route: RouteWithActivities) {
        // Calculer les coordonnées min/max pour centrer la carte
        var allCoordinates = route.activities.map { 
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) 
        }
        
        if let startLocation = selectedStartLocation {
            allCoordinates.append(CLLocationCoordinate2D(
                latitude: startLocation.latitude, 
                longitude: startLocation.longitude
            ))
        }
        
        if let destination = selectedDestination {
            allCoordinates.append(CLLocationCoordinate2D(
                latitude: destination.lat, 
                longitude: destination.long
            ))
        }
        
        if !allCoordinates.isEmpty {
            let minLat = allCoordinates.map { $0.latitude }.min() ?? 0
            let maxLat = allCoordinates.map { $0.latitude }.max() ?? 0
            let minLon = allCoordinates.map { $0.longitude }.min() ?? 0
            let maxLon = allCoordinates.map { $0.longitude }.max() ?? 0
            
            let centerLat = (minLat + maxLat) / 2
            let centerLon = (minLon + maxLon) / 2
            let latDelta = (maxLat - minLat) * 1.5 // 50% de marge
            let lonDelta = (maxLon - minLon) * 1.5
            
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                span: MKCoordinateSpan(
                    latitudeDelta: max(latDelta, 0.01), // Minimum 0.01
                    longitudeDelta: max(lonDelta, 0.01)
                )
            )
        }
    }
}

struct DestinationMapMarker: View {
    let destination: Destination
    let onDestinationSelected: (Destination) -> Void
    @EnvironmentObject var favoriteService: FavoriteService
    
    var body: some View {
        Button(action: {
            onDestinationSelected(destination)
        }) {
            VStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.title)
                    .foregroundColor(.red)
                
                Text(destination.title)
                    .font(.caption)
                    .padding(5)
                    .background(Color.white)
                    .cornerRadius(5)
                    .shadow(radius: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DestinationListItem: View {
    let destination: Destination
    @EnvironmentObject var favoriteService: FavoriteService
    @EnvironmentObject var authService: AuthService
    @State private var favoriteCount = 0
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
                // Image de la destination
                if !destination.imageURLs.isEmpty {
                    AsyncImage(url: URL(string: destination.imageURLs[0])) { image in
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
                            Text(destination.title)
                                .foregroundColor(.gray)
                        )
                }
                
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
                                .foregroundColor(favoriteService.isFavorite(userId: currentUser.id, destinationId: destination.id) ? .red : .white)
                                .font(.title2)
                                .padding(8)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        
                        // Compteur de favoris
                        Text("\(favoriteCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                    }
                    .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(destination.title)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(destination.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
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
                    Text("4.8")
                    Text("(\(Int.random(in: 50...200)) avis)")
                        .foregroundColor(.gray)
                }
                
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
            .padding()
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
        .onAppear {
            if let currentUser = authService.currentUser {
                Task {
                    favoriteCount = await favoriteService.getFavoriteCount(for: destination.id)
                }
            }
        }
    }
}

#Preview {
    DestinationsView()
}

// MARK: - Vues pour l'affichage GPS

struct GPSMapView: View {
    let route: RouteWithActivities
    let startLocation: Address?
    let destination: Destination?
    @Binding var region: MKCoordinateRegion
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: gpsAnnotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                annotation.marker
            }
        }
        .overlay(
            // Afficher la polyline de l'itinéraire
            RoutePolylineOverlay(route: route.route)
        )
    }
    
    private var gpsAnnotations: [MapAnnotationItem] {
        var annotations: [MapAnnotationItem] = []
        
        // Point de départ
        if let startLocation = startLocation {
            annotations.append(MapAnnotationItem(
                coordinate: CLLocationCoordinate2D(latitude: startLocation.latitude, longitude: startLocation.longitude),
                marker: AnyView(StartLocationMarker(location: startLocation))
            ))
        }
        
        // Point d'arrivée
        if let destination = destination {
            annotations.append(MapAnnotationItem(
                coordinate: CLLocationCoordinate2D(latitude: destination.lat, longitude: destination.long),
                marker: AnyView(EndLocationMarker(destination: destination))
            ))
        }
        
        // Activités le long de l'itinéraire
        for activity in route.activities {
            annotations.append(MapAnnotationItem(
                coordinate: CLLocationCoordinate2D(latitude: activity.latitude, longitude: activity.longitude),
                marker: AnyView(ActivityMapMarker(activity: activity))
            ))
        }
        
        return annotations
    }
}

// Fonction utilitaire pour décoder les coordonnées de la polyline
func decodePolyline(_ encodedString: String) -> [CLLocationCoordinate2D] {
    var coordinates: [CLLocationCoordinate2D] = []
    var index = 0
    var lat = 0.0
    var lng = 0.0
    
    while index < encodedString.count {
        var shift = 0
        var result = 0
        
        repeat {
            let char = encodedString[encodedString.index(encodedString.startIndex, offsetBy: index)]
            let value = Int(char.asciiValue ?? 0) - 63
            result |= (value & 0x1F) << shift
            shift += 5
            index += 1
        } while index < encodedString.count && encodedString[encodedString.index(encodedString.startIndex, offsetBy: index - 1)].asciiValue! >= 0x20
        
        let dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
        lat += Double(dlat)
        
        shift = 0
        result = 0
        
        repeat {
            let char = encodedString[encodedString.index(encodedString.startIndex, offsetBy: index)]
            let value = Int(char.asciiValue ?? 0) - 63
            result |= (value & 0x1F) << shift
            shift += 5
            index += 1
        } while index < encodedString.count && encodedString[encodedString.index(encodedString.startIndex, offsetBy: index - 1)].asciiValue! >= 0x20
        
        let dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
        lng += Double(dlng)
        
        coordinates.append(CLLocationCoordinate2D(latitude: lat / 1e5, longitude: lng / 1e5))
    }
    
    return coordinates
}

struct StartLocationMarker: View {
    let location: Address
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "location.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
                .background(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 30, height: 30)
                        .shadow(radius: 2)
                )
            
            Text("Départ")
                .font(.caption2)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(4)
                .shadow(radius: 1)
        }
    }
}

struct EndLocationMarker: View {
    let destination: Destination
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundColor(.red)
                .background(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 30, height: 30)
                        .shadow(radius: 2)
                )
            
            Text(destination.title)
                .font(.caption2)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(4)
                .shadow(radius: 1)
                .lineLimit(1)
        }
    }
}

// MARK: - Vues pour les activités

struct ActivityMapMarker: View {
    let activity: Activity
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundColor(.orange)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(radius: 2)
            
            Text(activity.name)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 1)
        }
    }
}

struct RouteActivityCard: View {
    let activity: Activity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForActivityType(activity.type))
                    .foregroundColor(.green)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let vicinity = activity.vicinity {
                        Text(vicinity)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if let rating = activity.rating {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
            
            HStack {
                Text(activity.type.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(8)
                
                Spacer()
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
        .frame(width: 200)
    }
    
    private func iconForActivityType(_ type: String) -> String {
        switch type {
        case "restaurant": return "fork.knife"
        case "tourist_attraction": return "binoculars.fill"
        case "gas_station": return "fuelpump.fill"
        case "lodging": return "bed.double.fill"
        case "hospital": return "cross.fill"
        case "pharmacy": return "pills.fill"
        case "bank": return "building.columns.fill"
        case "atm": return "creditcard.fill"
        case "park": return "leaf.fill"
        case "museum": return "building.columns"
        case "church": return "cross.circle.fill"
        case "shopping_mall": return "bag.fill"
        case "supermarket": return "cart.fill"
        case "cafe": return "cup.and.saucer.fill"
        case "bar": return "wineglass.fill"
        default: return "mappin.circle.fill"
        }
    }
}

// MARK: - Structures pour l'affichage GPS

struct RoutePolylineOverlay: View {
    let route: RouteInfo
    
    var body: some View {
        // Pour l'instant, on utilise une approche simple
        // L'implémentation complète nécessiterait MapKit avec polyline
        EmptyView()
    }
} 
