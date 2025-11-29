//
//  MeetDetailIntent.swift
//  WeeMo
//
//  Created by 차지용 on 11/16/25.
//

import Foundation

enum MeetDetailIntent {
    // MARK: - Lifecycle
    case onAppear(postId: String)
    case retryLoad

    // MARK: - Actions
    case joinMeet
    case createChatRoom(opponentUserId: String)
    case toggleLike

    // MARK: - Navigation
    case navigateToEdit
    case dismissError
    case dismissChatError
    case clearChatNavigation

    // MARK: - Space Navigation
    case navigateToSpace(spaceId: String)
    case clearSpaceNavigation

    // MARK: - Payment
    case showPaymentConfirmAlert
    case dismissPaymentConfirmAlert
    case confirmPayment
    case clearPaymentNavigation
    case validatePayment(impUid: String, postId: String)
    case dismissPaymentSuccess
    case dismissPaymentError

    // MARK: - Action Sheet & Delete
    case showActionSheet
    case dismissActionSheet
    case showDeleteAlert
    case dismissDeleteAlert
    case deleteMeet
}
