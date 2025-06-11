import SwiftUI
import CoreML
import Vision
import MapKit
import UserNotifications

class PredictionHistory: ObservableObject {
    @Published var items: [Prediction] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(data, forKey: "Predictions")
            }
        }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: "Predictions"),
           let decoded = try? JSONDecoder().decode([Prediction].self, from: data) {
            items = decoded
        }
    }
}

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var isCamera = false
    @State private var predictionResult = "Henüz tahmin yapılmadı."
    @State private var showMap = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.00902),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @ObservedObject var history = PredictionHistory()
    @State private var markedLocations: [MarkedLocation] = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 20) {
                    // Başlık
                    Text("Bitki Doktoru")
                        .font(.largeTitle)
                        .bold()
                    
                    // Resim alanı
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 250)
                            .cornerRadius(15)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 250)
                            .overlay(Text("Fotoğraf seç veya çek"))
                            .cornerRadius(15)
                    }
                    
                    // Tahmin sonucu
                    Text(predictionResult)
                        .padding(.bottom)
                    
                    // Butonlar
                    VStack(spacing: 12) {
                        Button("📷 Fotoğraf Çek") {
                            isCamera = true
                            isShowingImagePicker = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                        
                        Button("🖼️ Galeriden Seç") {
                            isCamera = false
                            isShowingImagePicker = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                        
                        Button("🗺️ Konum Seç") {
                            showMap = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                        
                        NavigationLink(destination: PredictionListView(history: history)) {
                            Text("📜 Tahmin Geçmişi")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(10)
                        
                        NavigationLink(destination: SelectedLocationsView(markedLocations: $markedLocations)) {
                            Text("📌 İşaretlenen Konumlar")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Spacer(minLength: 100) // Alt taşmayı önler
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(
                sourceType: isCamera ? .camera : .photoLibrary,
                selectedImage: $selectedImage,
                showAlert: $showAlert,
                alertMessage: $alertMessage
            )
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                predictImage(image)
            }
        }
        .sheet(isPresented: $showMap) {
            NavigationView {
                MapView(region: $region, markedLocations: $markedLocations, currentPrediction: predictionResult)
            }
        }
        .alert("Uyarı", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    func predictImage(_ image: UIImage) {
        let maxDimension: CGFloat = 1024
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let optimizedImage = resizedImage,
              let ciImage = CIImage(image: optimizedImage) else {
            predictionResult = "Resim işlenemedi. Lütfen başka bir fotoğraf deneyin."
            return
        }

        guard let coreMLModel = try? VNCoreMLModel(for: PlantDiseasesModel_ana(configuration: MLModelConfiguration()).model) else {
            predictionResult = "ML modeli yüklenemedi."
            return
        }

        let request = VNCoreMLRequest(model: coreMLModel) { request, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.predictionResult = "Tahmin sırasında hata oluştu: \(error.localizedDescription)"
                }
                return
            }

            if let results = request.results as? [VNClassificationObservation],
               let first = results.first {
                let confidence = Int(first.confidence * 100)
                let result = "Tahmin: \(first.identifier)\nGüven: %\(confidence)"

                DispatchQueue.main.async {
                    self.predictionResult = result
                    let newPrediction = Prediction(
                        label: first.identifier,
                        confidence: String(format: "%.2f", first.confidence),
                        date: Date(),
                        latitude: self.region.center.latitude,
                        longitude: self.region.center.longitude
                    )
                    self.history.items.insert(newPrediction, at: 0)
                }
            } else {
                DispatchQueue.main.async {
                    self.predictionResult = "Tahmin alınamadı. Lütfen başka bir fotoğraf deneyin."
                }
            }
        }

        // 🔄 Tahmini arka planda başlat (UI donmasını engeller)
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.predictionResult = "Model çalıştırılırken hata oluştu: \(error.localizedDescription)"
                }
            }
        }
    }
    }


