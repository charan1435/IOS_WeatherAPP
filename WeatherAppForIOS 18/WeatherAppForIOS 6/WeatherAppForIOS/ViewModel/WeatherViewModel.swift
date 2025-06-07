//
//  WeatherViewModel.swift
//  WeatherAppForIOS
//
//  Created by user271485 on 12/27/24.
//

import Foundation
import SwiftUI
import CoreLocation

class WeatherViewModel: ObservableObject {
    @Published var weeklyForecast: [WeatherEntry] = []  // Data for the weekly forecast
    @Published var hourlyForecast: [WeatherEntry] = []  // Data for the hourly forecast
    @Published var selectedCity: FavvouriteCity?        // Currently selected city
    @Published var isLoading: Bool = false             // Loading state for the UI
    @Published var apiError: String?

    // Persist favorite cities using @AppStorage
    @AppStorage("favoriteCities") private var favoriteCitiesData: Data = Data()

    // Favorite cities array
    @Published var favoriteCities: [FavvouriteCity] = [] {
        didSet {
            saveFavoriteCities()   // Save whenever the list gets updated
        }
    }

    // Constructor
    init() {
        loadFavoriteCities()
    }

    /// Save favorite cities using JSON encoding
    private func saveFavoriteCities() {
        do {
            let encodedData = try JSONEncoder().encode(favoriteCities)
            favoriteCitiesData = encodedData
        } catch {
            print("Failed to save favorite cities: \(error.localizedDescription)")
        }
    }

    /// Load favorite cities using JSON decoding
    private func loadFavoriteCities() {
        do {
            if !favoriteCitiesData.isEmpty {
                favoriteCities = try JSONDecoder().decode([FavvouriteCity].self, from: favoriteCitiesData)
            }
        } catch {
            print("Failed to load favorite cities: \(error.localizedDescription)")
        }
    }

    private let baseURL = "https://api.openweathermap.org/data/3.0/onecall"
    private let apiKey = "08e0a2b17c0dbc3d0c983e99ee0d27f8"  // API key

    // Fetch city suggestions using OpenWeather GeoCoding API
    func fetchCitySuggestions(for query: String) async throws -> [FavvouriteCity] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let geocodingURL = "https://api.openweathermap.org/geo/1.0/direct?q=\(encodedQuery)&limit=5&appid=\(apiKey)"
        guard let url = URL(string: geocodingURL) else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decodedResponse = try JSONDecoder().decode([GeocodingResponse].self, from: data)

