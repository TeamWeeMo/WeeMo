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
            if let firstImageURL = meet.imageURLs.first, !firstImageURL.isEmpty {
                let fullImageURL = firstImageURL.hasPrefix("http") ? firstImageURL : FileRouter.fileURL(from: firstImageURL)
                if let encodedURL = fullImageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: encodedURL) {
                    KFImage(url)
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
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.wmMain)
                        .frame(width: 40, height: 18)
                    Text(meet.dDayText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                }
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
                .foregroundColor(.textMain)
                .lineLimit(1)

            Text(meet.meetingDateText)
                .font(.app(.subContent3))
                .foregroundColor(.textSub)
                .lineLimit(1)

            Text(meet.spaceName)
                .font(.app(.subContent3))
                .foregroundColor(.textSub)
                .lineLimit(1)

            HStack {
                Text(meet.priceText)
                    .font(.app(.subContent3))
                    .foregroundColor(.textSub)

                Spacer()

                Text("0/\(meet.capacity)명")
                    .font(.app(.subContent3))
                    .foregroundColor(.textSub)
            }
        }
        .padding(Spacing.medium)
    }
}
