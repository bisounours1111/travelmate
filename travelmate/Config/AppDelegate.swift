import UIKit
import Stripe

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configuration Stripe - Assurez-vous que cette clé correspond à votre compte Stripe
        StripeAPI.defaultPublishableKey = "pk_test_51ReySuFMFs1dsPI2CShuVgACTBDdGXlQfZK9QjzNfFFmXZrDe7qslaK38Su9qNrWXETGKc0zzk1qdJpDRSQd6eyh0080sH3Q6Z"
        
        // Configuration supplémentaire pour le débogage
        #if DEBUG
        StripeAPI.advancedFraudSignalsEnabled = false
        #endif
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
    }
}
