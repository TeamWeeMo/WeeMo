//
//  SpaceCreateState.swift
//  WeeMo
//
//  Created by Reimos on 11/16/25.
//

import Foundation
import UIKit

// MARK: - Space Create State

struct SpaceCreateState {
    // 입력 필드
    var title: String = ""
    var price: String = ""
    var address: String = ""
    var latitude: Double = 37.5665   // 기본값: 서울 중심
    var longitude: Double = 126.9780  // 기본값: 서울 중심
    var rating: Double = 3.0  // Slider로 1.0 ~ 5.0, 0.5 단위
    var description: String = ""

    // 선택 필드
    var category: SpaceCategory = .all
    var isPopular: Bool = false

    // 편의시설
    var hasParking: Bool = false
    var hasRestroom: Bool = false
    var maxCapacity: String = ""

    // 해시태그
    var hashTagInput: String = ""
    var hashTags: [String] = []

    // 이미지 (최대 5개)
    var selectedImages: [UIImage] = []
    static let maxImageCount = 5

    // UI 상태
    var isLoading: Bool = false
    var errorMessage: String?
    var isSubmitSuccessful: Bool = false

    // MARK: - Computed Properties

    /// 제출 버튼 활성화 여부
    var isSubmitEnabled: Bool {
        !title.isEmpty &&
        !price.isEmpty &&
        !address.isEmpty &&
        !description.isEmpty &&
        !selectedImages.isEmpty &&
        isValidPrice
    }

    /// 이미지 추가 가능 여부
    var canAddMoreImages: Bool {
        selectedImages.count < Self.maxImageCount
    }

    /// 평점 포맷팅 (소수점 1자리)
    var formattedRating: String {
        String(format: "%.1f", rating)
    }

    /// 가격 유효성 검사 (양수)
    var isValidPrice: Bool {
        guard let priceValue = Int(price) else { return false }
        return priceValue > 0
    }

    /// 해시태그 추가 가능 여부
    var canAddHashTag: Bool {
        !hashTagInput.trimmingCharacters(in: .whitespaces).isEmpty &&
        !hashTags.contains(hashTagInput.trimmingCharacters(in: .whitespaces))
    }
}
