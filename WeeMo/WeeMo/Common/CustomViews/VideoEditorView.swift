//
//  VideoEditorView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/27/25.
//

import SwiftUI
import AVKit
import AVFoundation

// MARK: - Video Editor View

/// 동영상 편집 화면 (iPhone 앨범 스타일 UI)
struct VideoEditorView: View {
    // MARK: - Properties

    let videoURL: URL
    let onComplete: (MediaItem?) -> Void
    let onCancel: () -> Void

    // MARK: - State

    @State private var player: AVPlayer
    @State private var asset: AVAsset
    @State private var duration: CMTime = .zero

    // 트림 범위
    @State private var trimStartTime: Double = 0
    @State private var trimEndTime: Double = 0
    @State private var currentTime: Double = 0

    // 화질 선택
    @State private var selectedQuality: VideoQuality = .high

    // 자막
    @State private var subtitles: [Subtitle] = []
    @State private var showAddSubtitleSheet: Bool = false

    // 압축 상태
    @State private var isProcessing: Bool = false
    @State private var processingProgress: Double = 0
    @State private var estimatedFileSize: String = "계산 중..."
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    // 미리보기
    @State private var showPreview: Bool = false
    @State private var previewURL: URL?

    // 타임 옵저버
    @State private var timeObserver: Any?

    // MARK: - Initializer

