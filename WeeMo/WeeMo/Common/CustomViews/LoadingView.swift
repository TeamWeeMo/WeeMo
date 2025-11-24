//
//  LoadingView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/15/25.
//

import SwiftUI

// MARK: - Loading View

/// 로딩 상태를 표시하는 재사용 가능한 뷰
struct LoadingView: View {
    let message: String
    var tintColor: Color = .wmMain
    var scale: CGFloat = 1.5

    var body: some View {
        VStack(spacing: Spacing.base) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(tintColor)
                .scaleEffect(scale)

            Text(message)
                .font(.app(.content2))
                .foregroundStyle(.textSub)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Preview

#Preview("기본") {
    LoadingView(message: "데이터를 불러오는 중...")
}

#Preview("커스텀 색상") {
    LoadingView(message: "로딩 중...", tintColor: .red, scale: 2.0)
}
