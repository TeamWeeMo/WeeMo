//
//  ReservationInfoSection.swift
//  WeeMo
//
//  Created by Reimos on 11/17/25.
//

import SwiftUI
import Kingfisher

// MARK: - Reservation Info Section

struct ReservationInfoSection: View {
    let userProfileImage: String?
    let userNickname: String
    let selectedDate: String
    let selectedTimeSlot: String
    let totalPrice: String

    var body: some View {
        VStack(spacing: Spacing.base) {
            // 헤더
            HStack(spacing: Spacing.small) {
                Image(systemName: "doc.text")
                    .font(.system(size: AppFontSize.s18.rawValue))
                    .foregroundColor(Color("textMain"))

                Text("예약 정보")
                    .font(.app(.headline3))
                    .foregroundColor(Color("textMain"))

                Spacer()
            }

            // 사용자 정보
            HStack(spacing: Spacing.medium) {
                // 프로필 이미지
                if let profileImageURL = userProfileImage, !profileImageURL.isEmpty {
                    KFImage(URL(string: profileImageURL))
                        .placeholder {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(Color("textSub"))
                                )
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: AppFontSize.s20.rawValue))
                                .foregroundColor(Color("textSub"))
                        )
                }

                // 닉네임
                Text(userNickname)
                    .font(.app(.subHeadline2))
                    .foregroundColor(Color("textMain"))

                Spacer()
            }

            Divider()

            // 예약 상세 정보
            VStack(spacing: Spacing.medium) {
                // 날짜
                ReservationInfoRow(
                    icon: "calendar",
                    title: "예약 날짜",
                    value: selectedDate
                )

                // 시간대
                ReservationInfoRow(
                    icon: "clock",
                    title: "이용 시간",
                    value: selectedTimeSlot
                )

                // 가격
                ReservationInfoRow(
                    icon: "creditcard",
                    title: "결제 금액",
                    value: totalPrice,
                    valueColor: Color("wmMain")
                )
            }
        }
        .padding(Spacing.base)
        .background(Color.white)
        .cornerRadius(Spacing.radiusMedium)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Reservation Info Row

struct ReservationInfoRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = Color("textMain")

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: AppFontSize.s16.rawValue))
                .foregroundColor(.textSub)
                .frame(width: 20)

            Text(title)
                .font(.app(.content1))
                .foregroundColor(.textSub)

            Spacer()

            Text(value)
                .font(.app(.subHeadline2))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.base) {
        ReservationInfoSection(
            userProfileImage: nil,
            userNickname: "홍길동",
            selectedDate: "2025년 11월 17일",
            selectedTimeSlot: "14:00 - 15:00",
            totalPrice: "15,000원"
        )
        .padding()

        ReservationInfoSection(
            userProfileImage: "https://example.com/profile.jpg",
            userNickname: "김철수",
            selectedDate: "2025년 12월 25일",
            selectedTimeSlot: "10:00 - 11:00",
            totalPrice: "30,000원"
        )
        .padding()
    }
    .background(Color("wmBg"))
}
