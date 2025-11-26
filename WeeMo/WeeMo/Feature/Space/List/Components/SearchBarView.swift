//
//  SearchBarView.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSub)
                .font(.system(size: AppFontSize.s16.rawValue))

            TextField("", text: $searchText, prompt: Text("공간을 검색하세요")
                .foregroundColor(.textSub)
                .font(.app(.content2)))
                .font(.app(.content1))
                .foregroundColor(.textMain)
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.medium)
        .background(.wmGray)
        .cornerRadius(Spacing.radiusSmall)
    }
}

#Preview {
    SearchBarView(searchText: .constant(""))
        .padding()
}
