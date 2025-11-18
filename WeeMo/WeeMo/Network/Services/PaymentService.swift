//
//  PaymentService.swift
//  WeeMo
//
//  Created by Lee on 11/17/25.
//

import Foundation

// MARK: - Payment Service Protocol

protocol PaymentServicing {
    /// 내 결제 내역 조회
    func fetchMyPayments() async throws -> PaymentHistoryListDTO

    /// 결제 영수증 검증
    func validatePayment(impUid: String, postId: String) async throws -> PaymentValidationDTO
}

// MARK: - Payment Service Implementation

struct PaymentService: PaymentServicing {
    private let networkService: NetworkService

    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }

    func fetchMyPayments() async throws -> PaymentHistoryListDTO {
        try await networkService.request(
            PaymentRouter.fetchMyPayments,
            responseType: PaymentHistoryListDTO.self
        )
    }

    func validatePayment(impUid: String, postId: String) async throws -> PaymentValidationDTO {
        try await networkService.request(
            PaymentRouter.validatePayment(impUid: impUid, postId: postId),
            responseType: PaymentValidationDTO.self
        )
    }
}
