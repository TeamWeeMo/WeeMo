//
//  AppState.swift
//  WeeMo
//
//  Created by Lee on 11/14/25.
//

import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var isLoggedIn: Bool

    init() {
        print("[AppState] 초기화 시작")
        let loggedIn = TokenManager.shared.isLoggedIn
        print("[AppState] TokenManager.isLoggedIn = \(loggedIn)")
        self.isLoggedIn = loggedIn
        print("[AppState] 초기화 완료")
    }

    func login() {
        isLoggedIn = true
    }

    func logout() {
        TokenManager.shared.clearTokens()
        isLoggedIn = false
    }
}
