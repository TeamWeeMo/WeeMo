//
//  ViewModifiers.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI

// MARK: - 카드 그림자 Modifier
struct CardShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 모서리 둥글게 하기 Modifier
struct RoundedCornersModifier: ViewModifier {
    let radius: CGFloat
    let corners: UIRectCorner

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - 공통 패딩 Modifier
struct CommonPaddingModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 20)
    }
}

// MARK: - 섹션 간격 Modifier
struct SectionSpacingModifier: ViewModifier {
    let spacing: CGFloat

    init(spacing: CGFloat = 24) {
        self.spacing = spacing
    }

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, spacing)
    }
}

// MARK: - 카드 스타일 Modifier
struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .cardShadow()
    }
}

// MARK: - 버튼 스타일 Modifier
struct CommonButtonStyleModifier: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .font(.app(.content1))
            .foregroundColor(isSelected ? .white : Color("textMain"))
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(isSelected ? Color.blue : Color.white)
            .cornerRadius(12)
            .cardShadow()
    }
}

// MARK: - Extension으로 쉽게 사용할 수 있도록 제공
extension View {
    func cardShadow() -> some View {
        modifier(CardShadowModifier())
    }

    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        modifier(RoundedCornersModifier(radius: radius, corners: corners))
    }

    func commonPadding() -> some View {
        modifier(CommonPaddingModifier())
    }

    func sectionSpacing(_ spacing: CGFloat = 24) -> some View {
        modifier(SectionSpacingModifier(spacing: spacing))
    }

    func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }

    func commonButtonStyle(isSelected: Bool) -> some View {
        modifier(CommonButtonStyleModifier(isSelected: isSelected))
    }
}

// MARK: - RoundedCorner Shape (기존 코드에서 이동)
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
