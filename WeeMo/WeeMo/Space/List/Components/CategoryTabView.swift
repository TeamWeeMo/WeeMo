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
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.app(isSelected ? .subHeadline2 : .content1))
                .foregroundColor(isSelected ? .white : Color("textMain"))
                .padding(.horizontal, Spacing.base)
                .padding(.vertical, Spacing.small)
                .background(isSelected ? Color("wmMain") : Color("wmGray"))
                .cornerRadius(Spacing.radiusLarge)
        }
    }
}

#Preview {
    CategoryTabView(selectedCategory: .constant(.all))
}
