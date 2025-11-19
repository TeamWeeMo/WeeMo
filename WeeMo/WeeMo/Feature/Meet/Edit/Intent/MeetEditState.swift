//
//  MeetEditState.swift
//  WeeMo
//
//  Created by 차지용 on 11/14/25.
//


import Foundation

// MARK: - Meet State

struct MeetEditState {
    // Space Selection State
    var spaces: [Space] = []
    var selectedSpace: Space? = nil
    var isLoadingSpaces: Bool = false
    var spacesErrorMessage: String? = nil

    // Meet Creation State
    var isCreatingMeet: Bool = false
    var createMeetErrorMessage: String? = nil
    var isMeetCreated: Bool = false

    // Meet Edit State
    var isLoadingMeetForEdit: Bool = false
    var originalMeetData: MeetDetail? = nil
    var loadMeetErrorMessage: String? = nil
    var isUpdatingMeet: Bool = false
    var updateMeetErrorMessage: String? = nil
    var isMeetUpdated: Bool = false
}
