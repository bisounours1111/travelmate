import Foundation
import Supabase

@MainActor
class AuthService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: AuthUser?

    private let supabase = SupabaseConfig.client

    init() {
        Task {
            await checkAuthStatus()
        }
    }

    func checkAuthStatus() async {
        if let user = try? await supabase.auth.session.user {
            self.isAuthenticated = true
            await setUserConnected()
        } else {
            try? await signOut()
        }
    }

    func signIn(email: String, password: String) async -> String {
        let session = try? await supabase.auth.signIn(email: email, password: password)
        if let user = session?.user {
            await setUserConnected()

            return ""
        }
        return "Connexion échouée"
    }

    func signUp(email: String, password: String, firstName: String, lastName: String, age: String) async -> String {
        let session = try? await supabase.auth.signUp(email: email, password: password)
        
        try? await signOut()
        
        if let user = session?.user {
            do {
                let response = try await supabase
                    .from("user")
                    .insert([
                        "id_auth": user.id.uuidString,
                        "email": email,
                        "first_name": firstName,
                        "last_name": lastName,
                        "age": age,
                        "role": "User"
                    ])
                    .execute()
                await setUserConnected()
                print("Réponse Supabase: \(response)")
            } catch {
                print("Erreur Supabase: \(error)")
                return "Erreur lors de l'enregistrement de l'utilisateur"
            }

            return ""
        }
        return "Inscription échouée"
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        self.isAuthenticated = false
        self.currentUser = nil
    }

    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }

    func setUserConnected() async {
        if let user = try? await supabase.auth.session.user {
            self.isAuthenticated = true
            let baseUser = AuthUser(
                id: user.id.uuidString,
                email: user.email ?? "unknown",
                createdAt: Date.now.ISO8601Format(),
                updatedAt: Date.now.ISO8601Format(),
                firstName: "",
                lastName: "",
                age: 0,
                preferences: [],
                role: ""
            )
            do {
                print("Base user: \(baseUser)")
                let response = try await supabase
                    .from("user")
                    .select()
                    .eq("id_auth", value: baseUser.id)
                    .single()
                    .execute()
                print("Raw response data: \(response.data)")
                if let data = response.data as? Data {
                    if let userData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("User data: \(userData)")
                        let fullUser = AuthUser(
                            id: baseUser.id,
                            email: baseUser.email,
                            createdAt: baseUser.createdAt,
                            updatedAt: baseUser.updatedAt,
                            firstName: userData["first_name"] as? String ?? "",
                            lastName: userData["last_name"] as? String ?? "",
                            age: userData["age"] as? Int ?? 0,
                            preferences: userData["preferences"] as? [String] ?? [],
                            role: userData["role"] as? String ?? ""
                        )
                        print("Full user: \(fullUser)")
                        self.currentUser = fullUser
                    } else {
                        print("No user data found")
                        self.currentUser = baseUser
                    }
                }
            } catch {
                print("Erreur lors de la récupération du profil utilisateur : \(error)")
                self.currentUser = baseUser
            }
        }
    }
}
