//
//  KingfisherHelper.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/15/25.
//

import Foundation
import Kingfisher
import SwiftUI

// MARK: - Kingfisher Helper

extension KFImage {
    /// 인증 헤더를 포함한 이미지 다운로드 설정
    /// - Returns: 인증 헤더가 추가된 KFImage
    func withAuthHeaders() -> KFImage {
        // 헤더 구성
        let modifier = AnyModifier { request in
            var modifiedRequest = request

            // 1. SeSACKey 추가
            if let sesacKey = Bundle.main.object(forInfoDictionaryKey: "SeSACKey") as? String {
                modifiedRequest.setValue(sesacKey, forHTTPHeaderField: HTTPHeaderKey.sesacKey)
            }

            // 2. ProductId 추가
            modifiedRequest.setValue(NetworkConstants.productId, forHTTPHeaderField: HTTPHeaderKey.productId)

            // 3. Authorization (AccessToken) 추가 - Keychain에서 가져오기
            if let token = TokenManager.shared.accessToken {
                modifiedRequest.setValue(token, forHTTPHeaderField: HTTPHeaderKey.authorization)
            }

            return modifiedRequest
        }

        return self.requestModifier(modifier)
    }

    /// 피드 카드용 이미지 설정 (인증 + 재시도 + 비율 계산)
    /// - Parameters:
    ///   - aspectRatio: 동적 비율을 저장할 Binding
    ///   - onSuccess: 성공 시 추가 콜백 (옵션)
    /// - Returns: 설정이 완료된 KFImage
    func feedImageSetup(
        aspectRatio: Binding<CGFloat>,
        onSuccess: ((RetrieveImageResult) -> Void)? = nil
    ) -> KFImage {
        self
            .withAuthHeaders()
            .placeholder {
                Rectangle()
                    .imagePlaceholder()
                    .aspectRatio(1.0, contentMode: .fit)
            }
            .retry(maxCount: 3, interval: .seconds(2))
            .onSuccess { result in
                // 비율 계산 및 업데이트
                ImageAspectRatioCalculator.updateAspectRatio(
                    from: result.image,
                    binding: aspectRatio
                )
                // 추가 콜백 실행
                onSuccess?(result)
            }
            .onFailure { error in
                print("이미지 로드 실패: \(error.localizedDescription)")
            }
            .resizable()
    }

    /// 프로필 이미지 설정 (인증 + 원형)
    /// - Returns: 설정이 완료된 KFImage
    func profileImageSetup() -> KFImage {
        self
            .withAuthHeaders()
            .placeholder {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.gray)
                            .font(.system(size: 16))
                    }
            }
            .retry(maxCount: 3, interval: .seconds(2))
            .onFailure { error in
                print("프로필 이미지 로드 실패: \(error.localizedDescription)")
            }
            .resizable()
    }

    /// 피드 상세 이미지 설정 (인증 + 재시도)
    /// - Returns: 설정이 완료된 KFImage
    func feedDetailImageSetup() -> KFImage {
        self
            .withAuthHeaders()
            .placeholder {
                Rectangle()
                    .imagePlaceholder()
                    .aspectRatio(1.0, contentMode: .fit)
            }
            .retry(maxCount: 3, interval: .seconds(2))
            .onFailure { error in
                print("피드 상세 이미지 로드 실패: \(error.localizedDescription)")
            }
            .resizable()
    }
}
