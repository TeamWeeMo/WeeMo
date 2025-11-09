//
//  AllSpaceListView.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI

struct SpaceListCardView: View {
    let space: Space

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            // 이미지
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                )
                .cornerRadius(Spacing.radiusMedium)

            // 제목
            Text(space.title)
                .font(.app(.subHeadline2))
                .foregroundColor(Color("textMain"))
                .lineLimit(1)

            // 주소
            Text(space.address)
                .font(.app(.content4))
                .foregroundColor(Color("textSub"))
                .lineLimit(1)

            // 별점과 가격
            HStack {
                HStack(spacing: Spacing.xSmall) {
                    Image(systemName: "star.fill")
                        .font(.system(size: AppFontSize.s12.rawValue))
                        .foregroundColor(.yellow)

                    Text(space.formattedRating)
                        .font(.app(.subContent1))
                        .foregroundColor(Color("textMain"))
                }

                Spacer()

                Text(space.formattedPrice)
                    .font(.app(.subHeadline2))
                    .foregroundColor(Color("wmMain"))
            }
        }
        .padding(Spacing.medium)
        .background(Color.white)
        .cornerRadius(Spacing.radiusMedium)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct AllSpaceListView: View {
    let spaces: [Space]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("모든 공간")
                .font(.app(.headline3))
                .foregroundColor(Color("textMain"))
                .padding(.horizontal, Spacing.base)

            LazyVStack(spacing: Spacing.base) {
                ForEach(spaces) { space in
                    SpaceListCardView(space: space)
                        .padding(.horizontal, Spacing.base)
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        AllSpaceListView(spaces: Space.mockSpaces)
    }
}
