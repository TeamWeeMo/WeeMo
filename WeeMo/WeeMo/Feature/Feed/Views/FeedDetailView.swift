//
//  FeedDetailView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/9/25.
//

import SwiftUI
import Kingfisher
import AVKit
import AVFoundation

// MARK: - Instagram Style Feed Detail

/// 인스타그램 스타일의 피드 상세화면
/// - 구조: 헤더(프로필) + 이미지 + 콘텐츠(인터랙션/본문)
/// - 이미지 높이 제한: 화면 너비의 1.25배 (5:4 비율)
struct FeedDetailView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss

    // Store
    @State private var store: FeedDetailStore

    // Video players (인덱스별로 관리)
    @State private var videoPlayers: [Int: AVPlayer] = [:]
    @State private var videoResourceLoaderDelegates: [Int: VideoResourceLoaderDelegate] = [:]
    @State private var videoAspectRatios: [Int: CGFloat] = [:]

    // MARK: - Initializer

    init(
        item: Feed,
        networkService: NetworkServiceProtocol = NetworkService()
    ) {
        self.store = FeedDetailStore(
            feed: item,
            networkService: networkService
        )
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 상단: 프로필 정보
                headerView

                // 중간: 게시글 이미지 (여러 장 지원)
                imageCarouselView

                // 하단: 인터랙션 + 콘텐츠
                contentView
            }
        }
        .background(.wmBg)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // 공유 버튼
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(.textMain)
                    .buttonWrapper {
                        store.send(.sharePost)
                    }
            }
        }
        .sheet(isPresented: Binding(
            get: { store.state.showCommentSheet },
            set: { newValue in
                if !newValue {
                    store.send(.closeComments)
                }
            }
        )) {
            CommentBottomSheet(postId: store.state.feed.id)
        }
        .onAppear {
            store.send(.onAppear)
            setupVideoPlayers()
        }
        .onDisappear {
            cleanupVideoPlayers()
        }
    }

    // MARK: - Subviews

    /// 상단 프로필 정보 (헤더)
    private var headerView: some View {
        HStack(spacing: Spacing.medium) {
            // 프로필 이미지 (KingfisherHelper 사용)
            KFImage(URL(string: FileRouter.fileURL(from: store.state.feed.creator.profileImageURL ?? "")))
                .profileImageSetup()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .buttonWrapper {
                    store.send(.navigateToProfile)
                }

            // 닉네임
            Text(store.state.feed.creator.nickname)
                .font(.app(.subHeadline2))
                .foregroundStyle(.textMain)

            Spacer()

            // 더보기 메뉴 버튼
            Image(systemName: "ellipsis")
                .foregroundStyle(.textMain)
                .font(.app(.subHeadline1))
                .buttonWrapper {
                    store.send(.showMoreMenu)
                }
        }
        .feedDetailHeader()
    }

    /// 게시글 이미지/동영상 캐러셀 (여러 장 지원)
    private var imageCarouselView: some View {
        // TabView로 이미지/동영상 스와이프
        TabView(selection: Binding(
            get: { store.state.currentImageIndex },
            set: { store.send(.changeImagePage($0)) }
        )) {
            ForEach(Array(store.state.feed.imageURLs.enumerated()), id: \.offset) { index, imageURL in
                if isVideoURL(imageURL) {
                    // 동영상 표시
                    videoPlayerView(index: index)
                        .tag(index)
                } else {
                    // 이미지 표시
                    KFImage(URL(string: imageURL))
                        .feedDetailImageSetup()
                        .scaledToFit()
                        .feedDetailImage()
                        .tag(index)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: store.state.hasMultipleImages ? .always : .never))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .frame(height: UIScreen.main.bounds.width * 1.25) // 최대 높이 제한
        //TODO: - 수정방안 고민
        .padding(.vertical, -32) // TabView 기본 여백 제거
        .offset(y: -16) // TabView 기본 상단 여백 제거
    }

    /// 하단 콘텐츠 (인터랙션 + 본문)
    private var contentView: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // 인터랙션 버튼 (좋아요, 댓글, 공유, 북마크)
            interactionButtons

            // 좋아요 수
            if store.state.likeCount > 0 {
                Text("좋아요 \(store.state.likeCount)개")
                    .font(.app(.subHeadline2))
                    .foregroundStyle(.textMain)
            }

            // 닉네임 + 본문
            HStack(alignment: .top, spacing: Spacing.small) {
                Text(store.state.feed.creator.nickname)
                    .font(.app(.subHeadline2))
                    .foregroundStyle(.textMain)

                Text(store.state.feed.content)
                    .font(.app(.content2))
                    .foregroundStyle(.textMain)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 댓글 보기 버튼
            if store.state.feed.commentCount > 0 {
                Text("댓글 \(store.state.feed.commentCount)개 모두 보기")
                    .font(.app(.content2))
                    .foregroundStyle(.textSub)
                    .buttonWrapper {
                        store.send(.openComments)
                    }
            }

            // 작성일 (상대적 시간)
            Text(store.state.timeAgoString)
                .font(.app(.subContent2))
                .foregroundStyle(.textSub)
        }
        .feedDetailContent()
    }

    // MARK: - Subviews (Interaction)

    /// 인터랙션 버튼 바
    private var interactionButtons: some View {
        HStack(spacing: Spacing.base) {
            // 좋아요 버튼
            LikeButton(
                isLiked: Binding(
                    get: { store.state.isLiked },
                    set: { _ in store.send(.toggleLike) }
                ),
                likeCount: Binding(
                    get: { store.state.likeCount },
                    set: { _ in }
                )
            )

            // 댓글 버튼
            InteractionButton(systemImage: "bubble.right") {
                store.send(.openComments)
            }

            Spacer()
        }
    }

    /// 동영상 플레이어 뷰
    private func videoPlayerView(index: Int) -> some View {
        Group {
            if let player = videoPlayers[index] {
                VideoPlayer(player: player)
                    .aspectRatio(videoAspectRatios[index] ?? 1.0, contentMode: .fit)
                    .feedDetailImage()
                    .onTapGesture {
                        togglePlayPause(player: player)
                    }
            } else {
                // 플레이어 로딩 중 플레이스홀더
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(1.0, contentMode: .fit)
                    .feedDetailImage()
                    .overlay {
                        ProgressView()
                            .tint(.wmMain)
                    }
            }
        }
    }

    // MARK: - Helper Methods

    /// URL이 동영상인지 확인
    private func isVideoURL(_ urlString: String) -> Bool {
        let url = urlString.lowercased()
        return url.contains(".mp4") || url.contains(".mov") || url.contains(".m4v")
    }

    /// 모든 동영상 플레이어 설정
    private func setupVideoPlayers() {
        for (index, urlString) in store.state.feed.imageURLs.enumerated() {
            if isVideoURL(urlString) {
                setupPlayer(urlString: urlString, index: index)
            }
        }
    }

    /// 개별 플레이어 설정
    private func setupPlayer(urlString: String, index: Int) {
        print("[FeedDetail] 플레이어 설정 시작 - Index: \(index)")

        // VideoHelper를 사용하여 스트리밍 Asset 생성
        guard let (asset, delegate) = VideoHelper.shared.createStreamingAsset(from: urlString) else {
            print("[FeedDetail] 비디오 Asset 생성 실패 - Index: \(index)")
            return
        }

        // Delegate 저장 (메모리에서 해제되지 않도록)
        videoResourceLoaderDelegates[index] = delegate
        print("[FeedDetail] Delegate 저장 완료 - Index: \(index)")

        // Resource Loader Delegate 설정
        asset.resourceLoader.setDelegate(delegate, queue: DispatchQueue.main)
        print("[FeedDetail] Delegate 설정 완료 - Index: \(index)")

        // Player Item 및 Player 생성
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        player.isMuted = true
        videoPlayers[index] = player
        print("[FeedDetail] Player 생성 완료 - Index: \(index)")

        // 비디오 크기 정보를 비동기로 로드하여 aspect ratio 계산
        Task {
            await loadVideoAspectRatio(from: asset, index: index)
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
        print("[FeedDetail] 재생 시작! - Index: \(index)")
    }

    /// 동영상 Aspect Ratio 로드
    private func loadVideoAspectRatio(from asset: AVAsset, index: Int) async {
        do {
            let videoTracks = try await asset.loadTracks(withMediaType: .video)

            guard let videoTrack = videoTracks.first else {
                print("[FeedDetail] 비디오 트랙을 찾을 수 없음 - Index: \(index)")
                return
            }

            let naturalSize = try await videoTrack.load(.naturalSize)
            let preferredTransform = try await videoTrack.load(.preferredTransform)

            let size = naturalSize.applying(preferredTransform)
            let width = abs(size.width)
            let height = abs(size.height)

            let aspectRatio = width / height

            print("[FeedDetail] 비디오 크기: \(width) x \(height), aspect ratio: \(aspectRatio) - Index: \(index)")

            await MainActor.run {
                videoAspectRatios[index] = aspectRatio
            }
        } catch {
            print("[FeedDetail] 비디오 aspect ratio 로드 실패: \(error) - Index: \(index)")
        }
    }

    /// 플레이어 정리
    private func cleanupVideoPlayers() {
        for (_, player) in videoPlayers {
            player.pause()
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        }
        videoPlayers.removeAll()
        videoResourceLoaderDelegates.removeAll()
    }

    /// 재생/일시정지 토글
    private func togglePlayPause(player: AVPlayer) {
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
    }
}
