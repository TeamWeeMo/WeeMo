//
//  ButtonWrapper.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/9/25.
//

import SwiftUI

// MARK: - Button Wrapper Modifier

/// 기본 버튼 래퍼
/// - 모든 뷰를 버튼으로 변환
/// - 탭 제스처 + 액션 실행
private struct ButtonWrapper: ViewModifier {
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
    func buttonWrapper(action: @escaping () -> Void) -> some View {
        modifier(ButtonWrapper(action: action))
    }
}
