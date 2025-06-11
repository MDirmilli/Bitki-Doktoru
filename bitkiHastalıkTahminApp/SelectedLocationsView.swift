
import SwiftUI

struct SelectedLocationsView: View {
    @Binding var markedLocations: [MarkedLocation]

    var body: some View {
        List(markedLocations) { location in
            VStack(alignment: .leading, spacing: 5) {
                Text(location.address)
                    .font(.headline)
                Text("Araç: \(location.carPrediction)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(5)
        }
        .navigationTitle("📌 İşaretlenen Konumlar")
    }
}
