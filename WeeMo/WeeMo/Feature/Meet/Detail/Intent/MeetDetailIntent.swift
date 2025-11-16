//
//  MeetDetailIntent.swift
//  WeeMo
//
//  Created by Claude on 11/16/25.
//

import Foundation

enum MeetDetailIntent {
    case loadMeetDetail(postId: String)
    case retryLoadMeetDetail
    case joinMeet(postId: String)
}