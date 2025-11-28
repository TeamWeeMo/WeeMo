//
//  MeetMediaGallery.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/27/25.
//

import SwiftUI
import Kingfisher

// MARK: - Meet Media Gallery

struct MeetMediaGallery: View {
    let fileURLs: [String]
    @State private var currentIndex = 0
    @State private var selectedVideoURL: String?

    var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            let imageHeight: CGFloat = 300 + safeAreaTop

            ZStack(alignment: .bottomTrailing) {
                if !fileURLs.isEmpty {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(fileURLs.enumerated()), id: \.offset) { index, mediaURL in
                            mediaCell(mediaURL: mediaURL, geometry: geometry, imageHeight: imageHeight)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: imageHeight)

                    // 미디어 인디케이터
                    if fileURLs.count > 1 {
                        Text("\(currentIndex + 1) / \(fileURLs.count)")
                            .font(.app(.content2))
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.medium)
                            .padding(.vertical, Spacing.small)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(Spacing.radiusSmall)
                            .padding([.trailing, .bottom], Spacing.base)
                    }
                } else {
                    // 미디어가 없을 때
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: geometry.size.width, height: imageHeight)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        )
                }
            }
        }
        .frame(height: 300)
        .fullScreenCover(item: Binding(
            get: { selectedVideoURL.map { FullScreenVideoItem(url: $0) } },
            set: { selectedVideoURL = $0?.url }
        )) { item in
            FullScreenVideoPlayer(videoURL: item.url) {
                selectedVideoURL = nil
            }
        }
    }

    /// 미디어 셀 (이미지 또는 동영상)
    @ViewBuilder
    private func mediaCell(mediaURL: String, geometry: GeometryProxy, imageHeight: CGFloat) -> some View {
        let isVideo = isVideoFile(mediaURL)

        if isVideo {
            // 동영상 썸네일 + 재생 아이콘
            MeetVideoThumbnailView(
                videoURL: mediaURL,
                width: geometry.size.width,
                height: imageHeight
            ) {
                selectedVideoURL = mediaURL
            }
        } else {
            // 이미지
            KFImage(URL(string: FileRouter.fileURL(from: mediaURL)))
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
                .frame(width: geometry.size.width, height: imageHeight)
                .clipped()
        }
    }

    /// URL이 동영상 파일인지 확인
    private func isVideoFile(_ urlString: String) -> Bool {
        MeetVideoHelper.isVideoFile(urlString)
    }
}
