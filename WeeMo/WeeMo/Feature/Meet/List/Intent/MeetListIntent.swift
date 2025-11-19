//
//  MeetListIntent.swift
//  WeeMo
//
//  Created by 차지용 on 11/16/25.
//

import Foundation

enum MeetListIntent {
    case loadMeets
    case retryLoadMeets
    case searchMeets(query: String)
    case refreshMeets
    case sortMeets(option: SortOption)
}
