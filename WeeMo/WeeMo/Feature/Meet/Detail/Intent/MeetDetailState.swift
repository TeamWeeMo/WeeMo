//
//  MeetDetailState.swift
//  WeeMo
//
//  Created by 차지용 on 11/16/25.
//

import Foundation

struct MeetDetailState {
    // MARK: - Data
    var meet: Meet? = nil

    // MARK: - Loading States
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // MARK: - Join States
    var isJoining: Bool = false
    var joinErrorMessage: String? = nil
    var hasJoined: Bool = false

    // MARK: - Chat States
    var isCreatingChat: Bool = false
    var createdChatRoom: ChatRoom? = nil
    var chatErrorMessage: String? = nil

    // MARK: - Navigation
    var shouldNavigateToChat: Bool = false
    var shouldNavigateToEdit: Bool = false

    // MARK: - Space Navigation
    var isLoadingSpace: Bool = false
    var loadedSpace: Space? = nil
    var shouldNavigateToSpace: Bool = false

    // MARK: - Payment States
    var showPaymentConfirmAlert: Bool = false
    var shouldNavigateToPayment: Bool = false
    var isValidatingPayment: Bool = false
    var paymentSuccessMessage: String? = nil
    var paymentErrorMessage: String? = nil

    // MARK: - Action Sheet & Delete States
    var showActionSheet: Bool = false
    var showDeleteAlert: Bool = false
    var isDeleting: Bool = false
    var isDeleted: Bool = false
}