    init(videoURL: URL, onComplete: @escaping (MediaItem?) -> Void, onCancel: @escaping () -> Void) {
        self.videoURL = videoURL
        self.onComplete = onComplete
        self.onCancel = onCancel

        let asset = AVURLAsset(url: videoURL)
        self._asset = State(initialValue: asset)
        self._player = State(initialValue: AVPlayer(playerItem: AVPlayerItem(asset: asset)))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: Spacing.base) {
                        // 1. 비디오 플레이어 (자막 오버레이 포함)
                        videoPlayerSection

                        // 2. 재생 컨트롤
                        playbackControlSection

                        // 3. iPhone 스타일 타임라인 트림
                        timelineTrimSection

                        // 4. 화질 선택
                        qualitySelectionSection

                        // 5. 자막 추가
                        subtitleSection

                        // 6. 예상 파일 크기
                        fileSizeSection
                    }
                    .padding(.horizontal, Spacing.base)
                    .padding(.vertical, Spacing.medium)
                }

                // 7. 처리 중 오버레이
                if isProcessing {
                    processingOverlay
                }
            }
            .background(Color.wmBg)
            .navigationTitle("동영상 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        cleanup()
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        processVideo()
                    }
                    .disabled(isProcessing || !isValidFileSize)
                    .foregroundStyle(isValidFileSize ? .wmMain : .textSub)
                }
            }
            .onAppear {
                loadVideoMetadata()
                setupTimeObserver()
            }
            .onDisappear {
                cleanup()
            }
            .sheet(isPresented: $showAddSubtitleSheet) {
                AddSubtitleSheet(
                    duration: duration,
                    currentTime: currentTime
                ) { subtitle in
                    subtitles.append(subtitle)
                    subtitles.sort { $0.startTime < $1.startTime }
                }
            }
            .sheet(isPresented: $showPreview) {
                if let previewURL = previewURL {
                    VideoPreviewSheet(videoURL: previewURL) {
                        // 미리보기에서 "사용" 버튼
                        showPreview = false
                        if let mediaItem = try? createMediaItemFromURL(previewURL) {
                            cleanup()
                            onComplete(mediaItem)
                        }
                    } onCancel: {
                        // 미리보기에서 "다시 편집" 버튼
                        showPreview = false
                        try? FileManager.default.removeItem(at: previewURL)
                        self.previewURL = nil
                    }
                }
            }
            .alert("오류", isPresented: $showError) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Sections

    /// 1. 비디오 플레이어 (자막 오버레이)
    private var videoPlayerSection: some View {
        ZStack {
            VideoPlayer(player: player)
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))

            // 자막 오버레이 (실시간 미리보기)
            VStack {
                Spacer()

                if let currentSubtitle = getCurrentSubtitle() {
                    Text(currentSubtitle.text)
                        .font(.app(.content1))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.medium)
                        .padding(.vertical, Spacing.small)
                        .background(
                            RoundedRectangle(cornerRadius: Spacing.radiusSmall)
                                .fill(Color.black.opacity(0.7))
                        )
                        .padding(.bottom, 40)
                        .transition(.opacity)
                }
            }
            .frame(height: 280)
            .allowsHitTesting(false)
        }
    }

    /// 2. 재생 컨트롤
    private var playbackControlSection: some View {
        VStack(spacing: Spacing.small) {
            // 현재 시간 표시
            HStack {
                Text(formatTime(currentTime))
                    .font(.app(.content2))
                    .foregroundStyle(.textSub)
                    .monospacedDigit()

                Spacer()

                Text(formatTime(duration.seconds))
                    .font(.app(.content2))
                    .foregroundStyle(.textSub)
                    .monospacedDigit()
            }

            // 재생/일시정지 버튼
            HStack(spacing: Spacing.base) {
                Button {
                    seekPlayer(to: max(trimStartTime, currentTime - 5))
                } label: {
                    Image(systemName: "gobackward.5")
                        .font(.title2)
                        .foregroundStyle(.textMain)
                }

                Button {
                    if player.timeControlStatus == .playing {
                        player.pause()
                    } else {
                        player.play()
                    }
                } label: {
                    Image(systemName: player.timeControlStatus == .playing ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.wmMain)
                }

                Button {
                    seekPlayer(to: min(trimEndTime, currentTime + 5))
                } label: {
                    Image(systemName: "goforward.5")
                        .font(.title2)
                        .foregroundStyle(.textMain)
                }
            }
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                .fill(Color.gray.opacity(0.05))
        )
    }

    /// 3. iPhone 스타일 타임라인 트림
    private var timelineTrimSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text("영상 길이 조절")
                    .font(.app(.subHeadline1))
                    .foregroundStyle(.textMain)

                Spacer()

                Text("\(formatDuration(trimEndTime - trimStartTime))")
                    .font(.app(.headline2))
                    .foregroundStyle(.wmMain)
                    .monospacedDigit()
            }

            // 타임라인 UI (iPhone 앨범 스타일)
            TimelineView(
                duration: duration.seconds,
                trimStart: $trimStartTime,
                trimEnd: $trimEndTime,
                currentTime: currentTime,
                onSeek: { time in
                    seekPlayer(to: time)
                }
            )
            .frame(height: 60)
            .onChange(of: trimStartTime) { _, _ in
                estimateFileSize()
            }
            .onChange(of: trimEndTime) { _, _ in
                estimateFileSize()
            }

            // 시작/종료 시간 표시
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("시작")
                        .font(.app(.subContent2))
                        .foregroundStyle(.textSub)
                    Text(formatTime(trimStartTime))
                        .font(.app(.content2))
                        .foregroundStyle(.textMain)
                        .monospacedDigit()
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("종료")
                        .font(.app(.subContent2))
                        .foregroundStyle(.textSub)
                    Text(formatTime(trimEndTime))
                        .font(.app(.content2))
                        .foregroundStyle(.textMain)
                        .monospacedDigit()
                }
            }
        }
    }

    /// 4. 화질 선택
    private var qualitySelectionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("화질 선택")
                .font(.app(.subHeadline1))
                .foregroundStyle(.textMain)

            Picker("화질", selection: $selectedQuality) {
                ForEach(VideoQuality.allCases, id: \.self) { quality in
                    Text(quality.displayName).tag(quality)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedQuality) { _, _ in
                estimateFileSize()
            }

            Text(selectedQuality.description)
                .font(.app(.subContent2))
                .foregroundStyle(.textSub)
        }
    }

    /// 5. 자막 섹션
    private var subtitleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text("자막 추가")
                    .font(.app(.subHeadline1))
                    .foregroundStyle(.textMain)

                Spacer()

                Button {
                    player.pause()
                    showAddSubtitleSheet = true
                } label: {
                    HStack(spacing: Spacing.xSmall) {
                        Image(systemName: "plus.circle.fill")
                        Text("현재 위치에 추가")
                    }
                    .font(.app(.content2))
                    .foregroundStyle(.wmMain)
                }
            }

            if subtitles.isEmpty {
                Text("자막이 없습니다. 원하는 위치에서 재생을 멈추고 '추가' 버튼을 눌러주세요.")
                    .font(.app(.content2))
                    .foregroundStyle(.textSub)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.base)
            } else {
                ForEach(Array(subtitles.enumerated()), id: \.offset) { index, subtitle in
                    SubtitleRow(
                        subtitle: subtitle,
                        onDelete: {
                            subtitles.remove(at: index)
                        },
                        onSeek: {
                            seekPlayer(to: subtitle.startTime)
                        }
                    )
                }
            }
        }
    }

    /// 6. 파일 크기 섹션
    private var fileSizeSection: some View {
        VStack(spacing: Spacing.small) {
            HStack {
                Text("예상 파일 크기")
                    .font(.app(.subHeadline1))
                    .foregroundStyle(.textMain)

                Spacer()

                Text(estimatedFileSize)
                    .font(.app(.headline2))
                    .foregroundStyle(isValidFileSize ? .wmMain : .red)
            }

            if !isValidFileSize {
                Text("파일 크기가 10MB를 초과합니다. 영상 길이를 줄이거나 화질을 낮춰주세요.")
                    .font(.app(.subContent2))
                    .foregroundStyle(.red)
            }
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                .fill(Color.gray.opacity(0.05))
        )
    }

    /// 7. 처리 중 오버레이
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: Spacing.base) {
                ProgressView(value: processingProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .wmMain))
                    .frame(width: 200)

                Text("동영상 처리 중... \(Int(processingProgress * 100))%")
                    .font(.app(.content1))
                    .foregroundStyle(.white)
            }
            .padding(Spacing.base)
            .background(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }

    // MARK: - Computed Properties

    private var isValidFileSize: Bool {
        guard !estimatedFileSize.contains("계산") else { return true }
        let sizeString = estimatedFileSize.replacingOccurrences(of: "MB", with: "").trimmingCharacters(in: .whitespaces)
        guard let size = Double(sizeString) else { return true }
        return size <= 10
    }

    // MARK: - Methods

    /// 비디오 메타데이터 로드
    private func loadVideoMetadata() {
        Task {
            do {
                let loadedDuration = try await asset.load(.duration)
                await MainActor.run {
                    self.duration = loadedDuration
                    self.trimEndTime = loadedDuration.seconds
                    estimateFileSize()
                }
            } catch {
                print("[VideoEditor] 메타데이터 로드 실패: \(error)")
            }
        }
    }

    /// 타임 옵저버 설정 (현재 재생 시간 추적)
    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak player] time in
            guard let player = player else { return }
            currentTime = time.seconds

            // 트림 범위 밖으로 나가면 자동으로 시작 지점으로
            if currentTime >= trimEndTime {
                seekPlayer(to: trimStartTime)
            }
        }
    }

    /// 플레이어 시간 이동
    private func seekPlayer(to time: Double) {
        let clampedTime = max(trimStartTime, min(trimEndTime, time))
        let cmTime = CMTime(seconds: clampedTime, preferredTimescale: 600)
        player.seek(to: cmTime)
        currentTime = clampedTime
    }

    /// 현재 시간에 해당하는 자막 찾기
    private func getCurrentSubtitle() -> Subtitle? {
        return subtitles.first { subtitle in
            currentTime >= subtitle.startTime && currentTime <= subtitle.endTime
        }
    }

    /// 파일 크기 추정
    private func estimateFileSize() {
        let duration = trimEndTime - trimStartTime
        let bitrate = selectedQuality.bitrate
        let estimatedBytes = (bitrate * Int(duration)) / 8
        let estimatedMB = Double(estimatedBytes) / 1_000_000
        estimatedFileSize = String(format: "%.1f MB", estimatedMB)
    }

    /// 동영상 처리 (트림 + 자막 + 압축)
    private func processVideo() {
        Task {
            await MainActor.run {
                isProcessing = true
                processingProgress = 0
            }

            do {
                // 1. 트림 + 자막 적용
                let trimmedURL = try await exportVideoWithEdits()

                await MainActor.run {
                    processingProgress = 0.7
                }

                // 2. 압축 (필요 시)
                guard let compressedData = await VideoCompressor.compress(trimmedURL, maxSizeInMB: 10) else {
                    throw VideoEditorError.exportFailed("압축 실패")
                }

                await MainActor.run {
                    processingProgress = 0.9
                }

                // 3. 임시 파일로 저장 (미리보기용)
                let previewURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("preview_\(UUID().uuidString).mp4")
                try compressedData.write(to: previewURL)

                // 원본 트림 파일 삭제
                try? FileManager.default.removeItem(at: trimmedURL)

                await MainActor.run {
                    processingProgress = 1.0
                    isProcessing = false
                    self.previewURL = previewURL
                    showPreview = true
                }

            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "동영상 처리 실패: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    /// 트림 + 자막 적용 후 Export
    private func exportVideoWithEdits() async throws -> URL {
        let composition = AVMutableComposition()

        // 비디오 & 오디오 트랙 추가
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first,
              let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
              ) else {
            throw VideoEditorError.exportFailed("비디오 트랙 로드 실패")
        }

        let startTime = CMTime(seconds: trimStartTime, preferredTimescale: 600)
        let endTime = CMTime(seconds: trimEndTime, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startTime, end: endTime)

        try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)

        // 오디오 트랙 추가
        if let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first,
           let compositionAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
           ) {
            try? compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
        }

        // VideoComposition (자막 포함)
        let videoComposition: AVMutableVideoComposition?
        if !subtitles.isEmpty {
            videoComposition = try await createCompositionWithSubtitles()
        } else {
            videoComposition = nil
        }

        // Export Session
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("trimmed_\(UUID().uuidString).mp4")

        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: selectedQuality.preset
        ) else {
            throw VideoEditorError.exportFailed("Export Session 생성 실패")
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        if let videoComposition = videoComposition {
            exportSession.videoComposition = videoComposition
        }

        // Export 실행 및 진행률 추적
        await exportSession.export()

        // 진행률 모니터링
        while exportSession.status == .exporting {
            await MainActor.run {
                processingProgress = Double(exportSession.progress) * 0.7
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        guard exportSession.status == .completed else {
            throw VideoEditorError.exportFailed(exportSession.error?.localizedDescription ?? "Export 실패")
        }

        return outputURL
    }

    /// 자막이 포함된 Composition 생성
    private func createCompositionWithSubtitles() async throws -> AVMutableVideoComposition {
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            throw VideoEditorError.exportFailed("비디오 트랙을 찾을 수 없습니다")
        }

        let videoSize = try await videoTrack.load(.naturalSize)
        let videoComposition = AVMutableVideoComposition(asset: asset) { request in
            let sourceImage = request.sourceImage
            request.finish(with: sourceImage, context: nil)
        }

        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

        // 자막 레이어
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: videoSize)
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        parentLayer.addSublayer(videoLayer)

        // 트림 오프셋 적용
        for subtitle in subtitles {
            let adjustedStartTime = max(0, subtitle.startTime - trimStartTime)
            let adjustedEndTime = subtitle.endTime - trimStartTime

            guard adjustedEndTime > 0 else { continue }

            let textLayer = CATextLayer()
            textLayer.string = subtitle.text
            textLayer.font = UIFont.systemFont(ofSize: 32, weight: .bold)
            textLayer.fontSize = 32
            textLayer.foregroundColor = UIColor.white.cgColor
            textLayer.backgroundColor = UIColor.black.withAlphaComponent(0.7).cgColor
            textLayer.alignmentMode = .center
            textLayer.isWrapped = true

            let textHeight: CGFloat = 60
            let textWidth = videoSize.width * 0.8
            textLayer.frame = CGRect(
                x: (videoSize.width - textWidth) / 2,
                y: videoSize.height * 0.1,
                width: textWidth,
                height: textHeight
            )

            let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
            fadeInAnimation.fromValue = 0.0
            fadeInAnimation.toValue = 1.0
            fadeInAnimation.duration = 0.3
            fadeInAnimation.beginTime = adjustedStartTime
            fadeInAnimation.fillMode = .forwards
            fadeInAnimation.isRemovedOnCompletion = false

            let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
            fadeOutAnimation.fromValue = 1.0
            fadeOutAnimation.toValue = 0.0
            fadeOutAnimation.duration = 0.3
            fadeOutAnimation.beginTime = adjustedEndTime
            fadeOutAnimation.fillMode = .forwards
            fadeOutAnimation.isRemovedOnCompletion = false

            let animationGroup = CAAnimationGroup()
            animationGroup.animations = [fadeInAnimation, fadeOutAnimation]
            animationGroup.duration = adjustedEndTime + 0.3
            animationGroup.beginTime = AVCoreAnimationBeginTimeAtZero
            animationGroup.fillMode = .forwards
            animationGroup.isRemovedOnCompletion = false

            textLayer.add(animationGroup, forKey: "subtitleAnimation")
            textLayer.opacity = 0

            parentLayer.addSublayer(textLayer)
        }

        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer
        )

        return videoComposition
    }

    /// 미리보기 URL에서 MediaItem 생성
    private func createMediaItemFromURL(_ url: URL) throws -> MediaItem? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        let thumbnail = extractThumbnailSync(from: url)

        return MediaItem(
            id: UUID(),
            type: .video,
            thumbnail: thumbnail ?? UIImage(),
            data: data,
            originalFileName: url.lastPathComponent
        )
    }

    /// 썸네일 동기 추출
    private func extractThumbnailSync(from url: URL) -> UIImage? {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        do {
            let cgImage = try imageGenerator.copyCGImage(at: CMTime(seconds: 0.5, preferredTimescale: 600), actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
    }

    /// 리소스 정리
    private func cleanup() {
        player.pause()
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    /// 시간 포맷 (00:00)
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// 기간 포맷 (0분 00초)
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)분 \(seconds)초"
        } else {
            return "\(seconds)초"
        }
    }
}

