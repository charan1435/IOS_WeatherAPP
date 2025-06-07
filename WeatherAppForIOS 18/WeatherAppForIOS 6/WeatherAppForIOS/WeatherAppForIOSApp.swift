//
//  WeatherAppForIOSApp.swift
//  WeatherAppForIOS
//
//  Created by user271485 on 12/27/24.
//

import SwiftUI

@main
struct WeatherAppForIOSApp: App {
    //For the tab bar item
    init() {
           let appearance = UITabBarAppearance()
           appearance.configureWithOpaqueBackground()
           appearance.backgroundColor = UIColor.background1.withAlphaComponent(0.7)

           // Set active and inactive colors for tab bar items
           appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
           appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
               .foregroundColor: UIColor.systemBlue,
           ]
           appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white
           appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
               .foregroundColor: UIColor.white,
           ]

           UITabBar.appearance().scrollEdgeAppearance = appearance
           UITabBar.appearance().standardAppearance = appearance
       }
    @StateObject private var weatherViewModel = WeatherViewModel()
    var body: some Scene {
        WindowGroup {
            WeatherTabView()
                .environmentObject(weatherViewModel)
        }
    }
}
