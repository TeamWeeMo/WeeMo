//
//  SpaceInfoSection.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI

struct SpaceInfoSection: View {
    let space: Space

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // 제목
            Text(space.title)
                .font(.app(.headline1))
                .foregroundColor(Color("textMain"))

            // 주소
            HStack(spacing: Spacing.small) {
                Image(systemName: "mappin.circle")
                    .font(.system(size: AppFontSize.s16.rawValue))
                    .foregroundColor(Color("textSub"))

                Text(space.address)
                    .font(.app(.content2))
                    .foregroundColor(Color("textSub"))
            }

            // 별점
            HStack(spacing: Spacing.small) {
                Image(systemName: "star.fill")
                    .font(.system(size: AppFontSize.s16.rawValue))
                    .foregroundColor(.yellow)

                Text(space.formattedDetailRating)
                    .font(.app(.subHeadline2))
                    .foregroundColor(Color("textMain"))
            }

            // 가격
            HStack(spacing: Spacing.small) {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: AppFontSize.s16.rawValue))
                    .foregroundColor(Color("wmMain"))

                Text(space.formattedPrice)
                    .font(.app(.subHeadline2))
                    .foregroundColor(Color("wmMain"))
            }

            // 주차 가능
            if space.hasParking {
                HStack(spacing: Spacing.small) {
                    Image(systemName: "car.fill")
                        .font(.system(size: AppFontSize.s16.rawValue))
                        .foregroundColor(Color("textSub"))

                    Text("주차 가능")
                        .font(.app(.content2))
                        .foregroundColor(Color("textSub"))
                }
            }
        }
    }
}

#Preview {
    SpaceInfoSection(space: Space.mockSpaces[0])
        .padding()
}