// MARK: - Timeline View (iPhone 앨범 스타일)

struct TimelineView: View {
    let duration: Double
    @Binding var trimStart: Double
    @Binding var trimEnd: Double
    let currentTime: Double
    let onSeek: (Double) -> Void

    @State private var isDraggingStart = false
    @State private var isDraggingEnd = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 배경 (전체 타임라인)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))

                // 선택된 범위
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.wmMain.opacity(0.3))
                    .frame(width: selectedWidth(in: geometry.size.width))
                    .offset(x: startOffset(in: geometry.size.width))

                // 현재 재생 위치 인디케이터
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 2)
                    .offset(x: currentTimeOffset(in: geometry.size.width))

                // 시작 핸들
                TrimHandle(isStart: true, isDragging: isDraggingStart)
                    .offset(x: startOffset(in: geometry.size.width))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDraggingStart = true
                                let newStart = max(0, min(trimEnd - 1, value.location.x / geometry.size.width * duration))
                                trimStart = newStart
                            }
                            .onEnded { _ in
                                isDraggingStart = false
                            }
                    )

                // 종료 핸들
                TrimHandle(isStart: false, isDragging: isDraggingEnd)
                    .offset(x: endOffset(in: geometry.size.width))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDraggingEnd = true
                                let newEnd = max(trimStart + 1, min(duration, value.location.x / geometry.size.width * duration))
                                trimEnd = newEnd
                            }
                            .onEnded { _ in
                                isDraggingEnd = false
                            }
                    )
            }
            .frame(height: 60)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let time = max(trimStart, min(trimEnd, value.location.x / geometry.size.width * duration))
                        onSeek(time)
                    }
            )
        }
    }

    private func startOffset(in width: CGFloat) -> CGFloat {
        return (trimStart / duration) * width
    }

    private func endOffset(in width: CGFloat) -> CGFloat {
        return (trimEnd / duration) * width
    }

    private func selectedWidth(in width: CGFloat) -> CGFloat {
        return ((trimEnd - trimStart) / duration) * width
    }

    private func currentTimeOffset(in width: CGFloat) -> CGFloat {
        return (currentTime / duration) * width
    }
}

