//
//  SimpleMediaPickerSection.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/27/25.
//

import SwiftUI
import Kingfisher

// MARK: - Simple Media Picker Section

/// 간단한 미디어 피커 섹션 (커스텀 피커용)
struct SimpleMediaPickerSection: View {
    let title: String
    let maxCount: Int
    let selectedMediaItems: [MediaItem]
    let existingMediaURLs: [String]
    let shouldKeepExistingMedia: Bool
    let onAddTapped: () -> Void
    let onRemoveItem: (Int) -> Void
    let onRemoveExistingMedia: ((Int) -> Void)?

    init(
        title: String = "모임 미디어 (최대 5개)",
        maxCount: Int = 5,
        selectedMediaItems: [MediaItem],
        existingMediaURLs: [String] = [],
        shouldKeepExistingMedia: Bool = true,
        onAddTapped: @escaping () -> Void,
        onRemoveItem: @escaping (Int) -> Void,
        onRemoveExistingMedia: ((Int) -> Void)? = nil
    ) {
        self.title = title
        self.maxCount = maxCount
        self.selectedMediaItems = selectedMediaItems
        self.existingMediaURLs = existingMediaURLs
        self.shouldKeepExistingMedia = shouldKeepExistingMedia
        self.onAddTapped = onAddTapped
        self.onRemoveItem = onRemoveItem
        self.onRemoveExistingMedia = onRemoveExistingMedia
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(title)
                .font(.app(.subHeadline2))
                .foregroundStyle(.textMain)

            let hasExistingMedia = shouldKeepExistingMedia && !existingMediaURLs.isEmpty
            let hasNewMedia = !selectedMediaItems.isEmpty

            if hasExistingMedia || hasNewMedia {
                selectedMediaGrid
            } else {
                emptyStateButton
            }
        }
    }

    private var totalMediaCount: Int {
        let existingCount = shouldKeepExistingMedia ? existingMediaURLs.count : 0
        return existingCount + selectedMediaItems.count
    }

    // MARK: - Selected Media Grid

    private var selectedMediaGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) {
                // 기존 미디어 URL들 (서버에서 불러온 것)
                if shouldKeepExistingMedia {
                    ForEach(Array(existingMediaURLs.enumerated()), id: \.offset) { index, urlString in
                        ExistingMediaThumbnailItem(
                            urlString: urlString,
                            onRemove: onRemoveExistingMedia != nil ? {
                                onRemoveExistingMedia?(index)
                            } : nil
                        )
                    }
                }

                // 새로 선택한 미디어
                ForEach(Array(selectedMediaItems.enumerated()), id: \.offset) { index, item in
                    MediaThumbnailItem(
                        mediaItem: item,
                        onRemove: {
                            onRemoveItem(index)
                        }
                    )
                }

                // 추가 버튼
                if totalMediaCount < maxCount {
                    addButton
                }
            }
            .padding(.horizontal, 1)
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            onAddTapped()
        } label: {
            VStack(spacing: Spacing.xSmall) {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .foregroundStyle(.textSub)

                Text("추가")
                    .font(.app(.subContent1))
                    .foregroundStyle(.textSub)
            }
            .frame(width: 120, height: 120)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
        }
    }

    // MARK: - Empty State

    private var emptyStateButton: some View {
        Button {
            onAddTapped()
        } label: {
            VStack(spacing: Spacing.small) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 48))
                    .foregroundStyle(.textSub)

                Text("사진 또는 동영상 선택 (최대 \(maxCount)개)")
                    .font(.app(.content2))
                    .foregroundStyle(.textSub)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
        }
    }
}

// MARK: - Media Thumbnail Item

/// 미디어 썸네일 아이템 (삭제 버튼 포함)
struct MediaThumbnailItem: View {
    let mediaItem: MediaItem
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                Image(uiImage: mediaItem.thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))

                // 동영상 아이콘
                if mediaItem.type == .video {
                    Color.black.opacity(0.3)
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
            }

            // 삭제 버튼
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 24, height: 24)
                    )
            }
            .padding(Spacing.xSmall)
        }
    }
}

// MARK: - Existing Media Thumbnail Item

/// 기존 미디어 URL 썸네일 아이템 (서버에서 불러온 것)
struct ExistingMediaThumbnailItem: View {
    let urlString: String
    let onRemove: (() -> Void)?

    @State private var videoThumbnail: UIImage?
    @State private var isLoadingThumbnail = false

    private var isVideo: Bool {
        MeetVideoHelper.isVideoFile(urlString)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                if isVideo {
                    // 동영상 썸네일 표시
                    if let thumbnail = videoThumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
                    } else if isLoadingThumbnail {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 120)
                            .overlay(
                                ProgressView()
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
                    } else {
                        // 썸네일 로드 실패
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "video.slash")
                                    .font(.system(size: 30))
                                    .foregroundStyle(.gray)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
                    }

                    // 재생 아이콘
                    if videoThumbnail != nil {
                        Color.black.opacity(0.3)
                            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                    }
                } else if let url = URL(string: FileRouter.fileURL(from: urlString)) {
                    // 이미지 표시
                    KFImage(url)
                        .withAuthHeaders()
                        .placeholder {
                            ProgressView()
                                .frame(width: 120, height: 120)
                                .background(Color.gray.opacity(0.1))
                        }
                        .retry(maxCount: 3, interval: .seconds(2))
                        .onFailure { error in
                            print("이미지 로드 실패 (\(urlString)): \(error.localizedDescription)")
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
                } else {
                    // URL 파싱 실패 시 플레이스홀더
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundStyle(.textSub)
                        .frame(width: 120, height: 120)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
                }
            }
            .task(id: urlString) {
                if isVideo && videoThumbnail == nil {
                    isLoadingThumbnail = true
                    videoThumbnail = await MeetVideoHelper.extractThumbnail(from: urlString)
                    isLoadingThumbnail = false
                }
            }

            // 삭제 버튼 (onRemove가 있을 때만 표시)
            if let onRemove = onRemove {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 24, height: 24)
                        )
                }
                .padding(Spacing.xSmall)
            }
        }
    }
}

#Preview {
    VStack {
        SimpleMediaPickerSection(
            selectedMediaItems: [],
            onAddTapped: {},
            onRemoveItem: { _ in }
        )
        .padding()
    }
}
