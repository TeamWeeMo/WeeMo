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
}