// MARK: - Trim Handle

struct TrimHandle: View {
    let isStart: Bool
    let isDragging: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(isDragging ? Color.wmMain : Color.white)
            .frame(width: 8, height: 60)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.wmMain, lineWidth: 2)
            )
            .shadow(radius: 2)
    }
}

// MARK: - Add Subtitle Sheet

struct AddSubtitleSheet: View {
    let duration: CMTime
    let currentTime: Double
    let onAdd: (Subtitle) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var text: String = ""
    @State private var startTime: Double
    @State private var endTime: Double

    init(duration: CMTime, currentTime: Double, onAdd: @escaping (Subtitle) -> Void) {
        self.duration = duration
        self.currentTime = currentTime
        self.onAdd = onAdd

        // 현재 재생 위치를 기준으로 초기화
        _startTime = State(initialValue: currentTime)
        _endTime = State(initialValue: min(duration.seconds, currentTime + 3))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("자막 내용") {
                    TextField("자막을 입력하세요", text: $text, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("표시 시간") {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("시작: \(formatTime(startTime))")
                            .font(.app(.content2))
                        Slider(value: $startTime, in: 0...max(0.1, endTime - 0.1))
                            .tint(.wmMain)
                    }

                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("종료: \(formatTime(endTime))")
                            .font(.app(.content2))
                        Slider(value: $endTime, in: (startTime + 0.1)...duration.seconds)
                            .tint(.wmMain)
                    }

                    Text("표시 시간: \(formatDuration(endTime - startTime))")
                        .font(.app(.subContent2))
                        .foregroundStyle(.textSub)
                }
            }
            .navigationTitle("자막 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        let subtitle = Subtitle(
                            text: text,
                            startTime: startTime,
                            endTime: endTime
                        )
                        onAdd(subtitle)
                        dismiss()
                    }
                    .disabled(text.isEmpty)
                }
            }
        }
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func formatDuration(_ duration: Double) -> String {
        let seconds = Int(duration)
        return "\(seconds)초"
    }
}

