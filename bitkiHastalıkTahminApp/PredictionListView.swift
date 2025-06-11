import SwiftUI

struct PredictionListView: View {
    @ObservedObject var history: PredictionHistory

    var body: some View {
        List(history.items) { item in
            VStack(alignment: .leading, spacing: 5) {
                Text("\(item.label) - %\(item.confidence)")
                    .bold()
                Text(item.date, style: .date)
                Text("Konum: \(item.latitude), \(item.longitude)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(5)
        }
        .navigationTitle("📜 Önceki Tahminler")
    }
}
