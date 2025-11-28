//
//  ImagePlaceholder.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/27/25.
//

import SwiftUI

/// 이미지 플레이스홀더 뷰
struct WeeMoImagePlaceholder: View {
    let systemImage: String
    let size: CGFloat
    let cornerRadius: CGFloat

    init(
        systemImage: String = "photo",
        size: CGFloat = 80,
        cornerRadius: CGFloat = Spacing.radiusSmall
    ) {
        self.systemImage = systemImage
        self.size = size
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.2))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: systemImage)
                    .foregroundStyle(.textSub)
            }
    }
}

/// Empty state placeholder (큰 사이즈용)
struct EmptyStatePlaceholder: View {
    let systemImage: String
    let message: String
    let height: CGFloat
    let cornerRadius: CGFloat

    init(
        systemImage: String = "plus.circle",
        message: String,
        height: CGFloat = 120,
        cornerRadius: CGFloat = Spacing.radiusMedium
    ) {
        self.systemImage = systemImage
        self.message = message
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        VStack(spacing: Spacing.small) {
            Image(systemName: systemImage)
                .font(.system(size: 32))
                .foregroundStyle(.textSub)

            Text(message)
                .font(.app(.content2))
                .foregroundStyle(.textSub)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview("ImagePlaceholder") {
    VStack(spacing: 20) {
        WeeMoImagePlaceholder(systemImage: "building.2", size: 80)
        WeeMoImagePlaceholder(systemImage: "photo", size: 60)
        EmptyStatePlaceholder(message: "공간을 선택해주세요")
    }
    .padding()
}
