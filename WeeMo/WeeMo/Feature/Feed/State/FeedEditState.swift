//
//  FeedEditState.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation
import UIKit

// MARK: - Feed Edit State

struct FeedEditState: Equatable {
    // UI 데이터
    var content: String = ""
    var selectedImages: [UIImage] = []

    // 로딩 상태
    var isUploading: Bool = false
    var uploadProgress: Double = 0.0

    // 에러
    var errorMessage: String?

    // 성공 여부
    var isSubmitted: Bool = false
    var createdFeed: Feed?

    // MARK: - Computed Properties

    /// 폼 유효성 검사
    var isFormValid: Bool {
        !content.isEmpty && content.count <= 500 && !selectedImages.isEmpty
    }

    /// 제출 가능 여부
    var canSubmit: Bool {
        isFormValid && !isUploading
    }

    /// 글자 수 표시
    var characterCountText: String {
        "\(content.count)/500"
    }

    /// 글자 수 초과 여부
    var isCharacterOverLimit: Bool {
        content.count > 500
    }

    // MARK: - Equatable (UIImage 제외)

    static func == (lhs: FeedEditState, rhs: FeedEditState) -> Bool {
        lhs.content == rhs.content &&
        lhs.selectedImages.count == rhs.selectedImages.count &&
        lhs.isUploading == rhs.isUploading &&
        lhs.uploadProgress == rhs.uploadProgress &&
        lhs.errorMessage == rhs.errorMessage &&
        lhs.isSubmitted == rhs.isSubmitted &&
        lhs.createdFeed == rhs.createdFeed
    }
}
