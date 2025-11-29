//
//  SimpleMediaPickerSection.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/27/25.
//

import SwiftUI

// MARK: - Simple Media Picker Section

/// 간단한 미디어 피커 섹션 (커스텀 피커용)
struct SimpleMediaPickerSection: View {
    let title: String
    let maxCount: Int
    let selectedMediaItems: [MediaItem]
    let onAddTapped: () -> Void
    let onRemoveItem: (Int) -> Void

    init(
        title: String = "모임 미디어 (최대 5개)",
        maxCount: Int = 5,
        selectedMediaItems: [MediaItem],
        onAddTapped: @escaping () -> Void,
        onRemoveItem: @escaping (Int) -> Void
    ) {
        self.title = title
        self.maxCount = maxCount
        self.selectedMediaItems = selectedMediaItems
        self.onAddTapped = onAddTapped
        self.onRemoveItem = onRemoveItem
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(title)
                .font(.app(.subHeadline2))
                .foregroundStyle(.textMain)

            if !selectedMediaItems.isEmpty {
                selectedMediaGrid
            } else {
                emptyStateButton
            }
        }
    }

    // MARK: - Selected Media Grid

    private var selectedMediaGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) {
                ForEach(Array(selectedMediaItems.enumerated()), id: \.offset) { index, item in
                    MediaThumbnailItem(
                        mediaItem: item,
                        onRemove: {
                            onRemoveItem(index)
                        }
                    )
                }

                // 추가 버튼
                if selectedMediaItems.count < maxCount {
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
