//
//  EmptyStateView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/15/25.
//

import SwiftUI

// MARK: - Empty State View

/// 빈 상태를 표시하는 재사용 가능한 뷰
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.base) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.textSub)

            Text(title)
                .font(.app(.subHeadline1))
                .foregroundStyle(.textMain)

            Text(message)
                .font(.app(.content2))
                .foregroundStyle(.textSub)

            // 액션 버튼 (옵션)
            if let actionTitle = actionTitle, let action = action {
                Text(actionTitle)
                    .font(.app(.content1))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.base)
                    .padding(.vertical, Spacing.medium)
                    .background(.wmMain)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
                    .buttonWrapper {
                        action()
                    }
                    .padding(.top, Spacing.medium)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Preview

#Preview("버튼 있음") {
    EmptyStateView(
        icon: "photo.on.rectangle.angled",
        title: "아직 피드가 없습니다",
        message: "첫 피드를 작성해보세요!",
        actionTitle: "피드 작성하기"
    ) {
        print("액션 실행")
    }
}

#Preview("버튼 없음") {
    EmptyStateView(
        icon: "magnifyingglass",
        title: "검색 결과가 없습니다",
        message: "다른 키워드로 검색해보세요"
    )
}
