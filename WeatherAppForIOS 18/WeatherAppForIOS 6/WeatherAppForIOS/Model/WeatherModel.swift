import Foundation

// Weather Entry Model for Views
struct WeatherEntry: Identifiable {
    let id = UUID()
    let timeInformation: String        // Day or time information
    let iconName: String?               // Icon representing weather conditions
    let lowTemp: Int?                  // Low temperature
    let highTemp: Int                  // High temperature
    let currentTemp: Int?              // Current temperature
    let windGust: Double?              // Wind gust speed (km/h)
    let windDirection: String?         // Wind direction (e.g., "NE")
    let weatherDescription: String?     // Short weather details 
    let currentWeatherDescription : String? // Full weather Details
    let humidity: Int?                 // Humidity percentage
    let precipitation: Double?         // Precipitation (mm)
    let visibility: Double?            // visibility in km
    let presssure: Int?               // Pressure in hpa
}
// Air Quality API Response Model
struct AirQualityResponse: Codable {
    let list: [AirQualityData]

    struct AirQualityData: Codable {
        let main: AirQualityMain
        let components: Pollutants
        let dt: TimeInterval

        struct AirQualityMain: Codable {
            let aqi: Int               // Air Quality Index
        }

        struct Pollutants: Codable {
            let co: Double             // Carbon Monoxide (µg/m³)
            let no2: Double            // Nitrogen Dioxide (µg/m³)
            let o3: Double             // Ozone (µg/m³)
        }
    }
}
// Favorite City Model
struct FavvouriteCity: Identifiable, Codable {
    let id = UUID()
    let name: String                   // City name
    let latitude: Double               // Latitude
    let longitude: Double              // Longitude
}

// Geocoding API Response Model
struct GeocodingResponse: Codable {
    let name: String                   // City name
    let lat: Double                    // Latitude
    let lon: Double                    // Longitude
    let country: String?               // Country code
    let state: String?                 // State/region name
}

// Weather API Response Models
struct WeatherAPIResponse: Codable {
    let current: CurrentWeather        // Current weather data
    let daily: [DailyWeather]          // Daily weather data
    let hourly: [HourlyWeather]        // Hourly weather data
}

struct CurrentWeather: Codable {
    let temp: Double                   // Current temperature
    let weather: [WeatherCondition]   // Weather conditions
    let wind_speed: Double            // Wind speed
    let wind_gust: Double?            // Wind gust (optional)
    let dt: TimeInterval              // Timestamp for the current weather
    let humidity: Int
    let precipitation: Double?
    let visibility: Double?             // Visibility in meters
    let pressure: Int?                 // Pressure in hPa

    struct WeatherCondition: Codable {
        let icon: String               // Weather icon code
        let description: String        // Weather description
    }
}

struct DailyWeather: Codable {
    let dt: TimeInterval               // Timestamp for the day
    let temp: Temp                     // Temperature details
    let weather: [WeatherCondition]   // Weather conditions
    let wind_deg: Double               // Wind direction in degrees
    let wind_gust: Double?             // Wind gust speed (km/h)
    let humidity: Int
    let precipitation : Double?
    let visibility: Double?             // Visibility in meters
    let pressure: Int?                  // Pressure in hPa

    struct Temp: Codable {
        let min: Double                // Minimum temperature
        let max: Double                // Maximum temperature
    }

    struct WeatherCondition: Codable {
        let icon: String               // Weather icon code
        let description: String
    }
}

struct HourlyWeather: Codable {
    let dt: TimeInterval               // Timestamp for the hour
    let temp: Double                   // Temperature
    let weather: [WeatherCondition]   // Weather conditions
    let humidity: Int                  // Humidity percentage
    let precipitation: Double?         // Precipitation (mm)
    let visibility: Double             // Visibility in meters
    let pressure: Int                  // Pressure in hPa

    struct WeatherCondition: Codable {
        let icon: String               // Weather icon code
        let description: String      // weather Description
    }
}
