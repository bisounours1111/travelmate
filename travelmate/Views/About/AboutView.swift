import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // En-tête
                    AboutHeaderView()
                    
                    // Notre mission
                    MissionView()
                    
                    // Notre équipe
                    TeamView()
                    
                    // Nos engagements
                    CommitmentsView()
                    
                    // Statistiques
                    StatsView()
                }
                .padding()
            }
            .navigationTitle("À propos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView()
                }
            }
        }
    }
}

struct AboutHeaderView: View {
    var body: some View {
        VStack(spacing: 15) {
            // Logo
            Image(systemName: "airplane.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("TravelMate")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Votre compagnon de voyage idéal")
                .font(.title3)
                .foregroundColor(.gray)
        }
    }
}

struct MissionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Notre Mission")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Chez TravelMate, nous croyons que chaque voyage devrait être une expérience unique et mémorable. Notre mission est de rendre le voyage accessible à tous, tout en respectant l'environnement et les communautés locales.")
                .font(.body)
                .foregroundColor(.gray)
            
            Text("Nous nous engageons à :")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                MissionItem(icon: "globe", text: "Promouvoir le tourisme responsable")
                MissionItem(icon: "leaf", text: "Réduire notre impact environnemental")
                MissionItem(icon: "hand.raised", text: "Soutenir les communautés locales")
                MissionItem(icon: "heart", text: "Offrir des expériences authentiques")
            }
        }
    }
}

struct MissionItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
                .foregroundColor(.gray)
        }
    }
}

struct TeamView: View {
    let teamMembers = [
        ("Jean Dupont", "Fondateur & CEO", "jean.dupont@travelmate.com"),
        ("Marie Martin", "Directrice des opérations", "marie.martin@travelmate.com"),
        ("Pierre Durand", "Responsable développement", "pierre.durand@travelmate.com"),
        ("Sophie Bernard", "Responsable marketing", "sophie.bernard@travelmate.com")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Notre Équipe")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Une équipe passionnée par le voyage et le service client")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ForEach(teamMembers, id: \.0) { member in
                TeamMemberCard(name: member.0, role: member.1, email: member.2)
            }
        }
    }
}

struct TeamMemberCard: View {
    let name: String
    let role: String
    let email: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(name)
                    .font(.headline)
                
                Text(role)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(email)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct CommitmentsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Nos Engagements")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 20) {
                CommitmentCard(
                    title: "Écoresponsabilité",
                    description: "Nous nous engageons à réduire notre empreinte carbone et à promouvoir des pratiques durables.",
                    icon: "leaf.fill"
                )
                
                CommitmentCard(
                    title: "Sécurité",
                    description: "La sécurité de nos voyageurs est notre priorité absolue.",
                    icon: "shield.fill"
                )
                
                CommitmentCard(
                    title: "Qualité",
                    description: "Nous sélectionnons rigoureusement nos partenaires pour garantir la meilleure qualité de service.",
                    icon: "star.fill"
                )
                
                CommitmentCard(
                    title: "Innovation",
                    description: "Nous développons constamment de nouvelles fonctionnalités pour améliorer votre expérience.",
                    icon: "lightbulb.fill"
                )
            }
        }
    }
}

struct CommitmentCard: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct StatsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Nos Chiffres")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                StatCard(value: "50K+", label: "Voyageurs")
                StatCard(value: "100+", label: "Destinations")
                StatCard(value: "4.8/5", label: "Satisfaction")
                StatCard(value: "24/7", label: "Support")
            }
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 10) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

#Preview {
    AboutView()
} 