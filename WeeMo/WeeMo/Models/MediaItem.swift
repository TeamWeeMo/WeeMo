//
//  MediaItem.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/27/25.
//

import UIKit

// MARK: - Media Type

/// 미디어 타입 (이미지 또는 동영상)
enum MediaType: Equatable {
    case image
    case video
}

// MARK: - Media Item

/// 업로드용 미디어 아이템 (이미지 + 동영상 통합)
struct MediaItem: Identifiable, Equatable {
    let id: UUID
    let type: MediaType
    let thumbnail: UIImage // 이미지는 원본, 동영상은 추출된 썸네일
    let data: Data // 압축된 데이터 (업로드용)
    let originalFileName: String? // 원본 파일명

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        type: MediaType,
        thumbnail: UIImage,
        data: Data,
        originalFileName: String? = nil
    ) {
        self.id = id
        self.type = type
        self.thumbnail = thumbnail
        self.data = data
        self.originalFileName = originalFileName
    }

    // MARK: - Computed Properties

    /// 파일 크기 (MB 단위)
    var fileSizeInMB: Double {
        return Double(data.count) / (1024 * 1024)
    }

    /// 파일 크기 텍스트
    var fileSizeText: String {
        let mb = fileSizeInMB
        if mb < 1 {
            return String(format: "%.0f KB", mb * 1024)
        } else {
            return String(format: "%.1f MB", mb)
        }
    }

    /// 미디어 타입 아이콘
    var typeIcon: String {
        switch type {
        case .image:
            return "photo"
        case .video:
            return "video.fill"
        }
    }

    /// 파일 확장자 (originalFileName 또는 타입 기반)
    var fileExtension: String {
        if let fileName = originalFileName,
           let ext = fileName.split(separator: ".").last {
            return String(ext).lowercased()
        }
        // 기본값
        return type == .image ? "jpg" : "mp4"
    }

    /// MIME 타입
    var mimeType: String {
        switch fileExtension {
        // 이미지
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "heic", "heif": return "image/heic"
        case "webp": return "image/webp"
        // 동영상
        case "mp4", "m4v": return "video/mp4"
        case "mov": return "video/quicktime"
        default:
            return type == .image ? "image/jpeg" : "video/mp4"
        }
    }

    // MARK: - Equatable

    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - MediaItem Factory

extension MediaItem {
    /// 이미지로부터 MediaItem 생성 (압축 포함)
    static func fromImage(_ image: UIImage, maxSizeInMB: Int = 10) -> MediaItem? {
        guard let compressedData = ImageCompressor.compress(image, maxSizeInMB: maxSizeInMB) else {
            return nil
        }

        return MediaItem(
            type: .image,
            thumbnail: image,
            data: compressedData,
            originalFileName: "image_\(UUID().uuidString).jpg"
        )
    }

    /// 동영상 URL로부터 MediaItem 생성 (압축 + 썸네일 추출 포함)
    static func fromVideo(_ videoURL: URL, maxSizeInMB: Int = 10) async -> MediaItem? {
        // 썸네일 추출
        guard let thumbnail = await VideoCompressor.extractThumbnail(from: videoURL) else {
            return nil
        }

        // 동영상 압축
        guard let compressedData = await VideoCompressor.compress(videoURL, maxSizeInMB: maxSizeInMB) else {
            return nil
        }

        return MediaItem(
            type: .video,
            thumbnail: thumbnail,
            data: compressedData,
            originalFileName: videoURL.lastPathComponent
        )
    }
}
