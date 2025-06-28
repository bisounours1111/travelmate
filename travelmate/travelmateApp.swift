//
//  travelmateApp.swift
//  travelmate
//
//  Created by Yanis Daï on 16/06/2025.
//

import SwiftUI

@main
struct TravelMateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var viewModel: TravelAppViewModel = TravelAppViewModel()
    @StateObject var authService: AuthService = AuthService()

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(viewModel).environmentObject(authService)
        }
    }
}