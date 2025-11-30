//
//  FloatingButton.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/24/25.
//

import SwiftUI

// MARK: - Floating Button

/// 지도, 리스트 등에서 사용하는 플로팅 액션 버튼
struct FloatingButton: View {
    let icon: String
    let action: () -> Void

    // 커스터마이징 옵션
    var size: CGFloat = 44
    var iconSize: CGFloat = 20
    var backgroundColor: Color = .wmMain
    var foregroundColor: Color = .white
    var shadowRadius: CGFloat = 4

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: shadowRadius, x: 0, y: 2)
        }
    }
}

// MARK: - Preview

#Preview("현재 위치") {
    FloatingButton(icon: "location.fill") {
        print("현재 위치")
    }
}

#Preview("생성") {
    FloatingButton(
        icon: "plus",
        action: { print("생성") },
        size: 56,
        iconSize: 24
    )
}

#Preview("지도") {
    FloatingButton(icon: "map.fill") {
        print("지도")
    }
}

#Preview("커스텀") {
    FloatingButton(
        icon: "heart.fill",
        action: { print("좋아요") },
        size: 50,
        iconSize: 22,
        backgroundColor: .red,
        foregroundColor: .white
    )
}
