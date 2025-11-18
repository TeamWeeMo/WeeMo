//
//  ImageAspectRatioCalculator.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/15/25.
//

import SwiftUI

// MARK: - Image Aspect Ratio Calculator

/// 이미지 비율 계산 헬퍼
enum ImageAspectRatioCalculator {
    /// Pinterest 레이아웃용 이미지 비율 계산 및 업데이트
    /// - Parameters:
    ///   - image: UIImage
    ///   - binding: 비율을 저장할 Binding<CGFloat>
    static func updateAspectRatio(from image: UIImage, binding: Binding<CGFloat>) {
        // SwiftUI .aspectRatio()는 너비/높이 비율을 받음 (width/height)
        // 가로 사진: 1.0 초과 (너비가 더 큼)
        // 정사각형: 1.0
        // 세로 사진: 1.0 미만 (높이가 더 큼)
        let widthToHeightRatio = image.size.width / image.size.height

        // Pinterest 레이아웃을 위해 비율 제한
        // 최소: 0.56 (세로가 긴 사진, 약 9:16 비율)
        // 최대: 1.25 (가로가 조금 긴 사진, 약 5:4 비율)
        let clampedRatio = min(max(widthToHeightRatio, 0.56), 1.25)

        // 비율이 변경되었을 때만 업데이트 (레이아웃 재계산 트리거)
        if abs(binding.wrappedValue - clampedRatio) > 0.01 {
            withAnimation(.easeInOut(duration: 0.2)) {
                binding.wrappedValue = clampedRatio
            }
        }
    }

    /// 커스텀 비율 제한으로 계산
    /// - Parameters:
    ///   - image: UIImage
    ///   - minRatio: 최소 비율 (기본: 0.56)
    ///   - maxRatio: 최대 비율 (기본: 1.25)
    /// - Returns: 제한된 비율
    static func calculateAspectRatio(
        from image: UIImage,
        minRatio: CGFloat = 0.56,
        maxRatio: CGFloat = 1.25
    ) -> CGFloat {
        let widthToHeightRatio = image.size.width / image.size.height
        return min(max(widthToHeightRatio, minRatio), maxRatio)
    }
}
