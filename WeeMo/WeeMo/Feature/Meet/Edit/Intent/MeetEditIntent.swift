//
//  MeetEditIntent.swift
//  WeeMo
//
//  Created by 차지용 on 11/14/25.
//

import Foundation

enum MeetEditIntent {
    // Space Selection
    case loadSpaces
    case selectSpace(Space)
    case retryLoadSpaces

    // Meet Creation
    case createMeet(title: String, description: String, capacity: Int, price: String, gender: String, selectedSpace: Space?, startDate: Date)
    case retryCreateMeet

    // Meet Edit
    case loadMeetForEdit(postId: String)
    case updateMeet(postId: String, title: String, description: String, capacity: Int, price: String, gender: String, selectedSpace: Space?, startDate: Date)
}
