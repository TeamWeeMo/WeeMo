//
//  SearchBarButton.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/24/25.
//

import SwiftUI

// MARK: - Search Bar Button

/// 탭하면 검색 화면으로 이동하는 검색바 형태의 버튼
struct SearchBarButton: View {
    let placeholder: String
    let action: () -> Void

    // 커스터마이징 옵션
    var icon: String = "magnifyingglass"
    var backgroundColor: Color = .white
    var foregroundColor: Color = .gray
    var cornerRadius: CGFloat = Spacing.medium
    var showShadow: Bool = true

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(foregroundColor)
                    .padding(.leading, Spacing.medium)

                Text(placeholder)
                    .font(.app(.content2))
                    .foregroundColor(foregroundColor)
                    .padding(.vertical, Spacing.medium)

                Spacer()
            }
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .if(showShadow) { view in
                view.shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
    }
}

// MARK: - Conditional Modifier

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview

#Preview("모임 검색") {
    VStack {
        SearchBarButton(placeholder: "모임을 검색하세요") {
            print("모임 검색")
        }
        .padding()
    }
    .background(Color.gray.opacity(0.2))
}

#Preview("장소 검색") {
    VStack {
        SearchBarButton(
            placeholder: "장소를 검색하세요",
            action: { print("장소 검색") },
            icon: "mappin.and.ellipse"
        )
        .padding()
    }
    .background(Color.gray.opacity(0.2))
}

#Preview("커스텀") {
    VStack {
        SearchBarButton(
            placeholder: "해시태그로 검색",
            action: { print("해시태그 검색") },
            icon: "number",
            backgroundColor: Color(.systemGray6),
            showShadow: false
        )
        .padding()
    }
}
