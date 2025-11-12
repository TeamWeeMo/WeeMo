//
//  MeetingPhotoSection.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI

struct MeetingPhotoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "모임 사진")

            ImagePlaceholder(
                systemName: "camera",
                text: "사진 추가",
                size: 48
            )
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}