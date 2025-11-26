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
    let item: Feed

    // 동적으로 계산된 이미지 비율 저장
    // 초기값 1.0 (정사각형)으로 시작, 이미지 로드 후 실제 비율로 업데이트
    @State private var imageAspectRatio: CGFloat = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            // 이미지 (Kingfisher)
            // KFImage: Kingfisher의 SwiftUI 전용 컴포넌트
            // 리스트에서는 대표 이미지(첫 번째)만 표시
            KFImage(URL(string: item.thumbnailURL))
                // 피드 이미지 설정 (인증 + 재시도 + 비율 계산)
                .feedImageSetup(aspectRatio: $imageAspectRatio)
                // aspectRatio: 실제 이미지 비율 사용
                .aspectRatio(imageAspectRatio, contentMode: .fit)
                // Custom Modifier 활용: 피드 카드 이미지 스타일
                .feedCardImage()

            // 내용 (2줄)
            // Custom Modifier 활용: 콘텐츠 텍스트 스타일
            Text(item.content)
                .feedContentText()
                .padding(.bottom, Spacing.xSmall)
        }
        // Custom Modifier 활용: 카드 전체 스타일 (배경, 모서리, 그림자)
        .feedCardStyle()
    }
}

// MARK: - Preview

//#Preview("Single Card") {
//    FeedCardView(item: MockFeedData.sampleFeeds[0])
//        .padding()
//}
//
//#Preview("Multiple Cards") {
//    ScrollView {
//        VStack(spacing: 16) {
//            ForEach(MockFeedData.sampleFeeds.prefix(3)) { item in
//                FeedCardView(item: item)
//            }
//        }
//        .padding()
//    }
//}
