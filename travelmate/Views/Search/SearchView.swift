import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var selectedDate = Date()
    @State private var selectedBudget: Double = 1000
    @State private var selectedDuration = 7
    @State private var selectedCategory = "Tous"
    @StateObject private var destinationService = DestinationService()
    @EnvironmentObject var favoriteService: FavoriteService
    @EnvironmentObject var searchViewModel: SearchViewModel
    @StateObject private var categoryService = CategoryService()
    
    let categories = ["Tous", "Culture", "Nature", "Plage", "Montagne", "Ville"]
    
    var filteredDestinations: [Destination] {
        if let selected = searchViewModel.selectedCategory {
            return destinationService.destinations.filter { $0.categoryId == selected.id }
        } else {
            return destinationService.destinations
        }
    }
    
    var body: some View {
        VStack {
            // Picker catégorie en haut
            Picker("Catégorie", selection: $searchViewModel.selectedCategory) {
                Text("Toutes").tag(Category?.none)
                ForEach(categoryService.categories) { category in
                    Text(category.name).tag(Category?.some(category))
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            
            // Barre de recherche
            SearchBarView(searchText: $searchText)
                .padding()
                .onChange(of: searchText) { newValue in
                    if !newValue.isEmpty {
                        Task {
                            await destinationService.searchDestinations(query: newValue)
                        }
                    } else {
                        Task {
                            await destinationService.fetchDestinations()
                        }
                    }
                }
            
            // Filtres
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    
                    VStack {
                        Text("Budget: \(Int(selectedBudget))€")
                        Slider(value: $selectedBudget, in: 100...5000, step: 100)
                    }
                    .frame(width: 200)
                    
                    Picker("Durée", selection: $selectedDuration) {
                        ForEach([3, 7, 14, 21, 30], id: \.self) { days in
                            Text("\(days) jours")
                        }
                    }
                    
                    Picker("Catégorie", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category)
                        }
                    }
                    .onChange(of: selectedCategory) { newValue in
                        if newValue != "Tous" {
                            Task {
                                await destinationService.getDestinationsByType(type: newValue)
                            }
                        } else {
                            Task {
                                await destinationService.fetchDestinations()
                            }
                        }
                    }
                }
                .padding()
            }
            
            // Résultats de recherche
            if destinationService.isLoading {
                Spacer()
                ProgressView("Recherche en cours...")
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
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Aucun résultat")
                        .font(.headline)
                    Text("Essayez de modifier vos critères de recherche")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(filteredDestinations) { destination in
                            NavigationLink(destination: DestinationDetailView(destination: destination)
                                .environmentObject(favoriteService)) {
                                SearchResultCard(destination: destination)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Rechercher")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EmptyView()
            }
        }
        .onAppear {
            Task {
                await destinationService.fetchDestinations()
                await categoryService.fetchCategories()
            }
        }
    }
}

struct SearchBarView: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Rechercher une destination...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct SearchResultCard: View {
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
                            .frame(height: 200)
                            .clipped()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    }
                    .cornerRadius(10)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
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
                
                HStack {
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
                
                HStack {
                    Text(destination.type)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
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
    SearchView()
} 