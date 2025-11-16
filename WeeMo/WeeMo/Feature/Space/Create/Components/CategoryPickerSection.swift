//
//  CategoryPickerSection.swift
//  WeeMo
//
//  Created by Reimos on 11/16/25.
//

import SwiftUI

struct CategoryPickerSection: View {
    @Binding var selectedCategory: SpaceCategory

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("카테고리")
                .font(.app(.subHeadline2))
                .foregroundColor(Color("textMain"))

            Picker("카테고리 선택", selection: $selectedCategory) {
                ForEach(SpaceCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}
