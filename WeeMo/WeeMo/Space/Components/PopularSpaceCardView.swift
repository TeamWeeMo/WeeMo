//
//  PopularSpaceCardView.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI

struct PopularSpaceCardView: View {
    let space: Space

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 배경 이미지
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    // 실제 이미지가 있을 경우 AsyncImage 사용
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                )

            // 어두운 그라데이션 오버레이
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.7),
                    Color.clear
                ]),
                startPoint: .bottom,
                endPoint: .center
            )

            // 텍스트 정보
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(space.title)
                    .font(.app(.headline2))
                    .foregroundColor(.white)

                HStack(spacing: Spacing.xSmall) {
                    Image(systemName: "star.fill")
                        .font(.system(size: AppFontSize.s12.rawValue))
                        .foregroundColor(.yellow)

                    Text(space.formattedRating)
                        .font(.app(.content2))
                        .foregroundColor(.white)
                }
            }
            .padding(Spacing.base)
        }
        .frame(width: 280, height: 180)
        .cornerRadius(Spacing.radiusMedium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PopularSpaceSectionView: View {
    let spaces: [Space]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("인기 공간")
                .font(.app(.headline3))
                .foregroundColor(Color("textMain"))
                .padding(.horizontal, Spacing.base)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.medium) {
                    ForEach(spaces.filter { $0.isPopular }) { space in
                        PopularSpaceCardView(space: space)
                    }
                }
                .padding(.horizontal, Spacing.base)
            }
        }
    }
}

#Preview {
    PopularSpaceSectionView(spaces: Space.mockSpaces)
}
