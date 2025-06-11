import Foundation

struct Prediction: Identifiable, Codable {
    let id: UUID
    let label: String
    let confidence: String
    let date: Date
    let latitude: Double
    let longitude: Double

    init(id: UUID = UUID(), label: String, confidence: String, date: Date, latitude: Double, longitude: Double) {
        self.id = id
        self.label = label
        self.confidence = confidence
        self.date = date
        self.latitude = latitude
        self.longitude = longitude
    }
}
