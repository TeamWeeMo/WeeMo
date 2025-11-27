//
//  VideoHelper.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/27/25.
//

import Foundation
import AVFoundation
import UIKit

// MARK: - Video Thumbnail Cache

/// 동영상 썸네일 메모리 캐시
final class VideoThumbnailCache {
    static let shared = VideoThumbnailCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        // 메모리 제한 설정 (모든 썸네일 합쳐서 최대 30MB)
        cache.totalCostLimit = 30 * 1024 * 1024
        // 최대 50개 항목 (일반적으로 충분한 개수)
        cache.countLimit = 50
    }

    /// 캐시에서 썸네일 가져오기
    func getThumbnail(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    /// 캐시에 썸네일 저장
    func setThumbnail(_ image: UIImage, for key: String) {
        // 이미지 크기를 cost로 계산 (대략적)
        let cost = Int(image.size.width * image.size.height * 4) // RGBA
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    /// 캐시 초기화
    func clearCache() {
        cache.removeAllObjects()
    }
}

// MARK: - Video Helper

/// 동영상 관련 헬퍼 유틸리티
enum VideoHelper {

    // MARK: - Authentication Headers

    /// 동영상 다운로드/재생을 위한 인증 헤더 생성
    /// - Returns: 인증 헤더 딕셔너리
    static func makeAuthHeaders() -> [String: String] {
        var headers: [String: String] = [:]

        // 1. SeSACKey 추가
        if let sesacKey = Bundle.main.object(forInfoDictionaryKey: "SeSACKey") as? String {
            headers[HTTPHeaderKey.sesacKey] = sesacKey
        }

        // 2. ProductId 추가
        headers[HTTPHeaderKey.productId] = NetworkConstants.productId

        // 3. Authorization (AccessToken) 추가
        if let token = TokenManager.shared.accessToken {
            headers[HTTPHeaderKey.authorization] = token
        }

        return headers
    }

    // MARK: - AVURLAsset Creation

    /// 인증 헤더를 포함한 AVURLAsset 생성
    /// - Parameter url: 동영상 URL
    /// - Returns: 인증 헤더가 포함된 AVURLAsset
    static func makeAuthenticatedAsset(url: URL) -> AVURLAsset {
        let headers = makeAuthHeaders()
        return AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": headers
        ])
    }

    /// 서버 경로를 풀 URL로 변환하고 인증 헤더를 포함한 AVURLAsset 생성
    /// - Parameter videoPath: 서버 파일 경로 (예: "/data/posts/video_0_xxx.mp4")
    /// - Returns: 인증 헤더가 포함된 AVURLAsset, URL이 유효하지 않으면 nil
    static func makeAuthenticatedAsset(videoPath: String) -> AVURLAsset? {
        // 서버 경로를 풀 URL로 변환
        let fullURL = FileRouter.fileURL(from: videoPath)
        guard let url = URL(string: fullURL) else { return nil }

        return makeAuthenticatedAsset(url: url)
    }

    // MARK: - Thumbnail Extraction

    /// 동영상 서버 경로에서 썸네일 추출 (인증 헤더 + 캐싱 포함)
    /// - Parameters:
    ///   - videoPath: 서버 파일 경로 (예: "/data/posts/video_0_xxx.mp4")
    ///   - time: 썸네일을 추출할 시간 (기본값: 0.5초)
    ///   - maximumSize: 썸네일 최대 크기 (기본값: 1280x720, 가로 HD 해상도)
    /// - Returns: 썸네일 UIImage, 실패 시 nil
    static func extractThumbnail(
        from videoPath: String,
        at time: TimeInterval = 0.5,
        maximumSize: CGSize = CGSize(width: 1280, height: 720)
    ) async -> UIImage? {
        // 캐시 키 생성 (경로 + time + size)
        let cacheKey = "\(videoPath)_\(time)_\(Int(maximumSize.width))x\(Int(maximumSize.height))"

        // 캐시에서 먼저 확인
        if let cachedThumbnail = VideoThumbnailCache.shared.getThumbnail(for: cacheKey) {
            return cachedThumbnail
        }

        // 서버 경로를 풀 URL로 변환
        let fullURL = FileRouter.fileURL(from: videoPath)
        guard let url = URL(string: fullURL) else { return nil }

        // 썸네일 추출
        if let thumbnail = await extractThumbnail(from: url, at: time, maximumSize: maximumSize) {
            // 캐시에 저장
            VideoThumbnailCache.shared.setThumbnail(thumbnail, for: cacheKey)
            return thumbnail
        }

        return nil
    }

    /// 동영상 URL에서 썸네일 추출 (인증 헤더 포함)
    /// - Parameters:
    ///   - url: 동영상 URL
    ///   - time: 썸네일을 추출할 시간 (기본값: 0.5초)
    ///   - maximumSize: 썸네일 최대 크기 (기본값: 1280x720)
    /// - Returns: 썸네일 UIImage, 실패 시 nil
    static func extractThumbnail(
        from url: URL,
        at time: TimeInterval = 0.5,
        maximumSize: CGSize = CGSize(width: 1280, height: 720)
    ) async -> UIImage? {
        // 인증 헤더 포함 AVURLAsset 생성
        let asset = makeAuthenticatedAsset(url: url)

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = maximumSize

        do {
            let cmTime = CMTime(seconds: time, preferredTimescale: 600)
            let cgImage = try await imageGenerator.image(at: cmTime).image
            return UIImage(cgImage: cgImage)
        } catch {
            print("⚠️ [VideoHelper] Failed to extract thumbnail: \(error)")
            print("⚠️ [VideoHelper] Error details: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Video File Detection

    /// URL이 동영상 파일인지 확인
    /// - Parameter urlString: 확인할 URL 문자열
    /// - Returns: 동영상 파일이면 true, 아니면 false
    static func isVideoFile(_ urlString: String) -> Bool {
        let videoExtensions = ["mp4", "mov", "m4v", "avi", "mkv", "wmv", "flv"]
        let lowercased = urlString.lowercased()
        return videoExtensions.contains { lowercased.hasSuffix(".\($0)") }
    }
}
