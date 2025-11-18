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

            Text(filteredDescription)
                .font(.app(.content2))
                .foregroundColor(Color("textSub"))
                .lineSpacing(4)
        }
    }
    
    // 해시태그 제거된 공간 소개
    private var filteredDescription: String {
        // " #" (공백 + 해시태그)를 기준으로 문자열을 나눔
        // 그 중 첫 번째 부분(본문)을 가져옴
        let mainText = description.components(separatedBy: " #").first ?? description
        
        // 앞뒤 공백 제거
        return mainText.trimmingCharacters(in: .whitespaces)
    }
}

#Preview {
    SpaceDescriptionSection(description: "조용하고 아늑한 분위기의 카페입니다. 스터디나 작업하기 좋은 공간으로, 고속 WiFi와 충분한 콘센트를 제공합니다.")
        .padding()
}
