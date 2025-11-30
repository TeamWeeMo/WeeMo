//
//  ImageCompressor.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/15/25.
//

import UIKit

// MARK: - Image Compressor

/// 이미지 압축 헬퍼 (서버 업로드용)
enum ImageCompressor {
    /// 이미지 압축 (최대 용량 제한)
    /// - Parameters:
    ///   - images: 원본 이미지 배열
    ///   - maxSizeInMB: 최대 파일 크기 (MB 단위, 기본: 10MB)
    ///   - maxDimension: 최대 이미지 크기 (픽셀, 기본: 2048px)
    /// - Returns: 압축된 이미지 Data 배열
    static func compress(
        _ images: [UIImage],
        maxSizeInMB: Int = 10,
        maxDimension: CGFloat = 2048
    ) -> [Data] {
        let maxSizeInBytes = maxSizeInMB * 1024 * 1024

        return images.compactMap { image in
            // 1. 초기 압축 (0.8 품질)
            guard var imageData = image.jpegData(compressionQuality: 0.8) else {
                return nil
            }

            // 2. 제한 용량 이하면 그대로 반환
            if imageData.count <= maxSizeInBytes {
                return imageData
            }

            // 3. 용량 초과 시: 리사이징 + 동적 압축
            var currentImage = image
            var compressionQuality: CGFloat = 0.8

            // 3-1. 이미지 크기가 너무 크면 리사이징
            if image.size.width > maxDimension || image.size.height > maxDimension {
                let ratio = min(maxDimension / image.size.width, maxDimension / image.size.height)
                let newSize = CGSize(
                    width: image.size.width * ratio,
                    height: image.size.height * ratio
                )

                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                currentImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
                UIGraphicsEndImageContext()

                // 리사이징 후 재압축
                imageData = currentImage.jpegData(compressionQuality: compressionQuality) ?? imageData
            }

            // 3-2. 여전히 용량 초과 시: 품질 단계적 감소
            while imageData.count > maxSizeInBytes && compressionQuality > 0.1 {
                compressionQuality -= 0.1
                if let compressedData = currentImage.jpegData(compressionQuality: compressionQuality) {
                    imageData = compressedData
                } else {
                    break
                }
            }

            // 4. 최종 검증 (용량 초과 시 경고 로그)
            if imageData.count > maxSizeInBytes {
                print("[ImageCompressor] 이미지 압축 실패: \(imageData.count / 1024 / 1024)MB (최대 \(maxSizeInMB)MB)")
            }

            return imageData
        }
    }

    /// 단일 이미지 압축
    /// - Parameters:
    ///   - image: 원본 이미지
    ///   - maxSizeInMB: 최대 파일 크기 (MB 단위, 기본: 10MB)
    ///   - maxDimension: 최대 이미지 크기 (픽셀, 기본: 2048px)
    /// - Returns: 압축된 이미지 Data (실패 시 nil)
    static func compress(
        _ image: UIImage,
        maxSizeInMB: Int = 10,
        maxDimension: CGFloat = 2048
    ) -> Data? {
        return compress([image], maxSizeInMB: maxSizeInMB, maxDimension: maxDimension).first
    }
}