        return decodedResponse.map {
            let detailedName = [$0.name, $0.state, $0.country].compactMap { $0 }.joined(separator: ", ")
            return FavvouriteCity(name: detailedName, latitude: $0.lat, longitude: $0.lon)
        }
    }

    // Add a favorite city
    func addFavoriteCity(latitude: Double, longitude: Double) async {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            let name = placemarks.first?.locality ?? placemarks.first?.name ?? "Unnamed Location"
            await MainActor.run {
                self.favoriteCities.append(FavvouriteCity(name: name, latitude: latitude, longitude: longitude))
            }
        } catch {
            print("Reverse geocoding failed: \(error.localizedDescription)")
            await MainActor.run {
                self.favoriteCities.append(FavvouriteCity(name: "Unknown Location", latitude: latitude, longitude: longitude))
            }
        }
    }

    // Fetch weather for the user's current location
    func fetchWeatherForUserLocation(location: CLLocation) {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        fetchWeatherData(latitude: latitude, longitude: longitude)
    }

    // Fetch weather data for a given latitude and longitude
    func fetchWeatherData(latitude: Double, longitude: Double) {
        isLoading = true
        Task {
            do {
                let weatherResponse = try await fetchWeatherDataAsync(latitude: latitude, longitude: longitude)
                await MainActor.run {
                    self.parseWeatherData(response: weatherResponse)
                    self.isLoading = false
                }
            } catch {
                print("Error fetching weather data: \(error.localizedDescription)")
                await MainActor.run {
                    self.apiError = "Failed to fetch weather data. Please try again."
                    self.isLoading = false
                }
            }
        }
    }
    

    // Asynchronous API request to fetch weather data
    private func fetchWeatherDataAsync(latitude: Double, longitude: Double) async throws -> WeatherAPIResponse {
        guard let url = URL(string: "\(baseURL)?lat=\(latitude)&lon=\(longitude)&units=metric&exclude=minutely,alerts&appid=\(apiKey)") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(WeatherAPIResponse.self, from: data)
    }
    // Helper to format the time
    private func formatTime(from timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // Example: "09:30 AM"
        return formatter.string(from: date)
    }

    // Parse weather API response
    private func parseWeatherData(response: WeatherAPIResponse) {
        // Get current weather description
           let currentWeather = response.current
           let weatherCondition = currentWeather.weather.first?.description.capitalized ?? "Clear"
           let windGust = currentWeather.wind_gust ?? 0.0
           let formattedTime = formatTime(from: currentWeather.dt)

           // Create a full description
           let currentWeatherDescription = """
           \(weatherCondition) conditions expected around \(formattedTime). \
           Wind gusts are up to \(Int(windGust)) km/h.
           """
        
        weeklyForecast = response.daily.enumerated().map { index, daily in
            let date = Date(timeIntervalSince1970: daily.dt)
            let formatter = DateFormatter()
            formatter.dateFormat = "E"

            let windDirection = mapWindDirection(degrees: daily.wind_deg)

            return WeatherEntry(
                timeInformation: formatter.string(from: date),
                iconName: mapIcon(icon: daily.weather.first?.icon ?? ""),
                lowTemp: Int(daily.temp.min),
                highTemp: Int(daily.temp.max),
                currentTemp: (index == 0) ? Int(response.current.temp) : nil,
                windGust: daily.wind_gust,
                windDirection: windDirection,
                weatherDescription: daily.weather.first?.description.capitalized ,
                currentWeatherDescription: (index == 0) ? currentWeatherDescription : nil,
                humidity: daily.humidity,
                precipitation: daily.precipitation,
                visibility: index == 0 ? (response.current.visibility ?? 0) / 1000 : nil,
                presssure: index == 0 ? response.current.pressure : nil
                
            )
        }

        hourlyForecast = response.hourly.prefix(12).map { hourly in
            let date = Date(timeIntervalSince1970: hourly.dt)
            let formatter = DateFormatter()
            formatter.dateFormat = "h a"

            return WeatherEntry(
                timeInformation: formatter.string(from: date),
                iconName: mapIcon(icon: hourly.weather.first?.icon ?? ""),
                lowTemp: nil,
                highTemp: Int(hourly.temp),
                currentTemp: nil,
                windGust: nil,
                windDirection: nil,
                weatherDescription:  hourly.weather.first?.description,
                currentWeatherDescription: nil,
                humidity: hourly.humidity,
                precipitation: hourly.precipitation,
                visibility: hourly.visibility / 1000, // Correct}, // convert meters to km
                presssure: hourly.pressure
                
            )
        }
    }

    // Map OpenWeather icon codes to SF Symbols
    private func mapIcon(icon: String) -> String {
        switch icon {
        case "01d", "01n": return "sun.max.fill"
        case "02d", "02n": return "cloud.sun.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "smoke.fill"
        case "09d", "09n": return "cloud.drizzle.fill"
        case "10d", "10n": return "cloud.rain.fill"
        case "11d", "11n": return "cloud.bolt.fill"
        case "13d", "13n": return "snow"
        case "50d", "50n": return "wind"
        default: return "questionmark.circle"
        }
    }

    // Convert wind degrees to cardinal direction
    private func mapWindDirection(degrees: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW", "N"]
        let index = Int((degrees + 22.5) / 45.0) % 8
        return directions[index]
    }
    private let airQualityBaseURL = "https://api.openweathermap.org/data/2.5/air_pollution"
    @Published var aqi: Int? = nil                     // Air Quality Index
    @Published var pollutants: [String: Double]? = nil // Pollutants and their concentrations


    func fetchAirQualityData(latitude: Double, longitude: Double) {
        let url = URL(string: "\(airQualityBaseURL)?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)")!
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(AirQualityResponse.self, from: data)
                if let airQualityData = response.list.first {
                    await MainActor.run {
                        aqi = airQualityData.main.aqi
                        pollutants = [
                            "CO": airQualityData.components.co,
                            "NO2": airQualityData.components.no2,
                            "O3": airQualityData.components.o3
                        ]
                    }
                }
            } catch {
                print("Error fetching air quality data: \(error.localizedDescription)")
            }
        }
    }
    
    /// Mock preview instance for SwiftUI previews
    static var preview: WeatherViewModel {
        let viewModel = WeatherViewModel()

        // Set a mock selected city
        viewModel.selectedCity = FavvouriteCity(name: "Colombo", latitude: 6.9271, longitude: 79.8612)

        // Mock weekly forecast
        viewModel.weeklyForecast = [
            WeatherEntry(timeInformation: "Monday", iconName: "sun.max.fill", lowTemp: 25, highTemp: 30,currentTemp: 28, windGust: 35.0,windDirection: "NE",weatherDescription: "CLOUDY",currentWeatherDescription: "Sunny conditions expected around 9:30 AM. Wind speeds are 10 km/h, with gusts up to 35 km/h.",humidity: 5,precipitation: 20.0,visibility: 10.0,presssure: 30),
            WeatherEntry(timeInformation: "Tuesday", iconName: "cloud.rain.fill", lowTemp: 22, highTemp: 28,currentTemp: nil, windGust: 20.0, windDirection: "SW",weatherDescription: "WINDY",currentWeatherDescription: "Sunny conditions expected around 9:30 AM. Wind speeds are 10 km/h, with gusts up to 35 km/h.",humidity: 5,precipitation: 20.0,visibility: 10.0,presssure: 30),
            WeatherEntry(timeInformation: "Wednesday", iconName: "cloud.bolt.fill", lowTemp: 24, highTemp: 29,currentTemp: nil,windGust: 15.0, windDirection: "W",weatherDescription: "SUNNY",currentWeatherDescription: "Sunny conditions expected around 9:30 AM. Wind speeds are 10 km/h, with gusts up to 35 km/h.",humidity: 5,precipitation: 20.0,visibility: 10.0,presssure: 30),
        ]

        // Mock hourly forecast
        viewModel.hourlyForecast = [
            WeatherEntry(timeInformation: "6 AM", iconName: "sun.max.fill", lowTemp: nil, highTemp: 26, currentTemp: nil, windGust: 35.0,windDirection: "NE",weatherDescription: "SUNNY",currentWeatherDescription: "Sunny conditions expected around 9:30 AM. Wind speeds are 10 km/h, with gusts up to 35 km/h.",humidity: 5,precipitation: 20.0,visibility: 10.0,presssure: 30),
            WeatherEntry(timeInformation: "9 AM", iconName: "cloud.fill", lowTemp: nil, highTemp: 28, currentTemp: nil, windGust: 20.0,windDirection: "SW",weatherDescription: "SUNNY",currentWeatherDescription: "Sunny conditions expected around 9:30 AM. Wind speeds are 10 km/h, with gusts up to 35 km/h.",humidity: 5,precipitation: 20.0,visibility: 10.0,presssure: 30),
            WeatherEntry(timeInformation: "12 PM", iconName: "cloud.rain.fill", lowTemp: nil, highTemp: 30, currentTemp: nil, windGust: 15.0,windDirection: "N",weatherDescription: "SUNNY",currentWeatherDescription: "Sunny conditions expected around 9:30 AM. Wind speeds are 10 km/h, with gusts up to 35 km/h.",humidity: 5,precipitation: 20.0,visibility: 10.0,presssure: 30),
        ]

        return viewModel
    }
}
