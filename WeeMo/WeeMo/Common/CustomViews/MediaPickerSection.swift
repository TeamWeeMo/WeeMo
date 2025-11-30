//
//  MediaPickerSection.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/27/25.
//

import SwiftUI
import PhotosUI
import Kingfisher

// MARK: - Media Picker Section

/// 미디어 선택 섹션 (이미지 + 동영상 통합)
struct MediaPickerSection: View {
    // MARK: - Configuration

    let title: String
    let maxCount: Int
    let layout: MediaPickerLayout

    // MARK: - Bindings

    @Binding var selectedMediaItems: [MediaItem]
    @Binding var selectedPhotoItems: [PhotosPickerItem]
    @Binding var existingMediaURLs: [String]
    @Binding var shouldKeepExistingMedia: Bool

    // MARK: - State

    @State private var isDisabled: Bool = false
    @State private var isLoading: Bool = false

    // MARK: - Computed Properties

    private var totalMediaCount: Int {
        let existingCount = shouldKeepExistingMedia ? existingMediaURLs.count : 0
        return existingCount + selectedMediaItems.count
    }

    private var remainingSlots: Int {
        max(0, maxCount - totalMediaCount)
    }

    // MARK: - Initializer

    init(
        title: String = "사진 및 동영상",
        maxCount: Int = 5,
        layout: MediaPickerLayout = .horizontal,
        selectedMediaItems: Binding<[MediaItem]>,
        selectedPhotoItems: Binding<[PhotosPickerItem]>,
        existingMediaURLs: Binding<[String]> = .constant([]),
        shouldKeepExistingMedia: Binding<Bool> = .constant(true)
    ) {
        self.title = title
        self.maxCount = maxCount
        self.layout = layout
        self._selectedMediaItems = selectedMediaItems
        self._selectedPhotoItems = selectedPhotoItems
        self._existingMediaURLs = existingMediaURLs
        self._shouldKeepExistingMedia = shouldKeepExistingMedia
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // 섹션 타이틀
            HStack {
                Text("\(title) (최대 \(maxCount)개)")
                    .font(.app(.subHeadline2))
                    .foregroundStyle(.textMain)

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            // 미디어 영역
            if totalMediaCount > 0 {
                mediaView
            } else {
                emptyStateView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var mediaView: some View {
        switch layout {
        case .horizontal:
            horizontalMediaView
        case .grid:
            gridMediaView
        }
    }

    /// 가로 스크롤 레이아웃
    private var horizontalMediaView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) {
                // 기존 미디어 (서버에서 로드)
                if shouldKeepExistingMedia {
                    ForEach(Array(existingMediaURLs.enumerated()), id: \.offset) { index, mediaURL in
                        existingMediaCell(mediaURL: mediaURL, index: index)
                    }
                }

                // 새로 선택한 미디어
                ForEach(Array(selectedMediaItems.enumerated()), id: \.offset) { index, item in
                    newMediaCell(item: item, index: index)
                }

                // 추가 버튼
                if totalMediaCount < maxCount {
                    addButton
                }
            }
            .padding(.horizontal, 1)
        }
    }

