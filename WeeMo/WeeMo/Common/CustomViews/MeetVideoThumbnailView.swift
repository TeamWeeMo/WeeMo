//
//  MeetVideoThumbnailView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/27/25.
//

import SwiftUI

// MARK: - Video Thumbnail View

struct MeetVideoThumbnailView: View {
    let videoURL: String
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void

    @State private var thumbnailImage: UIImage?
    @State private var isLoading = true
    @State private var loadTask: Task<Void, Never>?

    private let networkService: NetworkServiceProtocol

    init(
        videoURL: String,
        width: CGFloat,
        height: CGFloat,
        networkService: NetworkServiceProtocol = NetworkService(),
        onTap: @escaping () -> Void
    ) {
        self.videoURL = videoURL
        self.width = width
        self.height = height
        self.networkService = networkService
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let thumbnail = thumbnailImage {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                        .clipped()
                } else if isLoading {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: width, height: height)
                        .overlay(
                            ProgressView("동영상 로딩 중...")
                                .foregroundStyle(.white)
                        )
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: width, height: height)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "video.slash")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.gray)
                                Text("썸네일을 로드할 수 없습니다")
                                    .font(.app(.content2))
                                    .foregroundStyle(.gray)
                            }
                        )
                }

                // 재생 아이콘 오버레이
                if thumbnailImage != nil {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 80, height: 80)

                        Image(systemName: "play.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .task(id: videoURL) {
            guard thumbnailImage == nil else { return }
            await loadThumbnail()
        }
        .onDisappear {
            loadTask?.cancel()
        }
    }

    private func loadThumbnail() async {
        loadTask = Task {
            if let thumbnail = await VideoHelper.extractThumbnail(from: videoURL) {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    thumbnailImage = thumbnail
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
        }

        await loadTask?.value
    }
}
