//
//  TokenManager.swift
//  WeeMo
//
//  Created by Lee on 11/14/25.
//

import Foundation

final class TokenManager {
    static let shared = TokenManager()
    private init() { }

    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let userIdKey = "userId"

    func saveTokens(accessToken: String, refreshToken: String) {
        _ = KeychainManager.shared.save(key: accessTokenKey, value: accessToken)
        _ = KeychainManager.shared.save(key: refreshTokenKey, value: refreshToken)
    }

    func saveUserId(_ userId: String) {
        _ = KeychainManager.shared.save(key: userIdKey, value: userId)
    }

    var accessToken: String? {
        return KeychainManager.shared.load(key: accessTokenKey)
    }

    var refreshToken: String? {
        return KeychainManager.shared.load(key: refreshTokenKey)
    }

    var userId: String? {
        return KeychainManager.shared.load(key: userIdKey)
    }

    func updateAccessToken(_ token: String) {
        _ = KeychainManager.shared.update(key: accessTokenKey, value: token)
    }

    func clearTokens() {
        _ = KeychainManager.shared.delete(key: accessTokenKey)
        _ = KeychainManager.shared.delete(key: refreshTokenKey)
        _ = KeychainManager.shared.delete(key: userIdKey)
    }

    var isLoggedIn: Bool {
        return accessToken != nil && refreshToken != nil
    }
}