// MARK: - Subtitle Row

struct SubtitleRow: View {
    let subtitle: Subtitle
    let onDelete: () -> Void
    let onSeek: () -> Void

    var body: some View {
        HStack(spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(subtitle.text)
                    .font(.app(.content2))
                    .foregroundStyle(.textMain)
                    .lineLimit(2)

                Text("\(formatTime(subtitle.startTime)) - \(formatTime(subtitle.endTime))")
                    .font(.app(.subContent2))
                    .foregroundStyle(.textSub)
                    .monospacedDigit()
            }

            Spacer()

            Button {
                onSeek()
            } label: {
                Image(systemName: "play.circle")
                    .font(.title3)
                    .foregroundStyle(.wmMain)
            }

            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundStyle(.red)
            }
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Spacing.radiusSmall)
                .fill(Color.gray.opacity(0.05))
        )
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Video Preview Sheet

struct VideoPreviewSheet: View {
    let videoURL: URL
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var player: AVPlayer

    init(videoURL: URL, onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.videoURL = videoURL
        self.onConfirm = onConfirm
        self.onCancel = onCancel

        _player = State(initialValue: AVPlayer(url: videoURL))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VideoPlayer(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }

                VStack(spacing: Spacing.medium) {
                    Button {
                        onConfirm()
                    } label: {
                        Text("이 동영상 사용")
                            .font(.app(.content1))
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.medium)
                            .background(
                                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                                    .fill(Color.wmMain)
                            )
                    }

                    Button {
                        onCancel()
                    } label: {
                        Text("다시 편집")
                            .font(.app(.content2))
                            .foregroundStyle(.textSub)
                    }
                }
                .padding(Spacing.base)
                .background(Color.wmBg)
            }
            .navigationTitle("미리보기")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Video Quality

enum VideoQuality: String, CaseIterable {
    case low = "저화질"
    case medium = "중화질"
    case high = "고화질"

    var displayName: String {
        rawValue
    }

    var description: String {
        switch self {
        case .low:
            return "640x480, 파일 크기 작음"
        case .medium:
            return "1280x720, 권장"
        case .high:
            return "1920x1080, 파일 크기 큼"
        }
    }

    var preset: String {
        switch self {
        case .low:
            return AVAssetExportPreset640x480
        case .medium:
            return AVAssetExportPreset1280x720
        case .high:
            return AVAssetExportPreset1920x1080
        }
    }

    var bitrate: Int {
        switch self {
        case .low:
            return 800_000 // 800Kbps
        case .medium:
            return 2_000_000 // 2Mbps
        case .high:
            return 5_000_000 // 5Mbps
        }
    }
}

// MARK: - Subtitle

struct Subtitle {
    let text: String
    let startTime: Double
    let endTime: Double
}

// MARK: - Video Editor Error

enum VideoEditorError: LocalizedError {
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .exportFailed(let message):
            return message
        }
    }
}