    /// 그리드 레이아웃
    private var gridMediaView: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Spacing.small),
                GridItem(.flexible(), spacing: Spacing.small),
                GridItem(.flexible(), spacing: Spacing.small)
            ],
            spacing: Spacing.small
        ) {
            // 기존 미디어
            if shouldKeepExistingMedia {
                ForEach(Array(existingMediaURLs.enumerated()), id: \.offset) { index, mediaURL in
                    existingMediaGridCell(mediaURL: mediaURL, index: index)
                }
            }

            // 새로 선택한 미디어
            ForEach(Array(selectedMediaItems.enumerated()), id: \.offset) { index, item in
                newMediaGridCell(item: item, index: index)
            }

            // 추가 버튼
            if totalMediaCount < maxCount {
                addGridButton
            }
        }
    }

    /// 빈 상태 (미디어 없음)
    private var emptyStateView: some View {
        PhotosPicker(
            selection: $selectedPhotoItems,
            maxSelectionCount: maxCount,
            matching: .any(of: [.images, .videos])
        ) {
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
        .disabled(isDisabled)
    }

    // MARK: - Horizontal Layout Cells

    /// 기존 미디어 셀 (가로 스크롤)
    private func existingMediaCell(mediaURL: String, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            let fullMediaURL = mediaURL.hasPrefix("http") ? mediaURL : FileRouter.fileURL(from: mediaURL)
            if let encodedURL = fullMediaURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: encodedURL) {

                let isVideo = isVideoURL(mediaURL)

                ZStack {
                    KFImage(url)
                        .withAuthHeaders()
                        .placeholder {
                            mediaPlaceholder
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))

                    // 동영상 아이콘 오버레이
                    if isVideo {
                        videoOverlay
                    }
                }
            } else {
                mediaPlaceholder
            }

            deleteButton {
                removeExistingMedia(at: index)
            }
        }
    }

    /// 새 미디어 셀 (가로 스크롤)
    private func newMediaCell(item: MediaItem, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                Image(uiImage: item.thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))

                // 동영상 아이콘 오버레이
                if item.type == .video {
                    videoOverlay
                }
            }

            deleteButton {
                removeNewMedia(at: index)
            }
        }
    }

    /// 추가 버튼 (가로 스크롤)
    private var addButton: some View {
        PhotosPicker(
            selection: $selectedPhotoItems,
            maxSelectionCount: remainingSlots,
            matching: .any(of: [.images, .videos])
        ) {
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
        .disabled(isDisabled)
    }

    // MARK: - Grid Layout Cells

    /// 기존 미디어 셀 (그리드)
    private func existingMediaGridCell(mediaURL: String, index: Int) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                let fullMediaURL = mediaURL.hasPrefix("http") ? mediaURL : FileRouter.fileURL(from: mediaURL)
                if let encodedURL = fullMediaURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: encodedURL) {

                    let isVideo = isVideoURL(mediaURL)

                    ZStack {
                        KFImage(url)
                            .withAuthHeaders()
                            .placeholder {
                                mediaPlaceholder
                            }
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSmall))

                        // 동영상 아이콘 오버레이
                        if isVideo {
                            videoOverlay
                        }
                    }
                } else {
                    mediaPlaceholder
                }

                deleteButton {
                    removeExistingMedia(at: index)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// 새 미디어 셀 (그리드)
    private func newMediaGridCell(item: MediaItem, index: Int) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Image(uiImage: item.thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSmall))

                    // 동영상 아이콘 오버레이
                    if item.type == .video {
                        videoOverlay
                    }
                }

                deleteButton {
                    removeNewMedia(at: index)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// 추가 버튼 (그리드)
    private var addGridButton: some View {
        PhotosPicker(
            selection: $selectedPhotoItems,
            maxSelectionCount: remainingSlots,
            matching: .any(of: [.images, .videos])
        ) {
            RoundedRectangle(cornerRadius: Spacing.radiusSmall)
                .fill(Color.gray.opacity(0.1))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: 32))
                        .foregroundStyle(.textSub)
                }
        }
        .disabled(isDisabled)
    }

    // MARK: - Common Components

    /// 미디어 플레이스홀더
    private var mediaPlaceholder: some View {
        RoundedRectangle(cornerRadius: Spacing.radiusMedium)
            .fill(Color.gray.opacity(0.2))
            .frame(width: 120, height: 120)
            .overlay {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
            }
    }

    /// 동영상 오버레이 (재생 아이콘)
    private var videoOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)

            Image(systemName: "play.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white)
        }
    }

    /// 삭제 버튼
    private func deleteButton(action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                action()
            }
        }) {
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

    // MARK: - Actions

    private func removeExistingMedia(at index: Int) {
        existingMediaURLs.remove(at: index)
        if existingMediaURLs.isEmpty {
            shouldKeepExistingMedia = false
        }
    }

    private func removeNewMedia(at index: Int) {
        selectedMediaItems.remove(at: index)
        if index < selectedPhotoItems.count {
            selectedPhotoItems.remove(at: index)
        }
    }

    // MARK: - Helper

    /// URL이 동영상인지 확인
    private func isVideoURL(_ urlString: String) -> Bool {
        let videoExtensions = ["mp4", "mov", "m4v", "avi", "mkv", "wmv", "flv"]
        let lowercased = urlString.lowercased()
        return videoExtensions.contains { lowercased.hasSuffix(".\($0)") }
    }

    // MARK: - Modifiers

    func disabled(_ disabled: Bool) -> MediaPickerSection {
        var copy = self
        copy.isDisabled = disabled
        return copy
    }

    func loading(_ loading: Bool) -> MediaPickerSection {
        var copy = self
        copy.isLoading = loading
        return copy
    }
}

// MARK: - Layout Type

enum MediaPickerLayout {
    case horizontal // 가로 스크롤
    case grid       // 그리드 (3열)
}

// MARK: - Preview

#Preview("가로 스크롤") {
    @Previewable @State var mediaItems: [MediaItem] = []
    @Previewable @State var items: [PhotosPickerItem] = []
    @Previewable @State var existing: [String] = []
    @Previewable @State var keep: Bool = true

    MediaPickerSection(
        title: "모임 미디어",
        maxCount: 5,
        layout: .horizontal,
        selectedMediaItems: $mediaItems,
        selectedPhotoItems: $items,
        existingMediaURLs: $existing,
        shouldKeepExistingMedia: $keep
    )
    .padding()
}

#Preview("그리드") {
    @Previewable @State var mediaItems: [MediaItem] = []
    @Previewable @State var items: [PhotosPickerItem] = []
    @Previewable @State var existing: [String] = []
    @Previewable @State var keep: Bool = true

    MediaPickerSection(
        title: "사진 및 동영상",
        maxCount: 5,
        layout: .grid,
        selectedMediaItems: $mediaItems,
        selectedPhotoItems: $items,
        existingMediaURLs: $existing,
        shouldKeepExistingMedia: $keep
    )
    .padding()
}
