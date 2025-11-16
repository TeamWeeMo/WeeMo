//
//  BuyPostResponseDTO.swift
//  WeeMo
//
//  Created by Claude on 11/16/25.
//

import Foundation

struct BuyPostResponseDTO: Decodable {
    let postId: String
    let buyerId: String
    let amount: Int
    let status: String

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case buyerId = "buyer_id"
        case amount
        case status
    }
}