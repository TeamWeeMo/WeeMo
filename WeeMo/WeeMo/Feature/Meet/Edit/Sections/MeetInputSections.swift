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

// MARK: - 모집 인원 섹션
struct MeetCapacitySection: View {
    @Binding var capacity: Int
    @State private var maxCapacity = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "모집 인원")

            VStack(spacing: 16) {
                HStack {
                    Text("참가 인원")
                        .font(.app(.content2))
                        .foregroundColor(Color("textSub"))

                    Spacer()

                    HStack(spacing: 16) {
                        Button(action: {
                            if capacity > 1 {
                                capacity -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(capacity > 1 ? .wmMain : Color("textDisabled"))
                        }
                        .disabled(capacity <= 1)

                        Text("\(capacity)")
                            .font(.app(.headline2))
                            .foregroundColor(Color("textMain"))
                            .frame(minWidth: 30)

                        Button(action: {
                            if capacity < maxCapacity {
                                capacity += 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(capacity < maxCapacity ? .wmMain : Color("textDisabled"))
                        }
                        .disabled(capacity >= maxCapacity)
                    }
                }

                Divider()
                    .background(Color("divider"))

                HStack {
                    Text("최대 \(maxCapacity)명까지 모집 가능")
                        .font(.app(.subContent2))
                        .foregroundColor(Color("textSub"))

                    Spacer()
                }
            }
            .cardStyle()
        }
    }
}

// MARK: - 참가 비용 섹션
struct MeetPriceSection: View {
    @Binding var price: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "참가 비용")

            HStack {
                TextField("0", text: $price)
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
    @Binding var selectedGender: String
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
