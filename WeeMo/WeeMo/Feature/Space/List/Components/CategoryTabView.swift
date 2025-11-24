//
//  CategoryTabView.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI

struct CategoryTabView: View {
    @Binding var selectedCategory: SpaceCategory

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.small) {
                    ForEach(SpaceCategory.allCases, id: \.self) { category in
                        CategoryButton(
                            title: category.rawValue,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, Spacing.base)
            }
            .background(
                // 전체 하단 기본 라인
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.textSub.opacity(0.3))
                        .frame(height: 2)
                }
                .padding(.horizontal, Spacing.base)
            )
        }
        
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text(title)
                    .font(.app(.content2))
                    .foregroundColor(isSelected ? .wmMain : .textMain)
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, Spacing.small)
                    .background(
                        GeometryReader { geometry in
                            // 하단 하이라이팅 라인 (선택 시만 표시)
                            VStack {
                                Spacer()
                                Rectangle()
                                    .fill(isSelected ? Color.wmMain : Color.clear)
                                    .frame(width: geometry.size.width, height: 2)
                            }
                        }
                    )
            }
        }
    }
}

#Preview {
    CategoryTabView(selectedCategory: .constant(.all))
}
