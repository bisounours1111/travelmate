import SwiftUI

struct HomeView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var destinationService = DestinationService()
    
    var body: some View {
        NavigationStack {
            TabView {
                HomeContentView()
                    .tabItem {
                        Label("Accueil", systemImage: "house.fill")
                    }
                
                SearchView()
                    .tabItem {
                        Label("Rechercher", systemImage: "magnifyingglass")
                    }
                
                DestinationsView()
                    .tabItem {
                        Label("Destinations", systemImage: "map.fill")
                    }
                
                ProfileView()
                    .tabItem {
                        Label("Profil", systemImage: "person.fill")
                    }
            }
        }
        .navigationBarHidden(true)
        .environmentObject(authService)
        .onAppear {
            Task {
                await destinationService.fetchDestinations()
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
                            NavigationLink(destination: DestinationDetailView(destination: destination)) {
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
    
    var body: some View {
        VStack {
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
            
            Text(destination.title)
                .font(.headline)
                .lineLimit(1)
            
            Text("À partir de \(Int.random(in: 500...2000))€")
                .font(.subheadline)
                .foregroundColor(.gray)
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