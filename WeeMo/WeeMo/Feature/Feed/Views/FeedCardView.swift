//
//  FeedCardView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/8/25.
//

import SwiftUI
import Kingfisher
import AVKit
import AVFoundation

// MARK: - Pinterest Style Feed Card

struct FeedCardView: View {
    let item: Feed

    // 동적으로 계산된 이미지 비율 저장
    // 초기값 1.0 (정사각형)으로 시작, 이미지 로드 후 실제 비율로 업데이트
    @State private var imageAspectRatio: CGFloat = 1.0
    @State private var videoAspectRatio: CGFloat = 1.0
    @State private var player: AVPlayer?
    @State private var resourceLoaderDelegate: VideoResourceLoaderDelegate?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            if item.isVideo {
                videoView
            } else {
                imageView
            }
            // 내용 (2줄)
            // Custom Modifier 활용: 콘텐츠 텍스트 스타일
            Text(item.content)
                .feedContentText()
                .padding(.bottom, Spacing.xSmall)
        }
        // Custom Modifier 활용: 카드 전체 스타일 (배경, 모서리, 그림자)
        .feedCardStyle()
        .onAppear {
            if item.isVideo {
                setupPlayer(urlString: item.thumbnailURL)
            }
        }
        .onDisappear {
            cleanupPlayer()
        }
    }

    private var imageView: some View {
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
    }

    private var videoView: some View {
        Group {
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(videoAspectRatio, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSmall))
                    .onTapGesture {
                        togglePlayPause()
                    }
            } else {
                // 플레이어 로딩 중 플레이스홀더
                RoundedRectangle(cornerRadius: Spacing.radiusSmall)
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(videoAspectRatio, contentMode: .fit)
                    .overlay {
                        ProgressView()
                            .tint(.wmMain)
                    }
            }
        }
    }

    // MARK: - Helpers

    private func setupPlayer(urlString: String) {
        print("[FeedCard] 플레이어 설정 시작")

        // VideoHelper를 사용하여 스트리밍 Asset 생성
        guard let (asset, delegate) = VideoHelper.shared.createStreamingAsset(from: urlString) else {
            print("[FeedCard] 비디오 Asset 생성 실패")
            return
        }

        // Delegate 저장 (메모리에서 해제되지 않도록)
        self.resourceLoaderDelegate = delegate
        print("[FeedCard] Delegate 저장 완료")

        // Resource Loader Delegate 설정
        asset.resourceLoader.setDelegate(delegate, queue: DispatchQueue.main)
        print("[FeedCard] Delegate 설정 완료")

        // Player Item 및 Player 생성
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        player.isMuted = true
        self.player = player
        print("[FeedCard] Player 생성 완료")

        // 비디오 크기 정보를 비동기로 로드하여 aspect ratio 계산
        Task {
            await loadVideoAspectRatio(from: asset)
        }

        // 무한 루프 재생 설정
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }

        // 자동 재생 시작
        player.play()
        print("[FeedCard] 재생 시작!")
    }

    private func loadVideoAspectRatio(from asset: AVAsset) async {
        do {
            // 비디오 트랙 직접 로드
            let videoTracks = try await asset.loadTracks(withMediaType: .video)

            guard let videoTrack = videoTracks.first else {
                print("[FeedCard] 비디오 트랙을 찾을 수 없음")
                return
            }

            // 비디오 크기 로드
            let naturalSize = try await videoTrack.load(.naturalSize)
            let preferredTransform = try await videoTrack.load(.preferredTransform)

            // Transform 적용 (회전 고려)
            let size = naturalSize.applying(preferredTransform)
            let width = abs(size.width)
            let height = abs(size.height)

            // Aspect ratio 계산 (width / height)
            let aspectRatio = width / height

            print("[FeedCard] 비디오 크기: \(width) x \(height), aspect ratio: \(aspectRatio)")

            // 메인 스레드에서 업데이트
            await MainActor.run {
                self.videoAspectRatio = aspectRatio
            }
        } catch {
            print("[FeedCard] 비디오 aspect ratio 로드 실패: \(error)")
        }
    }

    private func cleanupPlayer() {
        player?.pause()
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        player = nil
        resourceLoaderDelegate = nil
    }

    private func togglePlayPause() {
        guard let player = player else { return }

        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
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
