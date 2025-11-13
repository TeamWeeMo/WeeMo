//
//  MeetInputSections.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI

// MARK: - 모임 제목 섹션
struct MeetTitleSection: View {
    @Binding var title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "모임 이름")
            CommonTextField(placeholder: "모임 이름을 입력하세요", text: $title)
        }
    }
}

// MARK: - 모임 소개 섹션
struct MeetDescriptionSection: View {
    @Binding var description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "모임 소개")
            CommonTextField(
                placeholder: "모임에 대해 자세히 소개해주세요",
                text: $description,
                isMultiline: true
            )
        }
    }
}

// MARK: - 참가비용 섹션
struct MeetCapacitySection: View {
    @State private var capacity = "0"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "인원 참가 비용")

            HStack {
                TextField("0", text: $capacity)
                    .font(.app(.content1))
                    .foregroundColor(Color("textMain"))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)

                Text("원")
                    .font(.app(.content1))
                    .foregroundColor(Color("textSub"))
            }
            .cardStyle()
        }
    }
}

// MARK: - 성별 섹션
struct MeetGenderSection: View {
    @State private var selectedGender = "누구나"
    private let genderOptions = ["누구나", "남성만", "여성만"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "성별")

            HStack(spacing: 12) {
                ForEach(genderOptions, id: \.self) { option in
                    CommonButton(
                        title: option,
                        isSelected: selectedGender == option
                    ) {
                        selectedGender = option
                    }
                }
            }
        }
    }
}
