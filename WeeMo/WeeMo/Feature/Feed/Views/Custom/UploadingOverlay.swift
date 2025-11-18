//
//  UploadingOverlay.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/15/25.
//

import SwiftUI

// MARK: - Uploading Overlay

/// 업로드 중 상태를 표시하는 오버레이 뷰
struct UploadingOverlay: View {
    let message: String
    var tintColor: Color = .white
    var backgroundColor: Color = .black.opacity(0.4)
    var contentBackgroundColor: Color = .black.opacity(0.7)

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: Spacing.base) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(tintColor)
                    .scaleEffect(1.5)

                Text(message)
                    .font(.app(.content1))
                    .foregroundStyle(tintColor)
            }
            .padding(Spacing.base)
            .background(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                    .fill(contentBackgroundColor)
            )
        }
    }
}

// MARK: - Preview

#Preview("기본") {
    ZStack {
        Color.white
        UploadingOverlay(message: "게시글 업로드 중...")
    }
}

#Preview("커스텀 색상") {
    ZStack {
        Color.gray
        UploadingOverlay(
            message: "파일 업로드 중...",
            tintColor: .wmMain,
            backgroundColor: .white.opacity(0.8),
            contentBackgroundColor: .white
        )
    }
}
