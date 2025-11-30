//
//  PaymentDTO.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation

// MARK: - Payment DTOs

/// 결제 영수증 검증 응답
struct PaymentValidationDTO: Decodable {
    let impUid: String
    let postId: String

    enum CodingKeys: String, CodingKey {
        case impUid = "imp_uid"
        case postId = "post_id"
    }
}

/// 결제 내역 DTO
struct PaymentHistoryDTO: Decodable {
    let buyerId: String
    let postId: String
    let merchantUid: String
    let productName: String
    let price: Int
    let paidAt: String

    enum CodingKeys: String, CodingKey {
        case buyerId = "buyer_id"
        case postId = "post_id"
        case merchantUid = "merchant_uid"
        case productName
        case price
        case paidAt
    }
}

/// 결제 내역 목록 응답
struct PaymentHistoryListDTO: Decodable {
    let data: [PaymentHistoryDTO]
}
