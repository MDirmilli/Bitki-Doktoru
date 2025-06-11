import Foundation

struct MarkedLocation: Identifiable, Codable {
    let id = UUID()
    let address: String
    let carPrediction: String
}
