//
//  FullScreenVideoPlayer.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/27/25.
//

import SwiftUI
import AVKit

// MARK: - Full Screen Video Item

struct FullScreenVideoItem: Identifiable {
    let id = UUID()
    let url: String
}

// MARK: - Full Screen Video Player

struct FullScreenVideoPlayer: View {
    let videoURL: String
    let onDismiss: () -> Void

    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView("동영상 로딩 중...")
                    .foregroundStyle(.white)
            }

            // 닫기 버튼
            VStack {
                HStack {
                    Spacer()

                    Button {
                        player?.pause()
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                            )
                    }
                    .padding()
                }

                Spacer()
            }
        }
        .onAppear {
            loadVideo()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func loadVideo() {
        let fullURL = FileRouter.fileURL(from: videoURL)
        guard let url = URL(string: fullURL) else { return }

        let asset = MeetVideoHelper.makeAuthenticatedAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let newPlayer = AVPlayer(playerItem: playerItem)
        self.player = newPlayer
        newPlayer.play()
    }
}
