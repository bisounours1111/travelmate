import SwiftUI

struct ImageCarousel: View {
    let imageURLs: [String]
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if imageURLs.isEmpty {
                    // Placeholder si pas d'images
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                                Text("Aucune image")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                } else {
                    // Carrousel d'images
                    HStack(spacing: 0) {
                        ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, imageURL in
                            AsyncImage(url: URL(string: imageURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .clipped()
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 0)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(1.5)
                                    )
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                    .offset(x: -CGFloat(currentIndex) * geometry.size.width + dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                let threshold = geometry.size.width * 0.25
                                if value.translation.width > threshold && currentIndex > 0 {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentIndex -= 1
                                    }
                                } else if value.translation.width < -threshold && currentIndex < imageURLs.count - 1 {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentIndex += 1
                                    }
                                }
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    dragOffset = 0
                                }
                            }
                    )
                    
                    // Indicateurs de navigation
                    VStack {
                        Spacer()
                        
                        // Indicateurs de points
                        if imageURLs.count > 1 {
                            HStack(spacing: 8) {
                                ForEach(0..<imageURLs.count, id: \.self) { index in
                                    Circle()
                                        .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                                        .frame(width: 8, height: 8)
                                        .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                                        .animation(.easeInOut(duration: 0.2), value: currentIndex)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                    
                    // Boutons de navigation
                    if imageURLs.count > 1 {
                        HStack {
                            // Bouton précédent
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentIndex = max(0, currentIndex - 1)
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            .disabled(currentIndex == 0)
                            .opacity(currentIndex > 0 ? 1.0 : 0.3)
                            .animation(.easeInOut(duration: 0.2), value: currentIndex)
                            
                            Spacer()
                            
                            // Bouton suivant
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentIndex = min(imageURLs.count - 1, currentIndex + 1)
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            .disabled(currentIndex == imageURLs.count - 1)
                            .opacity(currentIndex < imageURLs.count - 1 ? 1.0 : 0.3)
                            .animation(.easeInOut(duration: 0.2), value: currentIndex)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Compteur d'images
                    if imageURLs.count > 1 {
                        VStack {
                            HStack {
                                Spacer()
                                Text("\(currentIndex + 1)/\(imageURLs.count)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(12)
                            }
                            .padding(.top, 20)
                            .padding(.trailing, 20)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

// Extension pour la compatibilité avec l'ancien système
extension ImageCarousel {
    init(imageURL: String) {
        self.imageURLs = [imageURL]
    }
}

#Preview {
    ImageCarousel(imageURLs: [
        "https://picsum.photos/400/300?random=1",
        "https://picsum.photos/400/300?random=2",
        "https://picsum.photos/400/300?random=3"
    ])
    .frame(height: 300)
} 