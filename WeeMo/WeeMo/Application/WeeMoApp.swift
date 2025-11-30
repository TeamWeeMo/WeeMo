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

    // Firebase 초기화를 위한 AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var appState = AppState()

    init() {
        // Kakao SDK 초기화
        if let appKey = Bundle.main.object(forInfoDictionaryKey: "KakaoKey") as? String {
            KakaoSDK.initSDK(appKey: appKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if RemoteConfigManager.shared.isMaintenanceMode {
                    // 점검 모드
                    MaintenanceView(message: RemoteConfigManager.shared.maintenanceMessage)
                } else if appState.isLoggedIn {
                    // 로그인 상태
                    HomeView()
                        .environmentObject(appState)
                        .onOpenURL { url in
                            if AuthApi.isKakaoTalkLoginUrl(url) {
                                _ = AuthController.handleOpenUrl(url: url)
                            }
                        }
                } else {
                    // 로그인 화면
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
}
