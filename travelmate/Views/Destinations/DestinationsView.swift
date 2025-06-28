import SwiftUI
import MapKit

struct DestinationsView: View {
    @State private var selectedTab = 0
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    )

    @State private var authService: AuthService = AuthService()
    @StateObject private var destinationService = DestinationService()

    var body: some View {
        VStack {
            // Sélecteur d'onglets
            Picker("Vue", selection: $selectedTab) {
                Text("Carte").tag(0)
                Text("Liste").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if destinationService.isLoading {
                Spacer()
                ProgressView("Chargement des destinations...")
                Spacer()
            } else if let errorMessage = destinationService.errorMessage {
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
            } else if destinationService.destinations.isEmpty {
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
            } else {
                if selectedTab == 0 {
                    // Vue carte
                    Map(coordinateRegion: $region, annotationItems: destinationService.destinations) { destination in
                        MapAnnotation(coordinate: CLLocationCoordinate2D(
                            latitude: destination.lat,
                            longitude: destination.long
                        )) {
                            DestinationMapMarker(destination: destination)
                        }
                    }
                } else {
                    // Vue liste
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(destinationService.destinations) { destination in
                                NavigationLink(destination: DestinationDetailView(destination: destination)) {
                                    DestinationListItem(destination: destination)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
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
    }
}

struct DestinationMapMarker: View {
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: DestinationDetailView(destination: destination)) {
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
    @StateObject private var favoriteService = FavoriteService()
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
                // Image de la destination
                if !destination.imageURL.isEmpty {
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
                            Text(destination.title)
                                .foregroundColor(.gray)
                        )
                }
                
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
                            .foregroundColor(favoriteService.isFavorite(userId: currentUser.id, destinationId: destination.id) ? .red : .white)
                            .font(.title2)
                            .padding(8)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
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
                    Text("\(Int(destination.price ?? 799))€")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
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
                    await favoriteService.fetchFavorites(for: currentUser.id)
                }
            }
        }
    }
}

#Preview {
    DestinationsView()
} 