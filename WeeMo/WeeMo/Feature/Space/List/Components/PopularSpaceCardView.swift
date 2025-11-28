//
//  PopularSpaceCardView.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI
import Kingfisher

struct PopularSpaceCardView: View {
    let space: Space
    let cardWidth: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 배경 이미지
            if let imageURLString = space.imageURLs.first,
               let imageURL = URL(string: FileRouter.fileURL(from: imageURLString)) {
                KFImage(imageURL)
                    .withAuthHeaders()
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                            )
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: 180)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    )
            }

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
                Text("2025년 인기 파티룸")
                    .font(.app(.subHeadline1))
                    .foregroundColor(.white)
                Text("소중한 사람과 함께하는 특별한 연말 파티")
                    .font(.app(.subContent1))
                    .foregroundColor(.white)
            }
            .padding(Spacing.base)
        }
        .frame(width: cardWidth, height: 180)
        .cornerRadius(Spacing.radiusMedium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PopularSpaceSectionView: View {
    let spaces: [Space]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            GeometryReader { geometry in
                let cardWidth = geometry.size.width - (Spacing.base * 2)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.base) {
                        ForEach(spaces.filter { $0.isPopular }) { space in
                            NavigationLink(value: space) {
                                PopularSpaceCardView(space: space, cardWidth: cardWidth)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, Spacing.base)
                }
            }
            .frame(height: 180)
        }
    }
}
