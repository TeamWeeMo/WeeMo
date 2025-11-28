//
//  VideoThumbnailView.swift
//  WeeMo
//
//  Created by 차지용 on 11/27/25.
//

import SwiftUI
import AVKit

struct VideoThumbnailView: View {
    let videoURL: String
    @State private var thumbnailImage: UIImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let thumbnailImage = thumbnailImage {
                Image(uiImage: thumbnailImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                // 로딩 중
                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        ProgressView()
                            .tint(.gray)
                    }
            } else {
                // 썸네일 추출 실패시 기본 비디오 아이콘
                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                    .fill(Color.gray.opacity(0.8))
                    .overlay {
                        Image(systemName: "video.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.9))
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
        .onAppear {
            generateThumbnail()
        }
    }

    private func generateThumbnail() {
        Task {
            await loadVideoThumbnail()
        }
    }

    @MainActor
    private func loadVideoThumbnail() async {
        do {
            // NetworkService로 비디오 다운로드
            let networkService = NetworkService()
            let videoData = try await networkService.downloadFile(FileRouter.downloadFile(filePath: videoURL))

            print("썸네일용 비디오 다운로드 완료: \(videoData.count) bytes")

            // 임시 파일로 저장
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempURL = tempDirectory.appendingPathComponent("temp_thumbnail_\(UUID().uuidString).mp4")

            try videoData.write(to: tempURL)

            // AVAsset으로 첫 프레임 추출
            let asset = AVAsset(url: tempURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true

            let time = CMTime(seconds: 0, preferredTimescale: 1) // 첫 프레임

            let cgImage = try await imageGenerator.image(at: time).image
            let uiImage = UIImage(cgImage: cgImage)

            print("비디오 썸네일 생성 성공")

            // 메인 스레드에서 UI 업데이트
            thumbnailImage = uiImage
            isLoading = false

            // 임시 파일 삭제
            try? FileManager.default.removeItem(at: tempURL)

        } catch {
            print("비디오 썸네일 생성 실패: \(error)")
            isLoading = false
        }
    }
}