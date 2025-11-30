//
//  SpaceCreateIntent.swift
//  WeeMo
//
//  Created by Reimos on 11/16/25.
//

import Foundation
import UIKit

// MARK: - Space Create Intent

enum SpaceCreateIntent {
    // 텍스트 입력
    case titleChanged(String)
    case priceChanged(String)
    case addressChanged(String)
    case addressSelected(address: String, roadAddress: String, latitude: Double, longitude: Double)
    case ratingChanged(Double)  // Slider 값 (1.0 ~ 5.0, 0.5 단위)
    case descriptionChanged(String)

    // 카테고리 선택
    case categoryChanged(SpaceCategory)

    // 인기 공간 여부
    case popularToggled(Bool)

    // 편의시설
    case parkingToggled(Bool)
    case restroomToggled(Bool)
    case maxCapacityChanged(String)

    // 해시태그
    case hashTagInputChanged(String)
    case addHashTag
    case removeHashTag(String)

    // 미디어 (이미지 + 동영상)
    case mediaItemsSelected([MediaItem])  // 팀원의 struct MediaItem
    case mediaItemRemoved(at: Int)

    // 기존 파일 (수정 모드)
    case existingFileRemoved(at: Int)

    // 이미지 (하위 호환성)
    case imageSelected(UIImage)
    case imageRemoved(at: Int)

    // 제출
    case submitButtonTapped
    case resetForm
}
