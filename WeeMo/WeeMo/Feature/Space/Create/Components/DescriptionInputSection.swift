//
//  DescriptionInputSection.swift
//  WeeMo
//
//  Created by Reimos on 11/16/25.
//

import SwiftUI

struct DescriptionInputSection: View {
    @Binding var description: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("공간 설명")
                .font(.app(.subHeadline2))
                .foregroundColor(.textMain)

            TextEditor(text: $description)
                .font(.app(.content1))
                .frame(height: 120)
                .padding(Spacing.small)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(Spacing.radiusSmall)
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.radiusSmall)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}
