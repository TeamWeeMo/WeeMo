//
//  MeetMapCardView.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//  Refactored by Watson22_YJ on 11/19/25.
//

import SwiftUI
import Kingfisher

// MARK: - 지도용 모임 카드
struct MeetMapCardView: View {
    let meet: Meet

    var body: some View {
        VStack() {
            // 이미지 영역
            imageSection
            // 정보 영역
            infoSection
        }
        .frame(width: 200)
        .background(.white)
        .cornerRadius(8)
        .cardShadow()
    }

    // MARK: - Subviews

    /// 이미지 섹션
    private var imageSection: some View {
        ZStack {
            if let imageURL = meet.firstImageURL {
                KFImage(URL(string: FileRouter.fileURL(from: imageURL)))
                    .withAuthHeaders()
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 200, height: 100)))
                    .placeholder {
                        placeholderView
                    }
                    .retry(maxCount: 2, interval: .seconds(1))
                    .onFailure { error in
                        print("이미지 로드 실패: \(error.localizedDescription)")
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 100)
                    .clipped()
                    .cornerRadius(8, corners: [.topLeft, .topRight])
            } else {
                placeholderView
            }
            // D-day 배지
            dDayBadge
        }
        .frame(width: 200, height: 100)
    }

    /// 플레이스홀더 뷰
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 200, height: 100)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 20))
                    .foregroundColor(.gray.opacity(0.5))
            )
    }

    /// D-day 배지
    private var dDayBadge: some View {
        VStack {
            HStack {
                Spacer()
                Text(meet.dDayText)
                    .font(.app(.subContent3))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    .background(dDayBackgroundColor(for: meet))
                    .cornerRadius(4)
            }
            .padding(.top, 6)
            .padding(.trailing, 6)
            Spacer()
        }
    }

    /// 정보 섹션
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(meet.title)
                .font(.app(.subContent1))
                .fontWeight(.semibold)
                .foregroundColor(.textMain)
                .lineLimit(1)

            HStack(spacing: Spacing.small) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundColor(.textSub)

                Text(meet.meetingDateText)
                    .font(.app(.subContent3))
                    .foregroundColor(.textSub)
            }


            HStack(spacing: Spacing.small) {
                Image(systemName: "mappin.square.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.textSub)

                Text(meet.spaceName)
                    .font(.app(.subContent3))
                    .foregroundColor(.textSub)
                    .lineLimit(1)
            }
            
            HStack {
                // 프로필 이미지
                if let profileImage = meet.creator.profileImageURL, !profileImage.isEmpty {
                    KFImage(URL(string: FileRouter.fileURL(from: profileImage)))
                        .withAuthHeaders()
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 16, height: 16)
                        .clipShape(Circle())
                } else {
                    profilePlaceholder
                }

                Text(meet.creator.nickname)
                    .font(.app(.subContent3))
                    .foregroundColor(.textSub)
                    .lineLimit(1)
            }

            HStack(spacing: Spacing.xSmall) {
                Text("참가비")
                    .font(.app(.subContent1))
                    .foregroundColor(.textSub)

                Text(meet.priceText)
                    .font(.app(.subContent1))
                    .fontWeight(.semibold)
                    .foregroundColor(.wmMain)

                Spacer()

                Text("\(meet.participants)/\(meet.capacity)명")
                    .font(.app(.subContent1))
                    .foregroundColor(.textSub)
            }
        }
        .padding(Spacing.medium)
    }
    
    private var profilePlaceholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 16, height: 16)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            )
    }
}
