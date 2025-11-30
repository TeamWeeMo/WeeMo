//
//  FacilityToggleSection.swift
//  WeeMo
//
//  Created by Reimos on 2025/11/21.
//

import SwiftUI

struct FacilityToggleSection: View {
    @Binding var hasParking: Bool
    @Binding var hasRestroom: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("편의시설")
                .font(.app(.subHeadline2))
                .foregroundColor(.textMain)

            VStack(spacing: Spacing.small) {
                // 주차 가능 여부
                HStack {
                    Image(systemName: hasParking ? "checkmark.square.fill" : "square")
                        .foregroundColor(hasParking ? Color("wmMain") : Color("textSub"))
                        .font(.system(size: 22))

                    Text("주차 가능")
                        .font(.app(.content1))
                        .foregroundColor(.textMain)

                    Spacer()

                    Toggle("", isOn: $hasParking)
                        .labelsHidden()
                        .tint(.wmMain)
                }
                .padding(.vertical, Spacing.xSmall)

                Divider()
                    .background(Color("wmGray"))

                // 화장실 여부
                HStack {
                    Image(systemName: hasRestroom ? "checkmark.square.fill" : "square")
                        .foregroundColor(hasRestroom ? Color("wmMain") : Color("textSub"))
                        .font(.system(size: 22))

                    Text("화장실 있음")
                        .font(.app(.content1))
                        .foregroundColor(.textMain)

                    Spacer()

                    Toggle("", isOn: $hasRestroom)
                        .labelsHidden()
                        .tint(.wmMain)
                }
                .padding(.vertical, Spacing.xSmall)
            }
            .padding(Spacing.base)
            .background(Color.white)
            .cornerRadius(Spacing.radiusMedium)
        }
    }
}

#Preview {
    FacilityToggleSection(
        hasParking: .constant(true),
        hasRestroom: .constant(false)
    )
    .padding()
}
