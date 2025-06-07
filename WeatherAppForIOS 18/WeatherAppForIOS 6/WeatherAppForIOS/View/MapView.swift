import SwiftUI
import MapKit
import CoreLocation

struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct MapView: View {
    @StateObject private var locationManager = LocationManager() // For tracking user location
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612), // Default center
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var markers: [MapAnnotationItem] = [] // Array of all markers
    @State private var selectedMarkerId: UUID? // ID of the selected marker
    @State private var showDuplicateAlert = false // State for duplicate alert
    @State private var showConfirmationDialog = false // State for showing the confirmation dialog
    @State private var showCityAddedAlert = false // State for city added alert
    @State private var addedCityName: String? // Name of the city added to favorites
    @EnvironmentObject var weatherViewModel: WeatherViewModel // Access to favorite cities

    var body: some View {
        NavigationStack {
            ZStack {
                // Map with markers
                Map(coordinateRegion: $region,
                    showsUserLocation: true,
                    annotationItems: markers) { marker in
                    MapAnnotation(coordinate: marker.coordinate) {
                        Image(systemName: "mappin.circle.fill") // Normal map marker
                            .resizable()
                            .foregroundColor(.blue)
                            .frame(width: 30, height: 30)
                            .onTapGesture {
                                handleMarkerTap(marker: marker) // Open alert on single tap
                            }
                    }
                }
                .mapStyle(.standard)
                .edgesIgnoringSafeArea(.all) // Make the map full-screen
                .onAppear {
                    locationManager.requestLocation() // Request location permissions on appear
                    syncMarkersWithFavorites() // Add markers for favorite cities
                }
                .onChange(of: locationManager.userLocation) { newLocation in
                    if let newLocation = newLocation {
                        region.center = newLocation.coordinate // Update map center to user's location
                    }
                }
                .gesture(
                    LongPressGesture(minimumDuration: 1.0)
                        .onEnded { _ in
                            addMarkerAtMapCenter() // Add a new marker with a long press
                        }
                )

                // Zoom and Location Buttons
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            Button(action: zoomIn) {
                                Image(systemName: "plus.magnifyingglass")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }

                            Button(action: zoomOut) {
                                Image(systemName: "minus.magnifyingglass")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }

                            Button(action: {
                                if let userLocation = locationManager.userLocation {
                                    region.center = userLocation.coordinate
                                }
                            }) {
                                Image(systemName: "location.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.blue)
                                    .padding()
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Select Locations")
            .confirmationDialog("Do you want to add this city to your favorites?", isPresented: $showConfirmationDialog, titleVisibility: .visible) {
                Button("Add") {
                    handleAddCity()
                }
                Button("Remove", role: .destructive) {
                    if let id = selectedMarkerId {
                        removeMarker(with: id)
                    }
                }
                Button("Cancel", role: .cancel) {
                    selectedMarkerId = nil
                }
            }
            .alert("Duplicate City", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This city is already in your favorites.")
            }
            .alert("City Added", isPresented: $showCityAddedAlert) { // Alert for city added
                Button("OK", role: .cancel) {}
            } message: {
                Text("\(addedCityName ?? "The city") has been added to your favorites.")
            }
        }
    }

    /// Handle single tap on a marker to open the alert dialog
    private func handleMarkerTap(marker: MapAnnotationItem) {
        selectedMarkerId = marker.id
        showConfirmationDialog = true
    }

    /// Add a marker at the center of the map
    private func addMarkerAtMapCenter() {
        let newMarker = MapAnnotationItem(coordinate: region.center)

        // Prevent duplicate markers
        if markers.contains(where: { $0.coordinate.latitude == newMarker.coordinate.latitude && $0.coordinate.longitude == newMarker.coordinate.longitude }) {
            showDuplicateAlert = true // Show alert for duplicate markers
            return
        }

        markers.append(newMarker)
    }

    /// Synchronize markers with favorite cities
    private func syncMarkersWithFavorites() {
        markers = weatherViewModel.favoriteCities.map { city in
            MapAnnotationItem(coordinate: CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude))
        }
    }

    private func handleAddCity() {
        guard let id = selectedMarkerId,
              let marker = markers.first(where: { $0.id == id }) else { return }

        // Check if the city is already in the favorites
        if weatherViewModel.favoriteCities.contains(where: {
            $0.latitude == marker.coordinate.latitude && $0.longitude == marker.coordinate.longitude
        }) {
            showDuplicateAlert = true // Show the duplicate alert
            return
        }

        Task {
            // Add the city to favorites if not a duplicate
            await weatherViewModel.addFavoriteCity(
                latitude: marker.coordinate.latitude,
                longitude: marker.coordinate.longitude
            )
            selectedMarkerId = nil

            // Set the added city name dynamically
            addedCityName = "Lat: \(marker.coordinate.latitude), Lon: \(marker.coordinate.longitude)"
            showCityAddedAlert = true // Show alert for city added
        }
    }

    private func removeMarker(with id: UUID) {
        markers.removeAll { $0.id == id }
        selectedMarkerId = nil
    }

    private func zoomIn() {
        let zoomFactor = 0.5
        region.span = MKCoordinateSpan(
            latitudeDelta: max(region.span.latitudeDelta * zoomFactor, 0.002),
            longitudeDelta: max(region.span.longitudeDelta * zoomFactor, 0.002)
        )
    }

    private func zoomOut() {
        let zoomFactor = 2.0
        region.span = MKCoordinateSpan(
            latitudeDelta: min(region.span.latitudeDelta * zoomFactor, 180),
            longitudeDelta: min(region.span.longitudeDelta * zoomFactor, 180)
        )
    }
}

#Preview {
    MapView()
        .environmentObject(WeatherViewModel.preview)
}
