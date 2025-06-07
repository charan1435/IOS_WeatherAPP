//
//  LocationManager.swift
//  WeatherAppForIOS
//
//  Created by user271485 on 12/28/24.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder() // Geocoder for reverse geocoding
    @Published var cityName: String?         // City name fetched via reverse geocoding
    @Published var userLocation: CLLocation?  // Stores user's current location
    @Published var locationError: String? // Error message if location fetch fails
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        checkLocationPermissions()
    }
    
    /// Check and request location permissions
    func checkLocationPermissions() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            locationError = "Location access denied or restricted."
            print("Location access denied or restricted.")
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        @unknown default:
            locationError = "Unknown location authorization status."
            print("Unknown location authorization status.")
        }
    }
    
    // Delegate method: Called when location is updated
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        userLocation = location
        // Fetch city name using reverse geocoding
        fetchCityName(for: location)
        manager.stopUpdatingLocation() // Stop updating after fetching
        
      
    }
    
    // Delegate method: Called when there is an error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error.localizedDescription
        print("Failed to fetch location: \(error.localizedDescription)")
    }
    
    /// Fetch city name using reverse geocoding
    private func fetchCityName(for location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error = error {
                print("Reverse geocoding failed: \(error.localizedDescription)")
                self?.cityName = "Unknown Location"
                return
            }
            
            if let placemark = placemarks?.first {
                // Fetch the locality (city) from the placemark
                self?.cityName = placemark.locality ?? "Unnamed Location"
                print("City name fetched: \(self?.cityName ?? "N/A")")
            }
        }
    }
}
