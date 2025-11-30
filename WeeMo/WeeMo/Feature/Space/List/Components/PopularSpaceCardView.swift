//
//  PopularSpaceCardView.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI
import Kingfisher

struct PopularSpaceCardView: View {
    let space: Space
    let cardWidth: CGFloat

    @State private var videoThumbnail: UIImage?

    // MARK: - Computed Properties

    /// 우선 표시할 미디어 (동영상 우선, 없으면 첫 이미지)
    private var priorityMediaURL: String? {
        // 동영상 우선 검색
        if let videoURL = space.imageURLs.first(where: { MeetVideoHelper.isVideoFile($0) }) {
            return videoURL
        }
        // 동영상이 없으면 첫 이미지
        return space.imageURLs.first
    }

    /// 선택된 미디어가 동영상인지 확인
    private var isVideoMedia: Bool {
        guard let mediaURL = priorityMediaURL else { return false }
        return MeetVideoHelper.isVideoFile(mediaURL)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 배경 미디어 (동영상 썸네일 또는 이미지)
            if let mediaURLString = priorityMediaURL {
                if isVideoMedia {
                    // 동영상 썸네일
                    videoThumbnailView
                } else {
                    // 이미지
                    if let imageURL = URL(string: FileRouter.fileURL(from: mediaURLString)) {
                        KFImage(imageURL)
                            .withAuthHeaders()
                            .placeholder {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        ProgressView()
                                    )
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: cardWidth, height: 180)
                            .clipped()
                    }
                }
            } else {
                // 미디어가 없는 경우
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    )
            }

            // 어두운 그라데이션 오버레이
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.7),
                    Color.clear
                ]),
                startPoint: .bottom,
                endPoint: .center
            )

            // 텍스트 정보
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("2025년 인기 파티룸")
                    .font(.app(.subHeadline1))
                    .foregroundColor(.white)
                Text("소중한 사람과 함께하는 특별한 연말 파티")
                    .font(.app(.subContent1))
                    .foregroundColor(.white)
            }
            .padding(Spacing.base)
        }
        .frame(width: cardWidth, height: 180)
        .cornerRadius(Spacing.radiusMedium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .task {
            // 동영상인 경우 썸네일 비동기 로드
            if isVideoMedia, let videoURL = priorityMediaURL {
                videoThumbnail = await MeetVideoHelper.extractThumbnail(from: videoURL)
            }
        }
    }

    // MARK: - Video Thumbnail View

    /// 동영상 썸네일 뷰 (재생 아이콘 포함)
    private var videoThumbnailView: some View {
        ZStack {
            if let thumbnail = videoThumbnail {
                // 썸네일 이미지
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: 180)
                    .clipped()
            } else {
                // 로딩 중
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                    )
                    .frame(width: cardWidth, height: 180)
            }

            // 재생 아이콘 오버레이
            Image(systemName: "play.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.white)
                .shadow(radius: 4)
        }
    }
}

struct PopularSpaceSectionView: View {
    let spaces: [Space]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            GeometryReader { geometry in
                let cardWidth = geometry.size.width - (Spacing.base * 2)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.base) {
                        ForEach(spaces.filter { $0.isPopular }) { space in
                            NavigationLink(value: space) {
                                PopularSpaceCardView(space: space, cardWidth: cardWidth)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, Spacing.base)
                }
            }
            .frame(height: 180)
        }
    }
}
