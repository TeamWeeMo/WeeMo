//
//  ProfileGridCard.swift
//  WeeMo
//
//  Created by Lee on 11/10/25.
//

import SwiftUI

struct ProfileGridCard: View {
    let title: String

    var body: some View {
        ZStack() {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.textSub)

            Text(title)
                .font(.app(.subContent2))
                .padding(8)
                .foregroundStyle(.wmBg)
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.separator, lineWidth: 1)
        }
    }
}

struct ProfileGridSection: View {
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    let items: [String]

    var body: some View {
        GeometryReader { geometry in
            let cardSize = (geometry.size.width - 32 - 16) / 3  // padding(16*2) + spacing(8*2)
            let gridHeight = cardSize * 3 + 16 + 12  // 3행 + spacing(8*2) + padding top(12)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(items.indices, id: \.self) { i in
                        ProfileGridCard(title: items[i])
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .frame(height: gridHeight)
        }
        .frame(height: 400)  // 3x3 그리드 영역 높이
    }
}

#Preview {
    ProfileGridCard(title: "123")
}
