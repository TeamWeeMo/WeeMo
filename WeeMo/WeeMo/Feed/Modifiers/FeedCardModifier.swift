//
//  FeedCardModifier.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/8/25.
//

import SwiftUI

// MARK: - Feed Card Style Modifier

/// 피드 카드에 공통적으로 적용되는 스타일 (배경, 모서리, 그림자)
private struct FeedCardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.wmGray)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

extension View {
    /// 피드 카드 스타일 적용
    /// - Returns: 배경, 모서리, 그림자가 적용된 뷰
    func feedCardStyle() -> some View {
        modifier(FeedCardStyleModifier())
    }
}

// MARK: - Image Placeholder Modifier

/// 이미지 로딩 플레이스홀더 스타일
/// Shape에만 적용 가능 (Rectangle, Circle 등)
private struct ImagePlaceholderModifier<S: Shape>: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay {
                ProgressView()
            }
    }
}

extension Shape {
    /// 이미지 플레이스홀더 스타일 적용 (Shape 전용)
    /// - Returns: 회색 배경 + 로딩 인디케이터
    func imagePlaceholder() -> some View {
        self
            .fill(Color.gray.opacity(0.2))
            .overlay {
                ProgressView()
            }
    }
}

// MARK: - Feed Card Image Modifier

/// 피드 카드 이미지 스타일 (모서리, 클리핑)
private struct FeedCardImageModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
            .clipped()
    }
}

extension View {
    /// 피드 카드 이미지 스타일 적용
    /// - Returns: 모서리가 둥글고 클리핑된 이미지
    func feedCardImage() -> some View {
        modifier(FeedCardImageModifier())
    }
}

// MARK: - Tappable Card Modifier

/// 카드 탭 제스처 + 애니메이션
private struct TappableCardModifier: ViewModifier {
    let action: () -> Void
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            // 탭 시 약간 축소되는 애니메이션
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onTapGesture {
                // 햅틱 피드백
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()

                action()
            }
            // 롱프레스 감지로 눌림 상태 추적
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onChanged { _ in
                        isPressed = true
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

extension View {
    /// 탭 가능한 카드 스타일 적용 (애니메이션 + 햅틱)
    /// - Parameter action: 탭 시 실행할 액션
    /// - Returns: 탭 제스처와 애니메이션이 적용된 뷰
    func tappableCard(action: @escaping () -> Void) -> some View {
        modifier(TappableCardModifier(action: action))
    }
}

// MARK: - Content Text Modifier

/// 피드 콘텐츠 텍스트 스타일 (2줄 제한, 정렬, 패딩)
private struct FeedContentTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.app(.content2))
            .foregroundStyle(.textMain)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, Spacing.xSmall)
    }
}

extension View {
    /// 피드 콘텐츠 텍스트 스타일 적용
    /// - Returns: 폰트, 색상, 줄 제한이 적용된 텍스트
    func feedContentText() -> some View {
        modifier(FeedContentTextModifier())
    }
}

// MARK: - Info Label Modifier

/// 좋아요/댓글 등 정보 레이블 스타일
private struct InfoLabelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.app(.subContent1))
            .foregroundStyle(.textSub)
    }
}

extension View {
    /// 정보 레이블 스타일 적용
    /// - Returns: 작은 폰트 + 보조 색상
    func infoLabel() -> some View {
        modifier(InfoLabelModifier())
    }
}
