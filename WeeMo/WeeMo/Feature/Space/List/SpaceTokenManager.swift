//
//  SpaceTokenManager.swift
//  WeeMo
//
//  Created by Reimos on 11/15/25
//

import Foundation

// MARK: - Space 기능 전용 임시 토큰 관리자

/// Space 기능 개발 중 임시로 사용하는 AccessToken 관리자
/// TODO: 추후 로그인 기능 완성 시 제거 예정
final class SpaceTokenManager {
    static let shared = SpaceTokenManager()

    private init() {}

    // MARK: - Constants

    private let tokenKey = "accessToken"

    // MARK: - Public Methods

    /// 임시 AccessToken 저장
    /// - Parameter token: 하드코딩된 임시 토큰
    func saveTemporaryToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        print("[SpaceTokenManager] 임시 토큰 저장 완료")
    }

    /// 현재 저장된 토큰 확인
    func getCurrentToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }

    /// 토큰 존재 여부 확인
    func hasToken() -> Bool {
        return getCurrentToken() != nil
    }

    /// 임시 토큰 제거 (개발용)
    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        print("[SpaceTokenManager] 임시 토큰 삭제 완료")
    }
}
