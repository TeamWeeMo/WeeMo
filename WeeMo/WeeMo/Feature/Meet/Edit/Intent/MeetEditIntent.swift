//
//  MeetEditIntent.swift
//  WeeMo
//
//  Created by 차지용 on 11/14/25.
//

import Foundation
import UIKit

// MARK: - Meet Edit Intent

enum MeetEditIntent {
    // MARK: - Lifecycle

    case onAppear
    case loadMeetForEdit(postId: String)

    // MARK: - Form Updates

    case updateTitle(String)
    case updateContent(String)
    case updateCapacity(Int)
    case updateGender(Gender)
    case updateRecruitmentStartDate(Date)
    case updateRecruitmentEndDate(Date)
    case updateMeetingStartDate(Date)
    case updateMeetingEndDate(Date)
    case updateTotalHours(Int)

    // MARK: - Image

    case selectImages([UIImage])
    case removeImage(at: Int)
    case removeExistingImage(at: Int)

    // MARK: - Space Selection

    case loadSpaces
    case selectSpace(Space)
    case confirmSpaceSelection

    // MARK: - Submit

    case createMeet
    case updateMeet(postId: String)
    case deleteMeet(postId: String)

    // MARK: - Navigation

    case cancel

    // MARK: - Alert

    case showDeleteAlert
    case dismissDeleteAlert
    case showErrorAlert
    case dismissErrorAlert
    case showSuccessAlert
    case dismissSuccessAlert

    // MARK: - Payment (for create mode)

    case showPaymentRequiredAlert
    case dismissPaymentRequiredAlert
    case confirmPayment
    case clearPaymentNavigation
    case validatePayment(impUid: String, postId: String)
    case dismissPaymentSuccess
}
