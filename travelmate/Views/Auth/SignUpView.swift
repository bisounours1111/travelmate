import SwiftUI
/*
CREATE TABLE "user" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_auth UUID NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    age INT CHECK (age >= 0),
    preference JSONB,
    is_admin BOOLEAN DEFAULT FALSE,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT fk_id_auth FOREIGN KEY (id_auth) REFERENCES auth.users(id) -- Adjust auth table name if different
);
*/

struct SignUpView: View {
    @State var firstName: String = "";
    @State var lastName: String = "";
    @State var age: String = "";
    @State var email: String = "";
    @State var password: String = "";
    @State var confirmPassword: String = "";
    @State var isPasswordVisible: Bool = false;
    @State var isConfirmPasswordVisible: Bool = false;

    @EnvironmentObject var authService: AuthService
    @State var isLoading: Bool = false;
    @State var errorMessage: String = "";
    @State private var shouldNavigate = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Text("Inscription")
                .bold()
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 78)

            
            TextInput(value: $email, isPasswordVisible: .constant(true), isPasswordField: false, placeholder: "Entrez votre email")
            
            TextInput(value: $firstName, isPasswordVisible: .constant(true), isPasswordField: false, placeholder: "Prénom")

            TextInput(value: $lastName, isPasswordVisible: .constant(true), isPasswordField: false, placeholder: "Nom")

            TextInput(value: $age, isPasswordVisible: .constant(true), isPasswordField: false, placeholder: "Âge")
            
            TextInput(value: $password, isPasswordVisible: $isPasswordVisible, isPasswordField: true, placeholder: "Mot de passe")
            
            TextInput(value: $confirmPassword, isPasswordVisible: $isConfirmPasswordVisible, isPasswordField: true, placeholder: "Confirmer le mot de passe")

            if errorMessage != "" {
                ErrorBanner(message: errorMessage)
            }

            VStack {
                Button(action: {
                    Task {
                        do {
                            isLoading = true
                            if password == confirmPassword {
                                let result = try await authService.signUp(email: email, password: password, firstName: firstName, lastName: lastName, age: age)
                                print("result: \(result)")
                                if result == "" {
                                    shouldNavigate = true
                                }
                                errorMessage = result
                                isLoading = false
                            } else {
                                errorMessage = "Les mots de passe ne correspondent pas"
                                isLoading = false
                            }
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
                        ButtonLabel(isDisabled: false, label: "S'inscrire")
                    }
                }
            }.padding(.vertical, 18)

            Text("Vous avez déjà un compte ?").padding(.vertical, 18)
            
            NavigationLink(destination: SignInView()) {
                VStack {
                    Text("SE CONNECTER")
                        .tracking(4)
                        .foregroundColor(Color("green"))
                        .padding(.bottom, 2)
                    
                    Rectangle()
                        .frame(width: 26, height: 1)
                        .foregroundColor(Color("green"))
                }
            }

            NavigationLink(destination: SignInView(showConfirmationNotice: true), isActive: $shouldNavigate) {
                EmptyView()
            }

        }
        .ignoresSafeArea()
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden()
        .navigationBarHidden(true)
        .background(Color(.secondarySystemBackground))
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
