//
//  WeatherTabView.swift
//  WeatherAppForIOS
//
//  Created by user271485 on 12/30/24.
//

import SwiftUI

struct WeatherTabView: View {
    var body: some View {
        TabView{
            ContentView()
                .tabItem{
                    Label("Weather", systemImage: "cloud.sun.fill")
                }

            MapView()
                .tabItem{
                    Label("MapView", systemImage: "map.fill")
                }
        }
    }
}

#Preview {
    WeatherTabView()
        .environmentObject(WeatherViewModel.preview)
}
