import SwiftUI

class SearchViewModel: ObservableObject {
    @Published var selectedCategory: Category? = nil
}

struct HomeView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var destinationService = DestinationService()
    @StateObject private var favoriteService = FavoriteService()
    @StateObject private var searchViewModel = SearchViewModel()
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeContentView(selectedTab: $selectedTab)
                .environmentObject(favoriteService)
                .environmentObject(searchViewModel)
                .tabItem {
                    Label("Accueil", systemImage: "house.fill")
                }
                .tag(0)
            
            SearchView()
                .environmentObject(favoriteService)
                .environmentObject(searchViewModel)
                .tabItem {
                    Label("Rechercher", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            DestinationsView()
                .environmentObject(favoriteService)
                .tabItem {
                    Label("Destinations", systemImage: "map.fill")
                }
                .tag(2)
            
            ProfileView()
                .environmentObject(favoriteService)
                .tabItem {
                    Label("Profil", systemImage: "person.fill")
                }
                .tag(3)
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
    @StateObject private var categoryService = CategoryService()
    @EnvironmentObject var searchViewModel: SearchViewModel
    @Binding var selectedTab: Int
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // En-tête avec recherche
                HomeSearchBarView()
                
                // Destinations populaires
                PopularDestinationsView(destinations: destinationService.destinations)
                
                // Catégories de voyage
                TravelCategoriesView(categories: categoryService.categories, isLoading: categoryService.isLoading, selectedTab: $selectedTab)
                
                // Offres spéciales
                SpecialOffersView(destinations: destinationService.destinations)
            }
            .padding()
        }
        .navigationTitle("TravelMate")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct HomeSearchBarView: View {
    @State private var searchText = ""
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Où souhaitez-vous aller ?", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
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
                if !destination.imageURLs.isEmpty {
                    AsyncImage(url: URL(string: destination.imageURLs[0])) { image in
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
    let categories: [Category]
    let isLoading: Bool
    @Binding var selectedTab: Int
    @EnvironmentObject var searchViewModel: SearchViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Catégories de voyage")
                .font(.title2)
                .fontWeight(.bold)
            
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Chargement des catégories...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if categories.isEmpty {
                Text("Aucune catégorie disponible")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
                    ForEach(Array(categories.prefix(4))) { category in
                        Button(action: {
                            searchViewModel.selectedCategory = category
                            selectedTab = 1 // Ouvre l'onglet Recherche
                        }) {
                            CategoryCardView(category: category)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

struct CategoryCardView: View {
    let category: Category
    
    var body: some View {
        ZStack {
            // Image de fond depuis le bucket Supabase

            if let imagePath = category.imagePath, !imagePath.isEmpty {
                let fullURL = "https://etzdkvwucgaznmolqdyj.supabase.co/storage/v1/object/public/products/\(imagePath)"
                AsyncImage(url: URL(string: fullURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 160, height: 120)
                        .clipped()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(category.categoryColor).opacity(0.2))
                        .frame(width: 160, height: 120)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(category.categoryColor).opacity(0.2))
                    .frame(width: 160, height: 120)
            }
            
            // Overlay avec icône et texte
            VStack(spacing: 8) {
                Text(category.name)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(radius: 2)
                    .padding(.top, 10)
            }
            .padding(8)
        }
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}

struct SpecialOffersView: View {
    let destinations: [Destination]
    @EnvironmentObject var favoriteService: FavoriteService
    
    var specialOffers: [Destination] {
        destinations.filter { ($0.promo ?? 1) < 1 }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Offres spéciales")
                .font(.title2)
                .fontWeight(.bold)
            
            if specialOffers.isEmpty {
                Text("Aucune offre spéciale en ce moment")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(specialOffers) { destination in
                            NavigationLink(destination: DestinationDetailView(destination: destination)
                                .environmentObject(favoriteService)) {
                                SpecialOfferCardView(destination: destination)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }
}

struct SpecialOfferCardView: View {
    let destination: Destination
    
    var originalPrice: Double {
        destination.price ?? 799
    }
    var promo: Double {
        destination.promo ?? 1
    }
    var discountedPrice: Double {
        (destination.price ?? 799) * (destination.promo ?? 1)
    }
    var discountPercent: Int {
        Int((1 - (destination.promo ?? 1)) * 100)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image de la destination
            if !destination.imageURLs.isEmpty {
                AsyncImage(url: URL(string: destination.imageURLs[0])) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 250, height: 150)
                        .clipped()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 250, height: 150)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
                .cornerRadius(10)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 250, height: 150)
                    .overlay(
                        Text(destination.title)
                            .foregroundColor(.gray)
                    )
            }
            
            Text(destination.title)
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(1)
            
            HStack(spacing: 8) {
                Text("\(Int(originalPrice))€")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .strikethrough()
                Text("\(Int(discountedPrice))€")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                if discountPercent > 0 {
                    Text("-\(discountPercent)%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
    }
}

#Preview {
    HomeView()
} 