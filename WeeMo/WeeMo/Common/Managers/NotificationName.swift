//
//  NotificationName.swift
//  WeeMo
//
//  Created by Lee on 11/24/25.
//

import Foundation

extension Notification.Name {
    /// 토큰 만료로 인한 강제 로그아웃 필요 시 발송
    static let forceLogout = Notification.Name("forceLogout")
}
