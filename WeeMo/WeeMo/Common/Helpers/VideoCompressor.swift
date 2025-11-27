//
//  VideoCompressor.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/27/25.
//

import AVFoundation
import UIKit

// MARK: - Video Compressor

/// 동영상 압축 헬퍼 (서버 업로드용)
enum VideoCompressor {

    // MARK: - Thumbnail Extraction

    /// 동영상에서 썸네일 추출
    /// - Parameter url: 동영상 파일 URL
    /// - Returns: 추출된 썸네일 이미지 (실패 시 nil)
    static func extractThumbnail(from url: URL) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        // 동영상 중간 지점에서 썸네일 추출
        let duration = try? await asset.load(.duration)
        let time = CMTime(seconds: (duration?.seconds ?? 0) / 2, preferredTimescale: 600)

        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("⚠️ [VideoCompressor] 썸네일 추출 실패: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Video Compression

    /// 동영상 압축 (최대 용량 제한)
    /// - Parameters:
    ///   - url: 원본 동영상 URL
    ///   - maxSizeInMB: 최대 파일 크기 (MB 단위, 기본: 10MB)
    /// - Returns: 압축된 동영상 Data (실패 시 nil)
    static func compress(_ url: URL, maxSizeInMB: Int = 10) async -> Data? {
        let maxSizeInBytes = maxSizeInMB * 1024 * 1024

        // 1. 원본 파일 크기 확인
        guard let originalSize = fileSize(of: url) else {
            print("⚠️ [VideoCompressor] 파일 크기 확인 실패")
            return nil
        }

        print("📹 [VideoCompressor] 원본 크기: \(originalSize / 1024 / 1024)MB")

        // 2. 이미 용량 이하면 그대로 반환
        if originalSize <= maxSizeInBytes {
            return try? Data(contentsOf: url)
        }

        // 3. 압축 필요 - 해상도와 비트레이트를 단계적으로 낮춤
        let compressionPresets: [(preset: String, bitrate: Int)] = [
            (AVAssetExportPresetMediumQuality, 2_000_000),    // 2Mbps
            (AVAssetExportPresetLowQuality, 1_000_000),       // 1Mbps
            (AVAssetExportPreset640x480, 800_000),            // 800Kbps
        ]

        for (preset, bitrate) in compressionPresets {
            if let compressedData = await compressVideo(url: url, preset: preset, bitrate: bitrate) {
                if compressedData.count <= maxSizeInBytes {
                    print("✅ [VideoCompressor] 압축 성공: \(compressedData.count / 1024 / 1024)MB (프리셋: \(preset))")
                    return compressedData
                } else {
                    print("⚠️ [VideoCompressor] 압축 후에도 용량 초과: \(compressedData.count / 1024 / 1024)MB")
                }
            }
        }

        print("❌ [VideoCompressor] 모든 압축 시도 실패")
        return nil
    }

    // MARK: - Private Helpers

    /// 파일 크기 반환 (bytes)
    private static func fileSize(of url: URL) -> Int? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int else {
            return nil
        }
        return size
    }

    /// 동영상 압축 실행
    /// - Parameters:
    ///   - url: 원본 동영상 URL
    ///   - preset: AVAssetExportSession 프리셋
    ///   - bitrate: 비디오 비트레이트 (bps)
    /// - Returns: 압축된 Data (실패 시 nil)
    private static func compressVideo(url: URL, preset: String, bitrate: Int) async -> Data? {
        let asset = AVURLAsset(url: url)

        // Export Session 생성
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            print("⚠️ [VideoCompressor] Export Session 생성 실패")
            return nil
        }

        // 출력 파일 경로
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        // Export 설정
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        // Note: videoComposition은 빈 instruction이 있으면 에러가 발생하므로 설정하지 않음
        // 프리셋에 의해 자동으로 해상도 조정됨

        // Export 실행
        await exportSession.export()

        // 결과 확인
        switch exportSession.status {
        case .completed:
            guard let data = try? Data(contentsOf: outputURL) else {
                print("⚠️ [VideoCompressor] 압축된 파일 읽기 실패")
                return nil
            }

            // 임시 파일 삭제
            try? FileManager.default.removeItem(at: outputURL)

            return data

        case .failed:
            print("⚠️ [VideoCompressor] 압축 실패: \(exportSession.error?.localizedDescription ?? "Unknown")")
            return nil

        case .cancelled:
            print("⚠️ [VideoCompressor] 압축 취소됨")
            return nil

        default:
            return nil
        }
    }
}
