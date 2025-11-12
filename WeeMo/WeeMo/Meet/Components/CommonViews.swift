//
//  CommonViews.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI

// MARK: - 공통 텍스트 필드
struct CommonTextField: View {
    let placeholder: String
    @Binding var text: String
    var isMultiline: Bool = false

    var body: some View {
        Group {
            if isMultiline {
                TextField(placeholder, text: $text, axis: .vertical)
                    .lineLimit(5...10)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .font(.app(.content1))
        .foregroundColor(Color("textMain"))
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .cardShadow()
    }
}

// MARK: - 공통 섹션 헤더
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.app(.subHeadline2))
            .foregroundColor(Color("textMain"))
    }
}

// MARK: - 공통 카드 컨테이너
struct CardContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .cardShadow()
    }
}

// MARK: - 공통 버튼
struct CommonButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.app(.content1))
                .foregroundColor(isSelected ? .white : Color("textMain"))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(isSelected ? Color.blue : Color.white)
                .cornerRadius(12)
                .cardShadow()
        }
    }
}

// MARK: - 커스텀 네비게이션 바
struct CustomNavigationBar: View {
    let onCancel: () -> Void
    let onComplete: () -> Void

    var body: some View {
        HStack {
            Button("취소") {
                onCancel()
            }
            .foregroundColor(.blue)
            .font(.app(.content1))

            Spacer()

            Button("완료") {
                onComplete()
            }
            .foregroundColor(.blue)
            .font(.app(.content1))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color("wmBg"))
    }
}

// MARK: - 이미지 플레이스홀더
struct ImagePlaceholder: View {
    let systemName: String
    let text: String
    let size: CGFloat

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: size))
                .foregroundColor(Color.gray.opacity(0.6))

            Text(text)
                .font(.app(.content2))
                .foregroundColor(Color("textSub"))
        }
    }
}