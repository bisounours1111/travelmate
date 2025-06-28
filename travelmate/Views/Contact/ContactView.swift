import SwiftUI

struct ContactView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var subject = ""
    @State private var message = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // En-tête
                    ContactHeaderView()
                    
                    // Formulaire de contact
                    ContactFormView(
                        name: $name,
                        email: $email,
                        subject: $subject,
                        message: $message,
                        showingAlert: $showingAlert
                    )
                    
                    // Informations de contact
                    ContactInfoView()
                    
                    // Réseaux sociaux
                    SocialMediaView()
                }
                .padding()
            }
            .navigationTitle("Contact")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView()
                }
            }
            .alert("Message envoyé", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Nous vous répondrons dans les plus brefs délais.")
            }
        }
    }
}

struct ContactHeaderView: View {
    var body: some View {
        VStack(spacing: 15) {
            Text("Contactez-nous")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Nous sommes là pour vous aider")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

struct ContactFormView: View {
    @Binding var name: String
    @Binding var email: String
    @Binding var subject: String
    @Binding var message: String
    @Binding var showingAlert: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Formulaire de contact")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                TextField("Votre nom", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Votre email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                TextField("Sujet", text: $subject)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextEditor(text: $message)
                    .frame(height: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            Button(action: {
                // Validation et envoi du formulaire
                showingAlert = true
            }) {
                Text("Envoyer")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct ContactInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Informations de contact")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                ContactInfoItem(
                    icon: "location.fill",
                    title: "Adresse",
                    content: "123 Rue du Voyage\n75001 Paris, France"
                )
                
                ContactInfoItem(
                    icon: "phone.fill",
                    title: "Téléphone",
                    content: "+33 1 23 45 67 89"
                )
                
                ContactInfoItem(
                    icon: "envelope.fill",
                    title: "Email",
                    content: "contact@travelmate.com"
                )
                
                ContactInfoItem(
                    icon: "clock.fill",
                    title: "Horaires",
                    content: "Lundi - Vendredi: 9h - 18h\nSamedi: 10h - 16h"
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct ContactInfoItem: View {
    let icon: String
    let title: String
    let content: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct SocialMediaView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Suivez-nous")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                SocialMediaButton(icon: "facebook", color: .blue)
                SocialMediaButton(icon: "twitter", color: .blue)
                SocialMediaButton(icon: "instagram", color: .purple)
                SocialMediaButton(icon: "linkedin", color: .blue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct SocialMediaButton: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: "\(icon).fill")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .clipShape(Circle())
        }
    }
}

#Preview {
    ContactView()
} 