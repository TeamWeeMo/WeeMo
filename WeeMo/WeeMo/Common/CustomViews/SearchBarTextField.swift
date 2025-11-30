//
//  SearchBarTextField.swift
//  WeeMo
//
//  버튼 검색이 가능한 텍스트 필드 형태의 검색바
//

import SwiftUI

// MARK: - Search Bar TextField

/// 버튼 검색이 가능한 텍스트 필드 형태의 검색바
struct SearchBarTextField: View {
    @Binding var text: String
    var placeholder: String
    var onSearch: () -> Void
    var showClearButton: Bool

    init(
        text: Binding<String>,
        placeholder: String = "검색하세요",
        onSearch: @escaping () -> Void = {},
        showClearButton: Bool = true
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSearch = onSearch
        self.showClearButton = showClearButton
    }

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 8)

            TextField(placeholder, text: $text)
                .font(.app(.content2))
                .padding(.vertical, 8)
                .padding(.trailing, 8)
                .onSubmit {
                    onSearch()
                }

            if showClearButton && !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 8)
            }

            // 검색 버튼
            Button(action: onSearch) {
                Text("검색")
                    .font(.app(.content2))
                    .foregroundColor(.wmMain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .padding(.trailing, 4)
        }
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 20) {
        SearchBarTextField(
            text: .constant(""),
            placeholder: "모임을 검색하세요",
            onSearch: { print("Search!") }
        )
        .padding()

        SearchBarTextField(
            text: .constant("검색어"),
            placeholder: "모임을 검색하세요",
            onSearch: { print("Search!") }
        )
        .padding()
    }
}
