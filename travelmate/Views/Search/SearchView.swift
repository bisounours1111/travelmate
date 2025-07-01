import SwiftUI

struct SearchView: View {
    @EnvironmentObject var favoriteService: FavoriteService
    @EnvironmentObject var searchViewModel: SearchViewModel
    @EnvironmentObject var destinationService: DestinationService
    @StateObject private var reservationService = ReservationService()
    @StateObject private var categoryService = CategoryService()
    
    let durees = [0, 3, 7, 14, 21, 30] // 0 = toutes durées
    
    var minPrice: Double {
        destinationService.destinations.compactMap { $0.price! * Double(searchViewModel.selectedDuration) }.min() ?? 0
        
    }
    var maxPrice: Double {
        destinationService.destinations.compactMap { $0.price! * Double(searchViewModel.selectedDuration) }.max() ?? 0
    }
    var sliderRange: ClosedRange<Double> {
        minPrice < maxPrice ? minPrice...maxPrice : minPrice...(minPrice+1)
    }
    var sliderDisabled: Bool {
        minPrice >= maxPrice
    }
    
    var body: some View {
        VStack {
            // Filtres avancés
            VStack(spacing: 12) {
                // Recherche textuelle
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    TextField("Rechercher une destination...", text: $searchViewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Budget max
                VStack(alignment: .leading) {
                    Text("Budget max : \(Int(searchViewModel.selectedBudget))€ (min: \(Int(minPrice))€, max: \(Int(maxPrice))€)")
                    Slider(value: $searchViewModel.selectedBudget, in: sliderRange, step: 1)
                        .disabled(sliderDisabled)
                }
                
                // Durée & Catégorie côte à côte
                HStack(spacing: 16) {
                    Picker("Durée", selection: $searchViewModel.selectedDuration) {
                        Text("Temps de séjour").tag(0)
                        ForEach(durees.filter { $0 != 0 }, id: \.self) { days in
                            Text("\(days) jours").tag(days)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity)

                    Picker("Catégorie", selection: $searchViewModel.selectedCategory) {
                        Text("Type de logement").tag(Category?.none)
                        ForEach(categoryService.categories) { category in
                            Text(category.name).tag(Category?.some(category))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity)
                }
                
                // Date de départ
                DatePicker("Date de départ", selection: $searchViewModel.selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                
                // Offres spéciales
                Toggle(isOn: $searchViewModel.showPromoOnly) {
                    Label("Offres spéciales uniquement", systemImage: "tag.fill")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
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
            } else {
                let results = searchViewModel.filteredDestinations(destinationService.destinations)
                if results.isEmpty {
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
                            ForEach(results) { destination in
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
                await searchViewModel.updateAvailableDestinations(
                    destinations: destinationService.destinations,
                    reservationService: reservationService
                )
            }
        }
        .onChange(of: searchViewModel.selectedDate) { _ in
            Task {
                await searchViewModel.updateAvailableDestinations(
                    destinations: destinationService.destinations,
                    reservationService: reservationService
                )
            }
        }
        .onChange(of: searchViewModel.selectedDuration) { _ in
            Task {
                await searchViewModel.updateAvailableDestinations(
                    destinations: destinationService.destinations,
                    reservationService: reservationService
                )
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
    @EnvironmentObject var searchViewModel: SearchViewModel
    @State private var favoriteCount = 0
    
    var totalPrice: Double {
        (destination.price ?? 0) * Double(searchViewModel.selectedDuration)
    }
    
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
                    Text("Prix total pour \(searchViewModel.selectedDuration) jour(s) :")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(Int(totalPrice))€")
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
