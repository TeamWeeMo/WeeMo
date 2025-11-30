//
//  PaymentRouter.swift
//  WeeMo
//
//  Created by Lee on 11/17/25.
//

import Foundation
import Alamofire

// MARK: - Payment Router

enum PaymentRouter: APIRouter {
    // 결제 내역 조회
    case fetchMyPayments

    // 결제 영수증 검증
    case validatePayment(impUid: String, postId: String)

    // MARK: - APIRouter Implementation

    var method: HTTPMethod {
        switch self {
        case .fetchMyPayments:
            return .get
        case .validatePayment:
            return .post
        }
    }

    var path: String {
        let version = NetworkConstants.apiVersion
        switch self {
        case .fetchMyPayments:
            return "\(version)/payments/me"
        case .validatePayment:
            return "\(version)/payments/validation"
        }
    }

    var parameters: Parameters? {
        switch self {
        case .fetchMyPayments:
            return nil
        case .validatePayment(let impUid, let postId):
            return [
                "imp_uid": impUid,
                "post_id": postId
            ]
        }
    }
}
