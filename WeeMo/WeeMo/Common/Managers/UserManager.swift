//
//  UserManager.swift
//  WeeMo
//
//  Created by Lee on 11/18/25.
//

import Foundation
import Combine

// MARK: - User Manager

@MainActor
final class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published var nickname: String?
    @Published var profileImageURL: String?

    private let nicknameKey = "userNickname"
    private let profileImageURLKey = "userProfileImageURL"

    private init() {
        loadNickname()
        loadProfileImageURL()
    }

    // MARK: - Public Methods

    /// 닉네임 저장
    func saveNickname(_ nickname: String) {
        print("[UserManager] 닉네임 저장: \(nickname)")
        self.nickname = nickname
        UserDefaults.standard.set(nickname, forKey: nicknameKey)
    }

    /// 닉네임 불러오기
    func loadNickname() {
        self.nickname = UserDefaults.standard.string(forKey: nicknameKey)
        if let nickname = self.nickname {
            print("[UserManager] 닉네임 로드: \(nickname)")
        } else {
            print("[UserManager] 저장된 닉네임 없음")
        }
    }

    /// 닉네임 삭제 (로그아웃)
    func clearNickname() {
        print("[UserManager] 닉네임 삭제")
        self.nickname = nil
        UserDefaults.standard.removeObject(forKey: nicknameKey)
    }

    /// 프로필 이미지 URL 저장
    func saveProfileImageURL(_ url: String?) {
        print("[UserManager] 프로필 이미지 URL 저장: \(url ?? "nil")")
        self.profileImageURL = url
        if let url = url {
            UserDefaults.standard.set(url, forKey: profileImageURLKey)
        } else {
            UserDefaults.standard.removeObject(forKey: profileImageURLKey)
        }
    }

    /// 프로필 이미지 URL 불러오기
    func loadProfileImageURL() {
        self.profileImageURL = UserDefaults.standard.string(forKey: profileImageURLKey)
        if let url = self.profileImageURL {
            print("[UserManager] 프로필 이미지 URL 로드: \(url)")
        } else {
            print("[UserManager] 저장된 프로필 이미지 URL 없음")
        }
    }

    /// 프로필 이미지 URL 삭제 (로그아웃)
    func clearProfileImageURL() {
        print("[UserManager] 프로필 이미지 URL 삭제")
        self.profileImageURL = nil
        UserDefaults.standard.removeObject(forKey: profileImageURLKey)
    }

    /// 모든 사용자 데이터 삭제 (로그아웃/회원탈퇴)
    func clearUserData() {
        print("[UserManager] 모든 사용자 데이터 삭제")
        clearNickname()
        clearProfileImageURL()
    }
}
