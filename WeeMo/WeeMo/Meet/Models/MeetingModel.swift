//
//  MeetingModel.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import Foundation

struct Meeting: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let location: String
    let address: String
    let price: String
    let participants: String
    let imageName: String
    let daysLeft: String
}

enum SortOption: String, CaseIterable {
    case registrationDate = "등록일순"
    case deadline = "마감일순"
    case distance = "가까운 순"
}

