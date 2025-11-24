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
//TODO: - 모임 카드뷰 재사용 고민
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
            let fullImageURL = FileRouter.fileURL(from: meet.imageName)
            KFImage(URL(string: fullImageURL))
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
            // D-day 배지
            dDayBadge
        }
        .frame(width: 200, height: 100)
    }

    /// 플레이스홀더 뷰
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 200, height: 140)
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
                        .frame(width: 30, height: 16)
//                    Text(meet.daysLeft)
                    Text("D-2")
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
//            Text(meet.title)
            Text("모임 제목입니다 다진홍차")
                .font(.app(.subContent1))
                .foregroundColor(.textMain)
                .lineLimit(1)

//            Text(meet.date)
            Text("11월 21일 (금)")
                .font(.app(.subContent3))
                .foregroundColor(.textSub)
                .lineLimit(1)

//            Text(meet.location)
            Text("서울시 영등포구 문래동 2가 33")
                .font(.app(.subContent3))
                .foregroundColor(.textSub)
                .lineLimit(1)

            HStack {
//                Text(meet.price)
                Text("10,000원")
                    .font(.app(.subContent3))
                    .foregroundColor(.textSub)

                Spacer()

//                Text(meet.participants)
                Text("3/4 명")
                    .font(.app(.subContent3))
                    .foregroundColor(.textSub)
            }
        }
        .padding(Spacing.medium)
    }
}

#Preview {
    MeetMapCardView(meet: Meet(
        postId: "2",
        title: "긴 제목의 모임입니다 테스트",
        date: "2025.11.20",
        location: "홍대",
        address: "서울 마포구",
        price: "무료",
        participants: "6/10명",
        imageName: "",
        daysLeft: "D-8",
        latitude: 37.5,
        longitude: 127.0
    ))
}
