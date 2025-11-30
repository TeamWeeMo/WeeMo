//
//  AppState.swift
//  WeeMo
//
//  Created by Lee on 11/14/25.
//

import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isLoggedIn: Bool

    init() {
        print("[AppState] 초기화 시작")
        let loggedIn = TokenManager.shared.isLoggedIn
        print("[AppState] TokenManager.isLoggedIn = \(loggedIn)")
        self.isLoggedIn = loggedIn
        print("[AppState] 초기화 완료")

        // 강제 로그아웃 Notification 옵저버 등록
        NotificationCenter.default.addObserver(
            forName: .forceLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("[AppState] forceLogout Notification 수신 - 자동 로그아웃 처리")
            Task { @MainActor in
                self?.logout()
            }
        }
    }

    func login() {
        isLoggedIn = true
    }

    func logout() {
        TokenManager.shared.clearTokens()
        UserManager.shared.clearNickname()
        UserManager.shared.clearProfileImageURL()
        isLoggedIn = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
