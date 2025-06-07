import SwiftUI

struct ContentView: View {
    @EnvironmentObject var weatherViewModel: WeatherViewModel
    @StateObject var locationManager = LocationManager()
    @State private var isShowingFavorites = false // State to control the presentation of Favorites View

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color.background1]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack {
                    if weatherViewModel.isLoading {
                        ProgressView("Loading weather data...")
                            .padding()
                    } else if let selectedCity = weatherViewModel.selectedCity {
                        displayWeatherForCity(selectedCity)
                    } else if let location = locationManager.userLocation {
                        if weatherViewModel.weeklyForecast.isEmpty {
                            Text("Fetching weather for your location...")
                                .onAppear {
                                    Task {
                                        weatherViewModel.fetchWeatherForUserLocation(location: location)
                                        weatherViewModel.fetchAirQualityData(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                                    }
                                }
                                .padding()
                        } else {
                            displayWeatherForCurrentLocation()
                        }
                    } else {
                        if let error = locationManager.locationError {
                            Text("Location Error: \(error)")
                                .foregroundColor(.red)
                                .padding()
                        } else {
                            Text("Requesting location... Please allow access or select a favorite city.")
                                .onAppear {
                                    locationManager.requestLocation()
                                }
                                .padding()
                        }
                    }
                }
                .foregroundColor(.white)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isShowingFavorites.toggle()
                        }) {
                            Image(systemName: "heart")
                                .foregroundColor(.red)
                        }
                    }
                }
                .sheet(isPresented: $isShowingFavorites) {
                    FavoritesView()
                        .environmentObject(weatherViewModel)
                }
            }
        }
    }

    @ViewBuilder
    private func displayWeatherForCity(_ city: FavvouriteCity) -> some View {
        VStack(alignment: .center, spacing: 16) {
            Text("\(city.name)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)

            if let currentTemp = weatherViewModel.weeklyForecast.first?.currentTemp {
                Text(" \(currentTemp)°")
                    .font(.system(size: 60))
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.horizontal)
            }

            ScrollView {
                VStack(alignment: .center, spacing: 16) {
                    if let description = weatherViewModel.weeklyForecast.first?.weatherDescription {
                        Text(description)
                            .font(.system(size: 20, weight: .semibold, design: .default))
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                    HStack {
                        if let highTemp = weatherViewModel.weeklyForecast.first?.highTemp {
                            Text("H: \(highTemp)°")
                                .font(.system(size: 18, weight: .regular, design: .default))
                                .foregroundColor(.white)
                        }
                        if let lowTemp = weatherViewModel.weeklyForecast.first?.lowTemp {
                            Text("L: \(lowTemp)°")
                                .font(.system(size: 18, weight: .regular, design: .default))
                                .foregroundColor(.white)
                        }
                    }

                    // Hourly Forecast Section
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Hourly Forecast")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)

                            hourlyForecastView
                                .padding(.horizontal)
                        }
                        .padding()
                    }
                    .padding(.horizontal)

                    // 10-Day Forecast Section
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("10-Day Forecast")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)

                            weeklyForecastView
                                .padding(.horizontal)
                        }
                        .padding()
                    }
                    .padding(.horizontal)

                    // Humidity, Precipitation, Visibility, and Pressure Section
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            createInfoCard(title: "Humidity", value: "\(weatherViewModel.weeklyForecast.first?.humidity ?? 0)%", symbol: "humidity.fill")
                            createInfoCard(title: "Precipitation", value: "\(weatherViewModel.weeklyForecast.first?.precipitation ?? 0) mm", symbol: "cloud.rain.fill")
                        }
                        .padding(.horizontal)

                        HStack(spacing: 16) {
                            createInfoCard(title: "Visibility", value: "\(weatherViewModel.weeklyForecast.first?.visibility ?? 0) km", symbol: "eye.fill")
                            createInfoCard(title: "Pressure", value: "\(weatherViewModel.weeklyForecast.first?.presssure ?? 0) hPa", symbol: "speedometer")
                        }
                        .padding(.horizontal)

                        if let aqi = weatherViewModel.aqi {
                            VStack(spacing: 16) {
                                createInfoCard(title: "Air Quality Index", value: "\(aqi)", symbol: nil)
                                if let pollutants = weatherViewModel.pollutants {
                                    HStack(spacing: 16) {
                                        if let co = pollutants["CO"] {
                                            createInfoCard(title: "Carbon Monoxide (CO)", value: "\(String(format: "%.2f", co)) µg/m³", symbol: nil)
                                        }
                                        if let no2 = pollutants["NO2"] {
                                            createInfoCard(title: "Nitrogen Dioxide (NO2)", value: "\(String(format: "%.2f", no2)) µg/m³", symbol: nil)
                                        }
                                        if let o3 = pollutants["O3"] {
                                            createInfoCard(title: "Ozone (O3)", value: "\(String(format: "%.2f", o3)) µg/m³", symbol: nil)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func createInfoCard(title: String, value: String, symbol: String? = nil) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
            VStack(spacing: 10) {
                if let symbol = symbol {
                    Image(systemName: symbol)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 30))
                }
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding()
        }
    }

    private var hourlyForecastView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(weatherViewModel.hourlyForecast) { forecast in
                    VStack {
                        Text(forecast.timeInformation)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        if let iconName = forecast.iconName {
                            Image(systemName: iconName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .symbolRenderingMode(.multicolor)
                        } else {
                            Image(systemName: "questionmark.circle")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                        Text("\(forecast.highTemp)°C")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)))
                }
            }
            .padding(.horizontal)
        }
    }

    private var weeklyForecastView: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(weatherViewModel.weeklyForecast) { forecast in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if let iconName = forecast.iconName {
                            Image(systemName: iconName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .symbolRenderingMode(.multicolor)
                        } else {
                            Image(systemName: "questionmark.circle")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                        Text(forecast.timeInformation)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(forecast.lowTemp ?? 0)°C / \(forecast.highTemp)°C")
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    if let windGust = forecast.windGust, let windDirection = forecast.windDirection {
                        HStack {
                            Text("Wind Gust: \(Int(windGust)) km/h")
                                .font(.footnote)
                                .foregroundColor(.white)
                            Spacer()
                            Text("Direction: \(windDirection)")
                                .font(.footnote)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)))
            }
        }
    }

    @ViewBuilder
    private func displayWeatherForCurrentLocation() -> some View {
        if let userLocation = locationManager.userLocation {
            displayWeatherForCity(
                FavvouriteCity(
                    name: locationManager.cityName ?? "Current Location",
                    latitude: userLocation.coordinate.latitude,
                    longitude: userLocation.coordinate.longitude
                )
            )
        } else {
            Text("Fetching your current location...")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WeatherViewModel.preview)
}
