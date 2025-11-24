//
//  MaxCapacityInputSection.swift
//  WeeMo
//
//  Created by Reimos on 2025/11/21.
//

import SwiftUI

struct MaxCapacityInputSection: View {
    @Binding var maxCapacity: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("최대 인원")
                .font(.app(.subHeadline2))
                .foregroundColor(Color("textMain"))

            HStack {
                TextField("예) 6", text: $maxCapacity)
                    .font(.app(.content1))
                    .foregroundColor(Color("textMain"))
                    .keyboardType(.numberPad)
                    .padding(.horizontal, Spacing.base)
                    .padding(.vertical, Spacing.medium)
                    .background(Color.white)
                    .cornerRadius(Spacing.radiusSmall)

                Text("명")
                    .font(.app(.content1))
                    .foregroundColor(Color("textMain"))
            }
        }
    }
}

#Preview {
    MaxCapacityInputSection(maxCapacity: .constant("6"))
        .padding()
        .background(Color("wmBg"))
}
