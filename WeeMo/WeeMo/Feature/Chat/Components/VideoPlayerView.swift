//
//  VideoPlayerView.swift
//  WeeMo
//
//  Created by 차지용 on 11/27/25.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoURL: String
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                ProgressView("동영상을 불러오는 중...")
                    .foregroundStyle(.white)
            }

            // 완료 버튼 오버레이
            VStack {
                HStack {
                    Button("완료") {
                        player?.pause()
                        dismiss()
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)

                    Spacer()
                }
                .padding(.top, 50) // Safe Area 고려

                Spacer()
            }
            .padding()
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func setupPlayer() {
        print("비디오 URL 원본: \(videoURL)")

        Task {
            await downloadAndSetupPlayer()
        }
    }

    private func downloadAndSetupPlayer() async {
        print("비디오 다운로드 시작 (NetworkService 사용)...")
        print("원본 비디오 경로: \(videoURL)")

        let router = FileRouter.downloadFile(filePath: videoURL)
        print("FileRouter 경로: \(router.path)")
        print("완전한 URL: \(NetworkConstants.baseURL)\(router.path)")

        do {
            let networkService = NetworkService()
            let videoData = try await networkService.downloadFile(router)
            print("비디오 다운로드 완료: \(videoData.count) bytes")
            setupPlayerWithData(videoData)

        } catch {
            print("비디오 다운로드 실패: \(error)")
        }
    }

    private func setupPlayerWithData(_ data: Data) {
        Task {
            do {
                // 임시 파일로 저장
                let tempDirectory = FileManager.default.temporaryDirectory
                let tempURL = tempDirectory.appendingPathComponent("temp_video_\(UUID().uuidString).mp4")

                try data.write(to: tempURL)
                print("임시 파일 저장: \(tempURL.path)")

                await MainActor.run {
                    // 로컬 파일로 플레이어 설정
                    let playerItem = AVPlayerItem(url: tempURL)
                    player = AVPlayer(playerItem: playerItem)

                    // 플레이어 상태 모니터링
                    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                        switch playerItem.status {
                        case .readyToPlay:
                            print("비디오 준비 완료 - 재생 가능")
                            timer.invalidate()
                        case .failed:
                            print("비디오 로드 실패: \(playerItem.error?.localizedDescription ?? "알 수 없는 오류")")
                            timer.invalidate()
                        case .unknown:
                            print("비디오 상태 로딩 중...")
                        @unknown default:
                            print("비디오 상태 기타")
                        }
                    }

                    print("로컬 비디오 플레이어 설정 완료")
                }
            } catch {
                print("임시 파일 저장 실패: \(error)")
            }
        }
    }

}
