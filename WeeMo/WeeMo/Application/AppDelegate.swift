//
//  AppDelegate.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/30/25.
//

import UIKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Firebase 초기화 (가장 먼저 실행)
        FirebaseApp.configure()

        // Remote Config 초기 로드
        Task { @MainActor in
            do {
                try await RemoteConfigManager.shared.fetchConfig()
                print("Remote Config initialized successfully")
            } catch {
                print("Remote Config initialization failed: \(error.localizedDescription)")
            }
        }

        return true
    }
}
