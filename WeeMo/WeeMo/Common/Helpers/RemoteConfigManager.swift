//
//  RemoteConfigManager.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/30/25.
//

import Foundation
import FirebaseRemoteConfig
import Observation

// MARK: - Remote Config Error

/// Remote Config 관련 에러
enum RemoteConfigError: LocalizedError {
    case fetchFailed(status: RemoteConfigFetchStatus)
    case activationFailed

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let status):
            return "Remote Config fetch 실패: \(status)"
        case .activationFailed:
            return "Remote Config activation 실패"
        }
    }
}

/// Firebase Remote Config를 관리하는 싱글톤 매니저
/// - 앱 시작 시 설정을 가져오고, 런타임에 동적으로 기능/UI를 제어
@Observable
final class RemoteConfigManager {

    // MARK: - Singleton

    static let shared = RemoteConfigManager()

    private let remoteConfig: RemoteConfig

    // MARK: - Observable Properties

    /// 점검 모드 활성화 여부 (UI 자동 업데이트)
    var isMaintenanceMode: Bool = false

    // MARK: - Initialization

    private init() {
        remoteConfig = RemoteConfig.remoteConfig()

        // Remote Config 설정
        let settings = RemoteConfigSettings()

        #if DEBUG
        // 개발 중에는 fetch 간격을 짧게 (테스트 용이)
        settings.minimumFetchInterval = 0
        #else
        // 프로덕션에서는 1시간 간격
        settings.minimumFetchInterval = 3600
        #endif

        remoteConfig.configSettings = settings

        // 기본값 설정 (네트워크 실패 시 사용)
        setDefaultValues()
    }

    // MARK: - Default Values

    /// Remote Config fetch 실패 시 사용할 기본값 설정
    private func setDefaultValues() {
        let defaults: [String: NSObject] = [
            // 공지사항
            RemoteConfigKey.homeNoticeEnabled.rawValue: false as NSObject,
            RemoteConfigKey.homeNoticeMessage.rawValue: "" as NSObject,
            RemoteConfigKey.homeNoticeLink.rawValue: "" as NSObject,

            // 앱 설정
            RemoteConfigKey.maintenanceMode.rawValue: false as NSObject,
            RemoteConfigKey.maintenanceMessage.rawValue: "서비스 점검 중입니다." as NSObject
//            RemoteConfigKey.minimumAppVersion.rawValue: "1.0.0" as NSObject
        ]

        remoteConfig.setDefaults(defaults)
    }

    // MARK: - Fetch Config

    /// Remote Config 값을 서버에서 가져오고 활성화
    @MainActor
    func fetchConfig() async throws {
        let status = try await remoteConfig.fetch()

        guard status == .success else {
            throw RemoteConfigError.fetchFailed(status: status)
        }

        try await remoteConfig.activate()

        // Observable 프로퍼티 업데이트 (이미 MainActor)
        updateObservableProperties()
    }

    // MARK: - Private Methods

    /// Observable 프로퍼티를 Remote Config 값으로 업데이트
    private func updateObservableProperties() {
        isMaintenanceMode = remoteConfig[RemoteConfigKey.maintenanceMode.rawValue].boolValue
    }

    // MARK: - Public Properties

    // MARK: 공지사항

    /// 홈 화면 공지사항 표시 여부
    var homeNoticeEnabled: Bool {
        remoteConfig[RemoteConfigKey.homeNoticeEnabled.rawValue].boolValue
    }

    /// 홈 화면 공지사항 메시지
    var homeNoticeMessage: String {
        remoteConfig[RemoteConfigKey.homeNoticeMessage.rawValue].stringValue
    }

    /// 공지사항 클릭 시 이동할 링크 URL
    var homeNoticeLink: String {
        remoteConfig[RemoteConfigKey.homeNoticeLink.rawValue].stringValue
    }

    // MARK: 앱 설정

    /// 서비스 점검 모드 활성화 여부
    var maintenanceMode: Bool {
        remoteConfig[RemoteConfigKey.maintenanceMode.rawValue].boolValue
    }

    /// 점검 모드 시 표시할 메시지
    var maintenanceMessage: String {
        remoteConfig[RemoteConfigKey.maintenanceMessage.rawValue].stringValue
    }

    /// 앱 최소 요구 버전 (강제 업데이트용)
//    var minimumAppVersion: String {
//        remoteConfig[RemoteConfigKey.minimumAppVersion.rawValue].stringValue
//    }
}

// MARK: - Remote Config Keys

/// Remote Config에서 사용하는 키 정의
enum RemoteConfigKey: String {
    // 공지사항
    case homeNoticeEnabled = "home_notice_enabled"
    case homeNoticeMessage = "home_notice_message"
    case homeNoticeLink = "home_notice_link"

    // 앱 설정
    case maintenanceMode = "maintenance_mode"
    case maintenanceMessage = "maintenance_message"
//    case minimumAppVersion = "minimum_app_version"
}
