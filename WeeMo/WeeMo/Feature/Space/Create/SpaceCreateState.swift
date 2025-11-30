//
//  SpaceCreateState.swift
//  WeeMo
//
//  Created by Reimos on 11/16/25.
//

import UIKit

// MARK: - Space Create State

struct SpaceCreateState {
    // 모드 (생성 또는 수정)
    var mode: Mode = .create
    var postId: String?  // 수정 모드일 때 게시글 ID

    // 입력 필드
    var title: String = ""
    var price: String = ""
    var address: String = ""
    var roadAddress: String = ""  // 도로명 주소
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

    // 미디어 (이미지 + 동영상, 최대 5개)
    var selectedMediaItems: [MediaItem] = []  // 팀원의 struct MediaItem 사용
    var existingFileURLs: [String] = []  // 수정 모드: 기존 파일 URL
    static let maxMediaCount = 5

    // 하위 호환성 (기존 코드 유지)
    var selectedImages: [UIImage] = []
    static let maxImageCount = 5

    // UI 상태
    var isLoading: Bool = false
    var errorMessage: String?
    var isSubmitSuccessful: Bool = false

    // MARK: - Mode

    enum Mode {
        case create
        case edit(postId: String)

        var title: String {
            switch self {
            case .create:
                return "공간 등록"
            case .edit:
                return "공간 수정"
            }
        }

        var submitButtonText: String {
            switch self {
            case .create:
                return "저장"
            case .edit:
                return "수정 완료"
            }
        }
    }

    // MARK: - Computed Properties

    /// 제출 버튼 활성화 여부
    var isSubmitEnabled: Bool {
        let hasMedia = !existingFileURLs.isEmpty || !selectedMediaItems.isEmpty

        return !title.isEmpty &&
        !price.isEmpty &&
        !address.isEmpty &&
        !description.isEmpty &&
        hasMedia &&  // 기존 파일이나 새 미디어 중 하나는 필수
        isValidPrice
    }

    /// 미디어 추가 가능 여부
    var canAddMoreMedia: Bool {
        selectedMediaItems.count < Self.maxMediaCount
    }

    /// 이미지 추가 가능 여부 (하위 호환성)
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
