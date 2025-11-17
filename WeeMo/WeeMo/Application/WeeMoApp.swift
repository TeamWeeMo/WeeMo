//
//  WeeMoApp.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/7/25.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct WeeMoApp: App {

    @StateObject private var appState = AppState()

    init() {
        if let appKey = Bundle.main.object(forInfoDictionaryKey: "KakaoKey") as? String {
            KakaoSDK.initSDK(appKey: appKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn {
                TapView()
                    .environmentObject(appState)
                    .onOpenURL { url in
                        if AuthApi.isKakaoTalkLoginUrl(url) {
                            _ = AuthController.handleOpenUrl(url: url)
                        }
                    }
            } else {
                LoginView()
                    .environmentObject(appState)
                    .onOpenURL { url in
                        if AuthApi.isKakaoTalkLoginUrl(url) {
                            _ = AuthController.handleOpenUrl(url: url)
                        }
                    }
            }
        }
    }
}
