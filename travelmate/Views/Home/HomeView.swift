import SwiftUI

struct HomeView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var destinationService = DestinationService()
    @StateObject private var favoriteService = FavoriteService()
    
    var body: some View {
        NavigationStack {
            TabView {
                HomeContentView()
                    .environmentObject(favoriteService)
                    .tabItem {
                        Label("Accueil", systemImage: "house.fill")
                    }
                
                SearchView()
                    .environmentObject(favoriteService)
                    .tabItem {
                        Label("Rechercher", systemImage: "magnifyingglass")
                    }
                
                DestinationsView()
                    .environmentObject(favoriteService)
                    .tabItem {
                        Label("Destinations", systemImage: "map.fill")
                    }
                
                ProfileView()
                    .environmentObject(favoriteService)
                    .tabItem {
                        Label("Profil", systemImage: "person.fill")
                    }
            }
        }
        .navigationBarHidden(true)
        .environmentObject(authService)
        .environmentObject(favoriteService)
        .onAppear {
            Task {
                await destinationService.fetchDestinations()
                if let currentUser = authService.currentUser {
                    await favoriteService.forceRefreshFavorites(for: currentUser.id)
                }
            }
        }
    }
}

struct HomeContentView: View {
    @StateObject private var destinationService = DestinationService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // En-tête avec recherche
                HomeSearchBarView()
                
                // Destinations populaires
                PopularDestinationsView(destinations: destinationService.destinations)
                
                // Catégories de voyage
                TravelCategoriesView()
                
                // Offres spéciales
                SpecialOffersView()
            }
            .padding()
        }
        .navigationTitle("TravelMate")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EmptyView()
            }
        }
    }
}

struct HomeSearchBarView: View {
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(.systemGray6))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all, edges: .top)
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Où souhaitez-vous aller ?", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}

struct PopularDestinationsView: View {
    let destinations: [Destination]
    @EnvironmentObject var favoriteService: FavoriteService
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Destinations populaires")
                .font(.title2)
                .fontWeight(.bold)
            
            if destinations.isEmpty {
                Text("Chargement des destinations...")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(Array(destinations.prefix(5))) { destination in
                            NavigationLink(destination: DestinationDetailView(destination: destination)
                                .environmentObject(favoriteService)) {
                                DestinationCardView(destination: destination)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }
}

struct DestinationCardView: View {
    let destination: Destination
    @EnvironmentObject var favoriteService: FavoriteService
    @EnvironmentObject var authService: AuthService
    @State private var favoriteCount = 0
    
    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                if !destination.imageURL.isEmpty {
                    AsyncImage(url: URL(string: destination.imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 150)
                            .clipped()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 200, height: 150)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    }
                    .cornerRadius(10)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 150)
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
                                .padding(6)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        
                        // Compteur de favoris
                        Text("\(favoriteCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(6)
                    }
                    .padding(6)
                }
            }
            
            Text(destination.title)
                .font(.headline)
                .lineLimit(1)
            
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
        .onAppear {
            if let currentUser = authService.currentUser {
                Task {
                    favoriteCount = await favoriteService.getFavoriteCount(for: destination.id)
                }
            }
        }
    }
}

struct TravelCategoriesView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Catégories de voyage")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(0..<4) { _ in
                    CategoryCardView()
                }
            }
        }
    }
}

struct CategoryCardView: View {
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.2))
                .frame(height: 100)
                .overlay(
                    Text("Catégorie")
                        .foregroundColor(.blue)
                )
        }
    }
}

struct SpecialOffersView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Offres spéciales")
                .font(.title2)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(0..<3) { _ in
                        OfferCardView()
                    }
                }
            }
        }
    }
}

struct OfferCardView: View {
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.red.opacity(0.2))
                .frame(width: 250, height: 150)
                .overlay(
                    Text("Offre spéciale")
                        .foregroundColor(.red)
                )
        }
    }
}

#Preview {
    HomeView()
} 