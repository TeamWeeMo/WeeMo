//
//  CustomMediaPickerView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/27/25.
//

import SwiftUI
import Photos
import UIKit

// MARK: - Custom Media Picker View

/// 커스텀 미디어 피커 (바텀시트, 동영상 즉시 감지)
struct CustomMediaPickerView: View {
    // MARK: - Properties

    let maxSelectionCount: Int
    let onImageSelected: ([UIImage]) -> Void
    let onVideoSelected: (URL) -> Void
    let onDismiss: () -> Void

    // MARK: - State

    @State private var assets: [PHAsset] = []
    @State private var selectedAssets: [String] = [] // Array로 선택 순서 유지
    @State private var loadedImages: [String: UIImage] = [:] // assetID: thumbnail

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if assets.isEmpty {
                    loadingView
                } else {
                    mediaGridView
                }
            }
            .navigationTitle("사진 및 동영상 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        onDismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("완료 (\(selectedAssets.count)/\(maxSelectionCount))") {
                        completeSelection()
                    }
                    .disabled(selectedAssets.isEmpty)
                    .foregroundStyle(selectedAssets.isEmpty ? .textSub : .wmMain)
                }
            }
            .onAppear {
                requestPermissionAndLoadAssets()
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: Spacing.base) {
            ProgressView()
            Text("미디어 로딩 중...")
                .font(.app(.content2))
                .foregroundStyle(.textSub)
        }
    }

    private var mediaGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2)
                ],
                spacing: 2
            ) {
                ForEach(assets, id: \.localIdentifier) { asset in
                    MediaCell(
                        asset: asset,
                        thumbnail: loadedImages[asset.localIdentifier],
                        isSelected: selectedAssets.contains(asset.localIdentifier),
                        selectionIndex: selectedAssets.firstIndex(of: asset.localIdentifier).map { $0 + 1 }
                    ) {
                        handleAssetTap(asset)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Methods

    /// 권한 요청 및 미디어 로드
    private func requestPermissionAndLoadAssets() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            if status == .authorized || status == .limited {
                loadAssets()
            }
        }
    }

    /// 앨범에서 미디어 로드
    private func loadAssets() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        var loadedAssets: [PHAsset] = []

        fetchResult.enumerateObjects { asset, _, _ in
            loadedAssets.append(asset)
        }

        Task { @MainActor in
            self.assets = loadedAssets

            // 썸네일 로드 (비동기)
            for asset in loadedAssets {
                loadThumbnail(for: asset)
            }
        }
    }

    /// 썸네일 로드
    private func loadThumbnail(for asset: PHAsset) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isSynchronous = false

        let size = CGSize(width: 200, height: 200)
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            if let image = image {
                Task { @MainActor in
                    loadedImages[asset.localIdentifier] = image
                }
            }
        }
    }

    /// 미디어 탭 처리
    private func handleAssetTap(_ asset: PHAsset) {
        // 동영상인 경우 즉시 처리
        if asset.mediaType == .video {
            loadVideoURL(for: asset) { url in
                if let url = url {
                    onVideoSelected(url)
                }
            }
            return
        }

        // 이미지인 경우 다중 선택
        let assetID = asset.localIdentifier

        if let index = selectedAssets.firstIndex(of: assetID) {
            // 이미 선택된 경우 선택 해제
            selectedAssets.remove(at: index)
        } else {
            // 최대 개수 체크
            if selectedAssets.count >= maxSelectionCount {
                return
            }
            selectedAssets.append(assetID)
        }
    }

    /// 동영상 URL 로드
    private func loadVideoURL(for asset: PHAsset, completion: @escaping (URL?) -> Void) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            if let urlAsset = avAsset as? AVURLAsset {
                // 임시 파일로 복사
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("video_\(UUID().uuidString)")
                    .appendingPathExtension("mov")

                do {
                    try FileManager.default.copyItem(at: urlAsset.url, to: tempURL)
                    Task { @MainActor in
                        completion(tempURL)
                    }
                } catch {
                    print("⚠️ 동영상 복사 실패: \(error)")
                    Task { @MainActor in
                        completion(nil)
                    }
                }
            } else {
                Task { @MainActor in
                    completion(nil)
                }
            }
        }
    }

    /// 선택 완료 (이미지만)
    private func completeSelection() {
        var images: [UIImage] = []
        let dispatchGroup = DispatchGroup()

        for assetID in selectedAssets {
            guard let asset = assets.first(where: { $0.localIdentifier == assetID }) else { continue }

            dispatchGroup.enter()

            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                if let image = image {
                    images.append(image)
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            onImageSelected(images)
        }
    }
}

// MARK: - Media Cell

private struct MediaCell: View {
    let asset: PHAsset
    let thumbnail: UIImage?
    let isSelected: Bool
    let selectionIndex: Int?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            GeometryReader { geometry in
                ZStack {
                    // 썸네일 이미지
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    } else {
                        Color.gray.opacity(0.2)
                    }

                    // 동영상 오버레이
                    if asset.mediaType == .video {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "video.fill")
                                    .foregroundStyle(.white)
                                Text(formatDuration(asset.duration))
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .padding(4)
                            .background(Color.black.opacity(0.5))
                        }
                    }

                    // 선택 표시
                    if isSelected, let index = selectionIndex {
                        VStack {
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.wmMain)
                                        .frame(width: 28, height: 28)

                                    Text("\(index)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .padding(6)
                            }
                            Spacer()
                        }
                    }

                    // 선택 테두리
                    if isSelected {
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.wmMain, lineWidth: 3)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
