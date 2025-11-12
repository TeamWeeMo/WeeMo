//
//  ChatButtonWrapper.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/10/25.
//

import SwiftUI

private struct ChatButtonWrapper: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        Button(action: action) {
            content
        }
    }
}

extension View {
    /// 버튼 래퍼 적용
    /// - Parameter action: 탭 시 실행할 액션
    func chatButtonWrapper(action: @escaping () -> Void) -> some View {
        modifier(ChatButtonWrapper(action: action))
    }
}
