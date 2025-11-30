//
//  FeedDetailModifier.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/9/25.
//

import SwiftUI

// MARK: - Feed Detail Header Modifier

/// 피드 상세화면 헤더 스타일 (프로필 영역)
private struct FeedDetailHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.medium)
    }
}

extension View {
    /// 피드 상세 헤더 스타일 적용
    func feedDetailHeader() -> some View {
        modifier(FeedDetailHeaderModifier())
    }
}

// MARK: - Feed Detail Image Modifier

/// 피드 상세화면 이미지 스타일
/// - 화면 너비를 넘지 않음
/// - 최대 높이 제한 (화면 너비의 1.25배, 약 5:4 비율)
private struct FeedDetailImageModifier: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .frame(width: geometry.size.width)
                // 최대 높이: 화면 너비의 1.25배 (5:4 비율 유지)
                // 인스타그램은 최대 4:5 비율까지 허용
                .frame(maxHeight: geometry.size.width * 1.25)
                .clipped()
        }
        // GeometryReader가 무한대로 확장되는 것을 방지
        .aspectRatio(contentMode: .fit)
    }
}

extension View {
    /// 피드 상세 이미지 스타일 적용 (높이 제한)
    func feedDetailImage() -> some View {
        modifier(FeedDetailImageModifier())
    }
}

// MARK: - Feed Detail Content Modifier

/// 피드 상세화면 콘텐츠 영역 스타일
private struct FeedDetailContentModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.medium)
    }
}

extension View {
    /// 피드 상세 콘텐츠 스타일 적용
    func feedDetailContent() -> some View {
        modifier(FeedDetailContentModifier())
    }
}
