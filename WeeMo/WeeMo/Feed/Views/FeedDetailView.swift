//
//  FeedDetailView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/9/25.
//

import SwiftUI
import Kingfisher

// MARK: - Instagram Style Feed Detail

/// 인스타그램 스타일의 피드 상세화면
/// - 구조: 헤더(프로필) + 이미지 + 콘텐츠(인터랙션/본문)
/// - 이미지 높이 제한: 화면 너비의 1.25배 (5:4 비율)
struct FeedDetailView: View {
    // MARK: - Properties

    let item: FeedItem
    @Environment(\.dismiss) private var dismiss

    // 임시 상태 (추후 ViewModel로 이동)
    @State private var isLiked: Bool = false
    @State private var likeCount: Int

    // MARK: - Initializer

    init(item: FeedItem) {
        self.item = item
        self._likeCount = State(initialValue: item.likes.count)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 상단: 프로필 정보
                headerView

                // 중간: 게시글 이미지 (높이 제한 적용)
                imageView

                // 하단: 인터랙션 + 콘텐츠
                contentView
            }
        }
        .background(.wmBg)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // 공유 버튼 (ButtonWrapper)
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(.textMain)
                    .buttonWrapper {
                        // TODO: 공유 기능
                        print("상단 공유")
                    }
            }
        }
    }

    // MARK: - Subviews

    /// 상단 프로필 정보 (헤더)
    private var headerView: some View {
        HStack(spacing: Spacing.medium) {
            // 프로필 이미지 버튼
            ProfileImageButton(url: item.creator.profileImageURL, size: 36) {
                // TODO: 프로필 화면으로 이동
                print("프로필 탭: \(item.creator.nickname)")
            }

            // 닉네임
            Text(item.creator.nickname)
                .font(.app(.subHeadline2))
                .foregroundStyle(.textMain)

            Spacer()

            // 더보기 메뉴 버튼
            Image(systemName: "ellipsis")
                .foregroundStyle(.textMain)
                .font(.app(.subHeadline1))
                .buttonWrapper {
                    // TODO: 메뉴 (수정/삭제/신고 등)
                    print("더보기 메뉴")
                }
        }
        // Custom Modifier 활용: 헤더 패딩
        .feedDetailHeader()
    }

    /// 게시글 이미지 (높이 제한 적용)
    private var imageView: some View {
        KFImage(URL(string: item.imageURL))
            .placeholder {
                // 플레이스홀더는 정사각형으로 표시
                Rectangle()
                    .imagePlaceholder()
                    .aspectRatio(1.0, contentMode: .fit)
            }
            .retry(maxCount: 3, interval: .seconds(2))
            .resizable()
            // aspectRatio를 지정하지 않고 feedDetailImage에서 처리
            .scaledToFit()
            // Custom Modifier 활용: 이미지 높이 제한 (화면 너비의 1.25배)
            .feedDetailImage()
            // TODO: 여러 이미지 스와이프 기능 추가
    }

    /// 하단 콘텐츠 (인터랙션 + 본문)
    private var contentView: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // 인터랙션 버튼 (좋아요, 댓글, 공유, 북마크)
            interactionButtons

            // 좋아요 수
            if likeCount > 0 {
                Text("좋아요 \(likeCount)개")
                    .font(.app(.subHeadline2))
                    .foregroundStyle(.textMain)
            }

            // 닉네임 + 본문
            HStack(alignment: .top, spacing: Spacing.small) {
                Text(item.creator.nickname)
                    .font(.app(.subHeadline2))
                    .foregroundStyle(.textMain)

                Text(item.content)
                    .font(.app(.content2))
                    .foregroundStyle(.textMain)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 댓글 보기 버튼 (ButtonWrapper)
            if item.commentCount > 0 {
                Text("댓글 \(item.commentCount)개 모두 보기")
                    .font(.app(.content2))
                    .foregroundStyle(.textSub)
                    .buttonWrapper {
                        // TODO: 댓글 화면으로 이동
                        print("댓글 보기")
                    }
            }

            // 작성일 (상대적 시간)
            Text(timeAgoString(from: item.createdAt))
                .font(.app(.subContent2))
                .foregroundStyle(.textSub)
        }
        // Custom Modifier 활용: 콘텐츠 패딩
        .feedDetailContent()
    }

    // MARK: - Helper Methods

    /// 상대적 시간 문자열 생성 (예: "3시간 전")
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date,
            to: now
        )

        if let year = components.year, year > 0 {
            return "\(year)년 전"
        } else if let month = components.month, month > 0 {
            return "\(month)개월 전"
        } else if let day = components.day, day > 0 {
            return "\(day)일 전"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)시간 전"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)분 전"
        } else {
            return "방금 전"
        }
    }

    /// 인터랙션 버튼 바
    private var interactionButtons: some View {
        HStack(spacing: Spacing.base) {
            // 좋아요 버튼 (애니메이션 + 햅틱 내장)
            LikeButton(isLiked: $isLiked, likeCount: $likeCount)

            // 댓글 버튼
            InteractionButton(systemImage: "bubble.right") {
                // TODO: 댓글 작성 화면
                print("댓글 작성")
            }

            // 공유 버튼
            InteractionButton(systemImage: "paperplane") {
                // TODO: 공유 기능
                print("공유하기")
            }

            Spacer()

            // 북마크 버튼
            InteractionButton(systemImage: "bookmark") {
                // TODO: 북마크 기능
                print("북마크 추가")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FeedDetailView(item: MockFeedData.sampleFeeds[0])
    }
}

#Preview("좋아요 많은 게시글") {
    NavigationStack {
        FeedDetailView(item: MockFeedData.sampleFeeds[2])
    }
}
