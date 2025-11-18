//
//  PopularToggleSection.swift
//  WeeMo
//
//  Created by Reimos on 11/16/25.
//

import SwiftUI

struct PopularToggleSection: View {
    @Binding var isPopular: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("인기 공간 여부")
                .font(.app(.subHeadline2))
                .foregroundColor(Color("textMain"))

            HStack(spacing: Spacing.medium) {
                Button(action: {
                    isPopular = false
                }) {
                    Text("일반")
                        .font(.app(.content1))
                        .foregroundColor(isPopular ? Color("textSub") : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(isPopular ? Color.gray.opacity(0.2) : Color("wmMain"))
                        .cornerRadius(Spacing.radiusSmall)
                }

                Button(action: {
                    isPopular = true
                }) {
                    Text("인기")
                        .font(.app(.content1))
                        .foregroundColor(isPopular ? .white : Color("textSub"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(isPopular ? Color("wmMain") : Color.gray.opacity(0.2))
                        .cornerRadius(Spacing.radiusSmall)
                }
            }
        }
    }
}
