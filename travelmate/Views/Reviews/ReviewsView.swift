import SwiftUI

struct ReviewsView: View {
    let destination: Destination
    @StateObject private var reviewService = ReviewService()
    @EnvironmentObject var authService: AuthService
    @State private var showingAddReview = false
    @State private var reviewStats: ReviewStats?
    
    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                // Header résumé
                ReviewsHeaderView(
                    reviewStats: reviewStats,
                    onAddReview: {
                        showingAddReview = true
                    }
                )
                .padding()
                .background(Color.white)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
                .padding(.top, 10)

                // Liste scrollable des avis
                if reviewService.isLoading {
                    ProgressView("Chargement des avis...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if reviewService.reviews.isEmpty {
                    ScrollView {
                        EmptyReviewsView()
                            .padding(.top, 60)
                    }
                } else {
                    ScrollView {
                        ReviewsListView(reviews: reviewService.reviews)
                            .padding(.top, 10)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: 400)
                }
                Spacer()
            }
        }
        .navigationTitle("Avis")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadReviews()
        }
        .sheet(isPresented: $showingAddReview) {
            AddReviewView(
                destination: destination,
                reviewService: reviewService,
                onReviewAdded: {
                    loadReviews()
                }
            )
        }
        .alert("Erreur", isPresented: .constant(reviewService.errorMessage != nil)) {
            Button("OK") {
                reviewService.errorMessage = nil
            }
        } message: {
            Text(reviewService.errorMessage ?? "")
        }
    }
    
    private func loadReviews() {
        Task {
            await reviewService.fetchReviews(for: destination.id)
            reviewStats = await reviewService.getReviewStats(for: destination.id)
        }
    }
}

struct ReviewsHeaderView: View {
    let reviewStats: ReviewStats?
    let onAddReview: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(String(format: "%.1f", reviewStats?.averageRating ?? 0.0))
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= Int(reviewStats?.averageRating ?? 0.0) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    Text("\(reviewStats?.reviewCount ?? 0) avis")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onAddReview) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Ajouter un avis")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            // Distribution des notes
            if let stats = reviewStats, stats.reviewCount > 0 {
                RatingDistributionView(ratingDistribution: stats.ratingDistribution)
            }
            
            Divider()
        }
    }
}

struct RatingDistributionView: View {
    let ratingDistribution: [String: Int]
    let totalReviews: Int
    
    init(ratingDistribution: [String: Int]) {
        self.ratingDistribution = ratingDistribution
        self.totalReviews = ratingDistribution.values.reduce(0, +)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach((1...5).reversed(), id: \.self) { rating in
                HStack {
                    Text("\(rating)")
                        .font(.caption)
                        .frame(width: 12)
                    
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                    
                    ProgressView(value: Double(ratingDistribution[String(rating)] ?? 0), total: Double(totalReviews))
                        .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
                        .frame(height: 6)
                    
                    Text("\(ratingDistribution[String(rating)] ?? 0)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .frame(width: 20, alignment: .trailing)
                }
            }
        }
    }
}

struct ReviewsListView: View {
    let reviews: [Review]
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(reviews) { review in
                ReviewCardView(review: review)
            }
        }
    }
}

struct ReviewCardView: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(review.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= review.rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
                
                Text(review.formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if let comment = review.comment, !comment.isEmpty {
                Text(comment)
                    .font(.body)
                    .lineLimit(nil)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct EmptyReviewsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("Aucun avis pour le moment")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Soyez le premier à donner votre avis sur cette destination !")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AddReviewView: View {
    let destination: Destination
    let reviewService: ReviewService
    let onReviewAdded: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var rating: Int = 5
    @State private var comment: String = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // En-tête
                VStack(spacing: 8) {
                    Text("Votre avis sur")
                        .font(.headline)
                    
                    Text(destination.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                
                // Système de notation
                VStack(spacing: 12) {
                    Text("Note")
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                rating = star
                            }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.title)
                                    .foregroundColor(star <= rating ? .yellow : .gray)
                            }
                        }
                    }
                }
                
                // Commentaire
                VStack(alignment: .leading, spacing: 8) {
                    Text("Commentaire (optionnel)")
                        .font(.headline)
                    
                    TextEditor(text: $comment)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.white))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // Bouton de soumission
                Button(action: submitReview) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Publier l'avis")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isLoading)
            }
            .padding()
            .navigationTitle("Nouvel avis")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Annuler") {
                    dismiss()
                }
            )
        }
    }
    
    private func submitReview() {
        guard let currentUser = authService.currentUser else { return }
        
        isLoading = true
        
        Task {
            let success = await reviewService.createReview(
                userId: currentUser.id,
                destinationId: destination.id,
                rating: rating,
                comment: comment.isEmpty ? nil : comment
            )
            
            await MainActor.run {
                isLoading = false
                if success {
                    onReviewAdded()
                    dismiss()
                }
            }
        }
    }
}
