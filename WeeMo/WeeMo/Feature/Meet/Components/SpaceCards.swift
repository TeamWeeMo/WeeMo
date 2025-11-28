//
//  SpaceCards.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/27/25.
//

import SwiftUI

/// 선택된 공간 카드 (예약 정보 포함)
struct SelectedSpaceCard: View {
    let space: Space
    let reservationDate: Date?
    let reservationStartHour: Int?
    let reservationTotalHours: Int
    let totalHours: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.medium) {
                // 공간 이미지
                SpaceImageView(
                    imageURL: space.imageURLs.first,
                    size: 80,
                    cornerRadius: Spacing.radiusSmall,
                    placeholderIcon: "building.2"
                )

                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text(space.title)
                        .font(.app(.subHeadline2))
                        .foregroundStyle(.textMain)
                        .lineLimit(1)

                    Text(space.address)
                        .font(.app(.content2))
                        .foregroundStyle(.textSub)
                        .lineLimit(1)

                    Text(space.formattedPrice)
                        .font(.app(.content2))
                        .foregroundStyle(.wmMain)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.textSub)
            }

            Divider()

            // 추가 정보 (예약일+시간, 최대 인원, 이용시간, 총비용)
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                SpaceInfoRow(
                    title: "예약 일시",
                    value: formattedReservationDateTime()
                )
                SpaceInfoRow(
                    title: "최대 인원",
                    value: "\(space.maxPeople)명"
                )
                SpaceInfoRow(
                    title: "이용 시간",
                    value: "\(totalHours)시간"
                )
                SpaceInfoRow(
                    title: "총 비용",
                    value: "\((space.pricePerHour * totalHours).formatted())원"
                )
            }
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                .fill(Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                .stroke(Color.wmMain.opacity(0.3), lineWidth: 1)
        )
    }

    /// 예약 날짜+시간 포맷팅
    private func formattedReservationDateTime() -> String {
        guard let date = reservationDate,
              let startHour = reservationStartHour else {
            return "예약 정보 없음"
        }

        let endHour = startHour + reservationTotalHours
        return ReservationFormatter.formattedDateTime(
            date: date,
            startHour: startHour,
            endHour: endHour
        )
    }
}

// MARK: - Space Info Row

/// 공간 정보 행 (제목 - 값)
struct SpaceInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.app(.content2))
                .foregroundStyle(.textSub)

            Spacer()

            Text(value)
                .font(.app(.content2))
                .foregroundStyle(.textMain)
        }
    }
}

// MARK: - Meet Space Card (for detail view)

/// Meet 공간 카드 (상세 화면용 - Meet 정보 기반)
struct MeetSpaceCard: View {
    let spaceName: String
    let address: String
    let spaceImageURL: String?
    let reservationScheduleText: String
    let priceText: String
    let imageSize: CGFloat

    init(
        spaceName: String,
        address: String,
        spaceImageURL: String?,
        reservationScheduleText: String,
        priceText: String,
        imageSize: CGFloat = 60
    ) {
        self.spaceName = spaceName
        self.address = address
        self.spaceImageURL = spaceImageURL
        self.reservationScheduleText = reservationScheduleText
        self.priceText = priceText
        self.imageSize = imageSize
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.medium) {
                // 공간 이미지
                SpaceImageView(
                    imageURL: spaceImageURL,
                    size: imageSize,
                    cornerRadius: Spacing.radiusSmall,
                    placeholderIcon: "building.2"
                )

                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text(spaceName)
                        .font(.app(.subContent1))
                        .fontWeight(.semibold)
                        .foregroundStyle(.textMain)
                        .lineLimit(1)

                    Text(address)
                        .font(.app(.subContent1))
                        .foregroundStyle(.textSub)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.wmMain)
            }

            Divider()

            // 예약 시간 정보
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                HStack {
                    Text("예약 시간")
                        .font(.app(.subContent1))
                        .foregroundStyle(.textSub)

                    Spacer()

                    Text(reservationScheduleText)
                        .font(.app(.subContent1))
                        .fontWeight(.semibold)
                        .foregroundStyle(.textSub)
                }

                HStack {
                    Text("참가비용")
                        .font(.app(.subContent1))
                        .foregroundStyle(.textSub)

                    Spacer()

                    Text(priceText)
                        .font(.app(.subContent1))
                        .fontWeight(.semibold)
                        .foregroundStyle(.wmMain)
                }
            }
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                .fill(Color.wmGray.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                .stroke(Color.wmMain.opacity(0.3), lineWidth: 1)
        )
    }
}

