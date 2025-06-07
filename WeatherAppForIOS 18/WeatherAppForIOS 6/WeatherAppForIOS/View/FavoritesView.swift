import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var weatherViewModel: WeatherViewModel
    @State private var searchQuery: String = ""
    @State private var searchResults: [FavvouriteCity] = []
    @State private var showDuplicateAlert = false
    @State private var duplicateCityName: String?
    @State private var showNoCityFoundAlert = false
    @State private var showCityAddedAlert = false // State for showing city added alert
    @State private var addedCityName: String? // Holds the name of the added city

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Transparent Gray Search Bar
                TextField("Search for cities or countries...", text: $searchQuery)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .padding([.horizontal, .top])
                    .foregroundColor(.black)

                // Search Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        Task {
                            await fetchCitySuggestions()
                        }
                    }) {
                        Text("Search")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.7))
                            .cornerRadius(15)
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                    }

                    Button(action: clearSearchResults) {
                        Text("Clear")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.7))
                            .cornerRadius(15)
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                    }
                }
                .padding(.horizontal)

                // Search Results Section
                if !searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Search Results")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal)

                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(searchResults) { city in
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(city.name)
                                            .font(.headline)
                                            .foregroundColor(.black) // Black for the main heading
                                        Text("Lat: \(city.latitude), Lon: \(city.longitude)")
                                            .font(.subheadline)
                                            .foregroundColor(.white) // White for lat/lon
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.2)) // Transparent background
                                    .cornerRadius(15)
                                    .shadow(radius: 5)
                                    .onTapGesture {
                                        handleAddFavorite(city: city)
                                    }
                                    .contextMenu {
                                        Button("Add to Favorites") {
                                            handleAddFavorite(city: city)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else if searchQuery.isEmpty {
                    Text("Search for a city to see results.")
                        .foregroundColor(.black)
                        .padding()
                }

                // Favorites Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Favorite Cities")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal)

                    if weatherViewModel.favoriteCities.isEmpty {
                        Text("No favorite cities added yet.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        List {
                            ForEach(weatherViewModel.favoriteCities) { city in
                                VStack(alignment: .leading) {
                                    NavigationLink(
                                        destination: ContentView()
                                            .environmentObject(weatherViewModel)
                                            .onAppear {
                                                weatherViewModel.selectedCity = city
                                                weatherViewModel.fetchWeatherData(latitude: city.latitude, longitude: city.longitude)
                                            }
                                    ) {
                                        VStack(alignment: .leading) {
                                            Text(city.name)
                                                .font(.headline)
                                                .foregroundColor(.black) // Black for the main heading
                                            Text("Tap to load weather for this city")
                                                .font(.subheadline)
                                                .foregroundColor(.white) // White for "Tap to load..."
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.2)) // Darker faded background
                                        .cornerRadius(10) // Slightly rounded corners for container
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray.opacity(0.5), lineWidth: 1) // Outline for visibility
                                        )
                                    }
                                    Divider()
                                        .background(Color.gray.opacity(0.6)) // Divider with a visible gray
                                }
                                .listRowBackground(Color.clear)
                                .padding([.horizontal, .vertical], 4) // Add padding to separate the container
                            }
                            .onDelete(perform: deleteStoredLocation)
                        }
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color.background1]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
            )
            .navigationTitle("Favorite Cities")
            .alert("Duplicate City", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("\(duplicateCityName ?? "This city") is already in your favorites.")
            }
            .alert("No City Found", isPresented: $showNoCityFoundAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("No city found. Please try again.")
            }
            .alert("City Added", isPresented: $showCityAddedAlert) { // Alert for city added
                Button("OK", role: .cancel) {}
            } message: {
                Text("\(addedCityName ?? "The city") has been added to your favorites.")
            }
        }
    }

    /// Fetch city suggestions from the OpenWeather API
    private func fetchCitySuggestions() async {
        guard !searchQuery.isEmpty else { return }

        do {
            searchResults = try await weatherViewModel.fetchCitySuggestions(for: searchQuery)

            if searchResults.isEmpty {
                showNoCityFoundAlert = true
            }
        } catch {
            print("Error fetching city suggestions: \(error.localizedDescription)")
            showNoCityFoundAlert = true
        }
    }

    /// Handle adding a city to favorites
    private func handleAddFavorite(city: FavvouriteCity) {
        if weatherViewModel.favoriteCities.contains(where: { $0.latitude == city.latitude && $0.longitude == city.longitude }) {
            duplicateCityName = city.name
            showDuplicateAlert = true
            return
        }

        Task {
            await weatherViewModel.addFavoriteCity(latitude: city.latitude, longitude: city.longitude)
            // Show alert for successfully adding a city
            addedCityName = city.name
            showCityAddedAlert = true
        }
    }

    /// Clear search results without affecting the favorite cities list
    private func clearSearchResults() {
        searchQuery = ""
        searchResults = []
    }

    /// Handle deletion of stored locations
    private func deleteStoredLocation(at offsets: IndexSet) {
        weatherViewModel.favoriteCities.remove(atOffsets: offsets)
    }
}

#Preview {
    FavoritesView()
        .environmentObject(WeatherViewModel.preview)
}
