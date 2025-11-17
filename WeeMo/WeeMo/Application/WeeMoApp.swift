//
//  WeeMoApp.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/7/25.
//

import SwiftUI

@main
struct WeeMoApp: App {

    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn {
                TapView()
                    .environmentObject(appState)
            } else {
                LoginView()
                    .environmentObject(appState)
            }
        }
    }
}
