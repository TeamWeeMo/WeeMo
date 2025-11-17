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
        .frame(width: 100, height: 100)
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.separator, lineWidth: 1)
        }
    }
}

struct ProfileGridSection: View {
    let columnCount: Int
    let items: [String]

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: columnCount)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(items.indices, id: \.self) { i in
                    ProfileGridCard(title: items[i])
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .frame(height: 400)
    }
}

struct HorizontalScrollSection: View {
    let items: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(items.indices, id: \.self) { i in
                    HorizontalMeetingCard(title: items[i])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(height: 116)  // 100 + 16(padding)
    }
}

struct HorizontalMeetingCard: View {
    let title: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.textSub)

            Text(title)
                .font(.app(.subContent2))
                .padding(8)
                .foregroundStyle(.wmBg)
        }
        .frame(width: 100, height: 100)
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.separator, lineWidth: 1)
        }
    }
}

struct LimitedGridSection: View {
    let columnCount: Int
    let items: [String]
    let maxRows: Int

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: columnCount)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(items.indices, id: \.self) { i in
                    ProfileGridCard(title: items[i])
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: CGFloat(maxRows) * 108)  // 100 + 8(spacing)
    }
}

struct TwoRowHorizontalSection: View {
    let items: [String]

    private var firstRowItems: [String] {
        let midIndex = (items.count + 1) / 2
        return Array(items.prefix(midIndex))
    }

    private var secondRowItems: [String] {
        let midIndex = (items.count + 1) / 2
        return Array(items.dropFirst(midIndex))
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 8) {
                // 첫 번째 행
                HStack(spacing: 12) {
                    ForEach(firstRowItems.indices, id: \.self) { i in
                        ProfileGridCard(title: firstRowItems[i])
                    }
                }

                // 두 번째 행
                HStack(spacing: 12) {
                    ForEach(secondRowItems.indices, id: \.self) { i in
                        ProfileGridCard(title: secondRowItems[i])
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(height: 216)  // 100 * 2 + 8(spacing) + 16(padding)
    }
}

#Preview {
    ProfileGridCard(title: "123")
}
