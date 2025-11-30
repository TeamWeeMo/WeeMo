//
//  SpaceMediaPickerSection.swift
//  WeeMo
//
//  Created by Reimos on 11/29/25.
//

import SwiftUI
import Kingfisher

// MARK: - Space Media Picker Section

/// 공간 전용 미디어 피커 섹션 (기존 URL + 새 MediaItem 통합 관리)
struct SpaceMediaPickerSection: View {
    let title: String
    let maxCount: Int
    let existingFileURLs: [String]  // 기존 서버 파일 URL
    let selectedMediaItems: [MediaItem]  // 새로 추가한 미디어
    let onAddTapped: () -> Void
    let onRemoveExistingFile: (Int) -> Void  // 기존 파일 삭제
    let onRemoveMediaItem: (Int) -> Void  // 새 미디어 삭제

    private var totalCount: Int {
        existingFileURLs.count + selectedMediaItems.count
    }

    private var canAddMore: Bool {
        totalCount < maxCount
    }

    init(
        title: String = "공간 미디어 (최대 5개)",
        maxCount: Int = 5,
        existingFileURLs: [String],
        selectedMediaItems: [MediaItem],
        onAddTapped: @escaping () -> Void,
        onRemoveExistingFile: @escaping (Int) -> Void,
        onRemoveMediaItem: @escaping (Int) -> Void
    ) {
        self.title = title
        self.maxCount = maxCount
        self.existingFileURLs = existingFileURLs
        self.selectedMediaItems = selectedMediaItems
        self.onAddTapped = onAddTapped
        self.onRemoveExistingFile = onRemoveExistingFile
        self.onRemoveMediaItem = onRemoveMediaItem
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text(title)
                    .font(.app(.subHeadline2))
                    .foregroundStyle(.textMain)

                Spacer()

                Text("\(totalCount)/\(maxCount)")
                    .font(.app(.content2))
                    .foregroundStyle(.textSub)
            }

            if totalCount > 0 {
                mediaGrid
            } else {
                emptyStateButton
            }
        }
        .onAppear {
            print("[SpaceMediaPickerSection] 기존 파일 개수: \(existingFileURLs.count)")
            print("[SpaceMediaPickerSection] 기존 파일 URL: \(existingFileURLs)")
            print("[SpaceMediaPickerSection] 새 미디어 개수: \(selectedMediaItems.count)")
        }
    }

    // MARK: - Media Grid

    private var mediaGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) {
                // 1. 기존 서버 파일들
                ForEach(Array(existingFileURLs.enumerated()), id: \.offset) { index, urlString in
                    ExistingFileThumbnail(
                        urlString: urlString,
                        onRemove: {
                            onRemoveExistingFile(index)
                        }
                    )
                }

                // 2. 새로 추가한 미디어들
                ForEach(Array(selectedMediaItems.enumerated()), id: \.offset) { index, item in
                    MediaThumbnailItem(
                        mediaItem: item,
                        onRemove: {
                            onRemoveMediaItem(index)
                        }
                    )
                }

                // 3. 추가 버튼
                if canAddMore {
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

// MARK: - Existing File Thumbnail

/// 기존 서버 파일 썸네일 (Kingfisher로 URL 이미지 표시)
struct ExistingFileThumbnail: View {
    let urlString: String
    let onRemove: () -> Void

    // 상대 경로를 API 경로(/v1 포함)로 변환
    private var apiURL: String {
        // URL이 이미 http로 시작하면, 상대 경로만 추출
        if urlString.hasPrefix("http") {
            // baseURL 제거
            let relativePath = urlString.replacingOccurrences(of: NetworkConstants.baseURL, with: "")
            // /v1 경로로 변환
            return FileRouter.fileURL(from: relativePath)
        } else {
            // 이미 상대 경로면 그대로 사용
            return FileRouter.fileURL(from: urlString)
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // URL 이미지 로드 (인증 헤더 포함, /v1 경로 사용)
            KFImage(URL(string: apiURL))
                .withAuthHeaders()
                .placeholder {
                    ZStack {
                        Color.gray.opacity(0.2)
                        ProgressView()
                    }
                }
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))

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
        .onAppear {
            print("[ExistingFileThumbnail] URL 로드 시작: \(urlString)")
        }
    }
}

#Preview {
    VStack {
        SpaceMediaPickerSection(
            existingFileURLs: [],
            selectedMediaItems: [],
            onAddTapped: {},
            onRemoveExistingFile: { _ in },
            onRemoveMediaItem: { _ in }
        )
        .padding()
    }
}
