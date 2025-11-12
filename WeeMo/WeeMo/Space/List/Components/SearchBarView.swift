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
                .foregroundColor(Color("textSub"))
                .font(.system(size: AppFontSize.s16.rawValue))

            TextField("", text: $searchText, prompt: Text("공간을 검색하세요")
                .foregroundColor(Color("textSub"))
                .font(.app(.content2)))
                .font(.app(.content1))
                .foregroundColor(Color("textMain"))
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.medium)
        .background(Color("wmGray"))
        .cornerRadius(Spacing.radiusSmall)
    }
}

#Preview {
    SearchBarView(searchText: .constant(""))
        .padding()
}
