//
//  SpaceDescriptionSection.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI

struct SpaceDescriptionSection: View {
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("공간 소개")
                .font(.app(.headline3))
                .foregroundColor(Color("textMain"))

            Text(description)
                .font(.app(.content2))
                .foregroundColor(Color("textSub"))
                .lineSpacing(4)
        }
    }
}

#Preview {
    SpaceDescriptionSection(description: "조용하고 아늑한 분위기의 카페입니다. 스터디나 작업하기 좋은 공간으로, 고속 WiFi와 충분한 콘센트를 제공합니다.")
        .padding()
}
