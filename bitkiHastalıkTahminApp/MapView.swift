import SwiftUI
import MapKit
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var isAuthorized = false
    private var geocoder = CLGeocoder()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        checkLocationAuthorization()
    }

    func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            isAuthorized = false
            locationManager.stopUpdatingLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        if location.horizontalAccuracy > 0 {
            self.location = location
            locationManager.stopUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Konum hatası: \(error.localizedDescription)")
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
}

struct MapView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var region: MKCoordinateRegion
    @Binding var markedLocations: [MarkedLocation]
    var currentPrediction: String
    @StateObject private var locationManager = LocationManager()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isProcessingLocation = false

    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true)
                .onTapGesture {
                    handleMapTap()
                }
                .edgesIgnoringSafeArea(.all)

            VStack {
                if !locationManager.isAuthorized {
                    permissionView
                }

                Spacer()

                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                            .font(.title2)
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }

                    Button(action: goToUserLocation) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    .disabled(!locationManager.isAuthorized || isProcessingLocation)

                    Spacer()
                }
                .padding()
            }
        }
        .alert("Bilgi", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private var permissionView: some View {
        VStack {
            Text("Konum izni gerekiyor")
                .font(.headline)
            Text("Haritayı kullanmak için lütfen konum iznini etkinleştirin")
                .multilineTextAlignment(.center)
                .padding()
            Button("Ayarları Aç") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }

    private func handleMapTap() {
        guard !isProcessingLocation else { return }

        if locationManager.isAuthorized {
            isProcessingLocation = true
            let coordinate = region.center
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                isProcessingLocation = false

                if let error = error {
                    alertMessage = "Konum bilgisi alınamadı: \(error.localizedDescription)"
                    showAlert = true
                    return
                }

                if let placemark = placemarks?.first {
                    let address = [
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.country
                    ].compactMap { $0 }.joined(separator: ", ")

                    let newMarkedLocation = MarkedLocation(address: address, carPrediction: currentPrediction)
                    markedLocations.append(newMarkedLocation)
                    alertMessage = "Konum kaydedildi: \(address)"
                    showAlert = true
                }
            }
        } else {
            alertMessage = "Konum izni gerekiyor. Lütfen ayarlardan konum iznini etkinleştirin."
            showAlert = true
        }
    }

    private func goToUserLocation() {
        guard let location = locationManager.location else {
            locationManager.startUpdatingLocation()
            return
        }

        withAnimation {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
}
