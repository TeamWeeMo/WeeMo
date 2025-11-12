//
//  FeedCardView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/8/25.
//

import SwiftUI
import Kingfisher

// MARK: - Pinterest Style Feed Card

struct FeedCardView: View {
    let item: FeedItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            // 이미지 (Kingfisher)
            // KFImage: Kingfisher의 SwiftUI 전용 컴포넌트
            KFImage(URL(string: item.imageURL))
                // placeholder: 이미지 로딩 중 표시할 뷰
                .placeholder {
                    // Custom Modifier 활용: 재사용 가능한 플레이스홀더 스타일
                    Rectangle()
                        .imagePlaceholder()
                }
                // retry: 네트워크 실패 시 재시도 (최대 3회, 2초 간격)
                .retry(maxCount: 3, interval: .seconds(2))
                // onFailure: 최종 실패 시 에러 핸들링
                .onFailure { error in
                    print("이미지 로드 실패: \(error.localizedDescription)")
                }
                .resizable()
                // aspectRatio: 이미지 비율 유지하며 크기 조정
                // item.aspectRatio: FeedItem마다 다른 높이 비율 (1.0~1.8)
                // contentMode: .fit -> 주어진 너비에 맞춰 높이 자동 계산
                .aspectRatio(item.aspectRatio, contentMode: .fit)
                // Custom Modifier 활용: 피드 카드 이미지 스타일
                .feedCardImage()

            // 내용 (2줄)
            // Custom Modifier 활용: 콘텐츠 텍스트 스타일
            Text(item.content)
                .feedContentText()

            // 하단 정보 (좋아요, 댓글)
            HStack(spacing: Spacing.small) {
                // Custom Modifier 활용: 정보 레이블 스타일
                Label("\(item.likes.count)", systemImage: "heart")
                    .infoLabel()

                Label("\(item.commentCount)", systemImage: "bubble.right")
                    .infoLabel()

                Spacer()
            }
            .padding(.horizontal, Spacing.xSmall)
            .padding(.bottom, Spacing.xSmall)
        }
        // Custom Modifier 활용: 카드 전체 스타일 (배경, 모서리, 그림자)
        .feedCardStyle()
    }

}

// MARK: - Preview

#Preview("Single Card") {
    FeedCardView(item: MockFeedData.sampleFeeds[0])
        .padding()
}

#Preview("Multiple Cards") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(MockFeedData.sampleFeeds.prefix(3)) { item in
                FeedCardView(item: item)
            }
        }
        .padding()
    }
}
