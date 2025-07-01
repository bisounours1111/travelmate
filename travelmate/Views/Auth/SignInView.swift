import SwiftUI

struct SignInView: View {
    @State var email: String = "";
    @State var password: String = "";
    @State var isPasswordVisible: Bool = false;
    @EnvironmentObject var authService: AuthService

    @State var isLoading: Bool = false;
    @State var errorMessage: String = "";
    @State private var shouldNavigate = false
    
    var showConfirmationNotice: Bool = false
    @State private var showBanner: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                if showConfirmationNotice || showBanner {
                    HStack {
                        Image(systemName: "envelope.badge")
                            .foregroundColor(.white)
                        Text("Veuillez confirmer votre adresse e-mail avant de vous connecter.")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(8)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }
                
                Text("Connexion")
                    .bold()
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 78)
                
                TextInput(value: $email, isPasswordVisible: .constant(true), isPasswordField: false, placeholder: "Entrez votre email")
                
                TextInput(value: $password, isPasswordVisible: $isPasswordVisible, isPasswordField: true, placeholder: "Mot de passe")
                
                if errorMessage != "" {
                    ErrorBanner(message: errorMessage)
                }
                
                VStack {
                    Button(action: {
                        Task {
                            do {
                                isLoading = true
                                let result = try await authService.signIn(email: email, password: password)
                                print("result: \(result)")
                                if result == "" {
                                    shouldNavigate = true
                                }
                                errorMessage = result
                                isLoading = false
                            } catch {
                                isLoading = false
                            }
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color("green")))
                                .frame(width: 20, height: 20)
                        } else {
                            ButtonLabel(isDisabled: false, label: "Se connecter")
                        }
                    }
                }.padding(.vertical, 18)

                Text("Vous n'avez pas de compte ?").padding(.vertical, 18)
                
                NavigationLink(destination: SignUpView()) {
                    VStack {
                        Text("S'INSCRIRE")
                            .tracking(4)
                            .foregroundColor(Color("green"))
                            .padding(.bottom, 2)
                        
                        Rectangle()
                            .frame(width: 26, height: 1)
                            .foregroundColor(Color("green"))
                    }
                }
                NavigationLink(destination: HomeView(), isActive: $shouldNavigate) {
                    EmptyView()
                }
            }
        }
        .ignoresSafeArea()
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden()
        .navigationBarHidden(true)
        .background(Color(.secondarySystemBackground))
        .onAppear {
            if showConfirmationNotice {
                showBanner = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    showBanner = false
                }
            }
            if authService.isAuthenticated {
                shouldNavigate = true
            }
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(showConfirmationNotice: true)
            .environmentObject(AuthService())
    }
}

struct SocialButton: View {
    var label: String;
    var color: Color;
    
    var body: some View {
        Text(label)
            .frame(width: UIScreen.main.bounds.width * 0.41, height: 51)
            .background(color.opacity(0.25))
            .foregroundColor(color)
            .cornerRadius(5)
            .bold()
            .tracking(2)
    }
}

