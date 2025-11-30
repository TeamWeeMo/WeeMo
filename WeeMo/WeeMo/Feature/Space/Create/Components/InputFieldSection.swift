//
//  InputFieldSection.swift
//  WeeMo
//
//  Created by Reimos on 11/16/25.
//

import SwiftUI

struct InputFieldSection: View {
    @Binding var text: String
    
    let title: String
    let placeholder: String
    
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(title)
                .font(.app(.subHeadline2))
                .foregroundColor(.textMain)

            TextField(placeholder, text: $text)
                .font(.app(.content1))
                .padding(Spacing.medium)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(Spacing.radiusSmall)
                .keyboardType(keyboardType)
        }
    }
}
