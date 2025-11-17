//
//  SignIntent.swift
//  WeeMo
//
//  Created by Lee on 11/14/25.
//

import Foundation

enum SignIntent {
    case idChanged(String)
    case pwChanged(String)
    case nicknameChanged(String)
    case emailValidTapped
    case joinTapped
}
