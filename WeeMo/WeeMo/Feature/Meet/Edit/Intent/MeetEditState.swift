//
//  MeetEditState.swift
//  WeeMo
//
//  Created by 차지용 on 11/14/25.
//

import Foundation
import UIKit

// MARK: - Meet Edit State

struct MeetEditState: Equatable {
    // MARK: - Form Data

    var title: String = ""
    var content: String = ""
    var capacity: Int = 1
    var gender: Gender = .anyone
    var recruitmentStartDate: Date = Date()
    var recruitmentEndDate: Date = Date().addingTimeInterval(7 * 24 * 60 * 60) // 기본 7일 후
    var meetingStartDate: Date = Date()
    var meetingEndDate: Date = Date()
    var totalHours: Int = 1
    var pricePerPerson: Int = 0

    // MARK: - Media Data (Image + Video)

    var selectedMediaItems: [MediaItem] = []
    var existingMediaURLs: [String] = []
    var shouldKeepExistingMedia: Bool = true
    var videoCompressionFailed: Bool = false

    // MARK: - Space Selection

    var spaces: [Space] = []
    var selectedSpace: Space? = nil
    var isLoadingSpaces: Bool = false
    var spacesErrorMessage: String? = nil

    // 선택한 공간의 예약 정보 (댓글에서 파싱)
    var reservationDate: Date? = nil
    var reservationStartHour: Int? = nil
    var reservationTotalHours: Int? = nil

    // MARK: - Loading States

    var isCreating: Bool = false
    var isUpdating: Bool = false
    var isLoadingForEdit: Bool = false

    // MARK: - Result States

    var isCreated: Bool = false
    var isUpdated: Bool = false

    // MARK: - Alert States

    var showErrorAlert: Bool = false
    var showSuccessAlert: Bool = false

    // MARK: - Error

    var errorMessage: String? = nil

    // MARK: - Payment States (for create mode)

    var createdPostId: String? = nil
    var shouldNavigateToPayment: Bool = false
    var showPaymentRequiredAlert: Bool = false
    var isValidatingPayment: Bool = false
    var paymentSuccessMessage: String? = nil

    // MARK: - Original Data (for edit mode)

    var originalMeet: Meet? = nil

    // MARK: - Computed Properties

    /// 폼 유효성 검사
    var isFormValid: Bool {
        !title.isEmpty &&
        !content.isEmpty &&
        capacity > 0 &&
        selectedSpace != nil
    }

    /// 제출 가능 여부
    var canSubmit: Bool {
        isFormValid && !isCreating && !isUpdating
    }

    /// 로딩 중 여부
    var isLoading: Bool {
        isCreating || isUpdating || isLoadingForEdit || isLoadingSpaces
    }

    /// 미디어 총 개수
    var totalMediaCount: Int {
        let existingCount = shouldKeepExistingMedia ? existingMediaURLs.count : 0
        return existingCount + selectedMediaItems.count
    }

    /// 참가비 계산 (공간 가격 기반)
    var calculatedPrice: Int {
        guard let space = selectedSpace, capacity > 0 else { return 0 }
        return (space.pricePerHour * totalHours) / capacity
    }

    // MARK: - Equatable

    static func == (lhs: MeetEditState, rhs: MeetEditState) -> Bool {
        lhs.title == rhs.title &&
        lhs.content == rhs.content &&
        lhs.capacity == rhs.capacity &&
        lhs.gender == rhs.gender &&
        lhs.recruitmentStartDate == rhs.recruitmentStartDate &&
        lhs.recruitmentEndDate == rhs.recruitmentEndDate &&
        lhs.selectedMediaItems.count == rhs.selectedMediaItems.count &&
        lhs.existingMediaURLs == rhs.existingMediaURLs &&
        lhs.selectedSpace?.id == rhs.selectedSpace?.id &&
        lhs.isCreating == rhs.isCreating &&
        lhs.isUpdating == rhs.isUpdating &&
        lhs.isCreated == rhs.isCreated &&
        lhs.isUpdated == rhs.isUpdated &&
        lhs.showErrorAlert == rhs.showErrorAlert &&
        lhs.showSuccessAlert == rhs.showSuccessAlert &&
        lhs.errorMessage == rhs.errorMessage &&
        lhs.createdPostId == rhs.createdPostId &&
        lhs.shouldNavigateToPayment == rhs.shouldNavigateToPayment &&
        lhs.showPaymentRequiredAlert == rhs.showPaymentRequiredAlert &&
        lhs.isValidatingPayment == rhs.isValidatingPayment &&
        lhs.paymentSuccessMessage == rhs.paymentSuccessMessage
    }
}
