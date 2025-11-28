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
                            category: category,
                            isSelected: selectedCategory == category,
                            selectedCategory: $selectedCategory
                        )
                    }
                }
                .padding(.horizontal, Spacing.base)
            }
            .frame(height: 44) // 명확한 높이 지정
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
        .zIndex(1) // 터치 우선순위 높임
    }
}

struct CategoryButton: View {
    let category: SpaceCategory
    let isSelected: Bool
    @Binding var selectedCategory: SpaceCategory

    var body: some View {
        Button(action: {
            selectedCategory = category
        }) {
            Text(category.rawValue)
                .font(.app(.content2))
                .foregroundColor(isSelected ? .wmMain : .textMain)
                .padding(.horizontal, Spacing.small)
                .frame(height: 44) // CategoryTabView의 ScrollView 높이와 동일
                .contentShape(Rectangle())
                .background(
                    VStack {
                        Spacer()
                        // 하단 하이라이팅 라인 (선택 시만 표시)
                        Rectangle()
                            .fill(isSelected ? Color.wmMain : Color.clear)
                            .frame(height: 2)
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CategoryTabView(selectedCategory: .constant(.all))
}
