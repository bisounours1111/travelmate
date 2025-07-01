import Foundation
import CoreLocation

struct NearbyActivity: Identifiable, Decodable {
    let id = UUID()
    let name: String
    let description: String
    let category: String
    let rating: Double
    let position: Position

    struct Position: Decodable {
        let lat: Double
        let lng: Double
    }
}

class ActivityService: ObservableObject {
    @Published var activities: [NearbyActivity] = []

    func fetchNearbyActivities(lat: Double, lon: Double, radius: Double = 1000) async {
        guard let url = URL(string: "http://172.20.10.4:8000/api/activities/nearby?lat=\(lat)&lon=\(lon)&radius=\(radius)") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([NearbyActivity].self, from: data)
            DispatchQueue.main.async {
                self.activities = decoded
            }
        } catch {
            print("Erreur lors du chargement des activités: \(error)")
        }
    }
}