//
//  MeetEditIntent.swift
//  WeeMo
//
//  Created by 차지용 on 11/14/25.
//

import Foundation
import SwiftUI
import UIKit
import PhotosUI

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

    // MARK: - Media (Image + Video)

    case selectMediaItems([MediaItem])
    case removeMediaItem(at: Int)
    case removeExistingMedia(at: Int)
    case loadMediaFromPhotos([PhotosPickerItem])
    case handleSelectedImages([UIImage])
    case autoCompressVideo(URL)
    case setVideoCompressionFailed
    case resetVideoCompressionFailed

    // MARK: - Space Selection

    case loadSpaces
    case selectSpace(Space)
    case confirmSpaceSelection

    // MARK: - Submit

    case createMeet
    case updateMeet(postId: String)

    // MARK: - Navigation

    case cancel

    // MARK: - Alert

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
