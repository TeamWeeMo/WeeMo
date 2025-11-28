//
//  KingfisherHelper.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/15/25.
//

import Foundation
import Kingfisher
import SwiftUI
import AVFoundation

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
                print(token)
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

// MARK: - Video Resource Loader Delegate

/// 비디오 스트리밍 시 인증 헤더를 추가하는 Resource Loader Delegate
class VideoResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    private let originalURL: URL

    init(originalURL: URL) {
        self.originalURL = originalURL
        super.init()
    }

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        print("[VideoLoader] Delegate 호출됨")

        guard let url = loadingRequest.request.url else {
            print("[VideoLoader] URL 없음")
            return false
        }

        print("[VideoLoader] 요청 URL: \(url)")

        // Custom scheme을 원래 https로 변경
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("[VideoLoader] URLComponents 생성 실패")
            return false
        }
        components.scheme = originalURL.scheme

        guard let actualURL = components.url else {
            print("[VideoLoader] 실제 URL 변환 실패")
            return false
        }

        print("[VideoLoader] 실제 URL: \(actualURL)")

        // 인증 헤더를 포함한 URLRequest 생성
        var request = URLRequest(url: actualURL)

        // 1. SeSACKey 추가
        if let sesacKey = Bundle.main.object(forInfoDictionaryKey: "SeSACKey") as? String {
            request.setValue(sesacKey, forHTTPHeaderField: HTTPHeaderKey.sesacKey)
        }

        // 2. ProductId 추가
        request.setValue(NetworkConstants.productId, forHTTPHeaderField: HTTPHeaderKey.productId)

        // 3. Authorization (AccessToken) 추가
        if let token = TokenManager.shared.accessToken {
            request.setValue(token, forHTTPHeaderField: HTTPHeaderKey.authorization)
        }

        // Range 헤더 추가 (스트리밍용)
        if let rangeValue = loadingRequest.request.value(forHTTPHeaderField: "Range") {
            request.setValue(rangeValue, forHTTPHeaderField: "Range")
            print("[VideoLoader] Range: \(rangeValue)")
        }

        print("[VideoLoader] 네트워크 요청 시작...")

        // 네트워크 요청 실행
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in

            if let error = error {
                print("[VideoLoader] 네트워크 에러: \(error.localizedDescription)")
                loadingRequest.finishLoading(with: error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("[VideoLoader] HTTP 응답 없음")
                loadingRequest.finishLoading()
                return
            }

            print("[VideoLoader] 응답 상태코드: \(httpResponse.statusCode)")

            // Content Information 설정
            if let contentInformationRequest = loadingRequest.contentInformationRequest {
                // Content-Type 설정
                if let contentType = httpResponse.mimeType {
                    contentInformationRequest.contentType = contentType
                    print("[VideoLoader] Content-Type: \(contentType)")
                }

                // Content-Length 설정 (전체 파일 크기)
                // Range 응답인 경우 Content-Range 헤더에서 전체 크기 추출
                if let contentRange = httpResponse.allHeaderFields["Content-Range"] as? String {
                    // Content-Range: bytes 0-1/2285656 형식에서 총 크기 추출
                    if let totalSize = contentRange.split(separator: "/").last,
                       let totalBytes = Int64(totalSize) {
                        contentInformationRequest.contentLength = totalBytes
                        print("[VideoLoader] 전체 Content-Length (from Range): \(totalBytes)")
                    }
                } else if let contentLengthString = httpResponse.allHeaderFields["Content-Length"] as? String,
                          let contentLength = Int64(contentLengthString) {
                    contentInformationRequest.contentLength = contentLength
                    print("[VideoLoader] Content-Length: \(contentLength)")
                } else if httpResponse.expectedContentLength > 0 {
                    contentInformationRequest.contentLength = httpResponse.expectedContentLength
                    print("[VideoLoader] Expected Content-Length: \(httpResponse.expectedContentLength)")
                }

                // Range 요청 지원
                contentInformationRequest.isByteRangeAccessSupported = true
            }

            // 데이터 전달
            if let data = data, let dataRequest = loadingRequest.dataRequest {
                print("[VideoLoader] 데이터 수신: \(data.count) bytes")
                dataRequest.respond(with: data)
            } else {
                print("[VideoLoader] 데이터 없음")
            }

            loadingRequest.finishLoading()
            print("[VideoLoader] 로딩 완료")
        }

        task.resume()
        return true
    }
}

// MARK: - Video Helper

/// 비디오 스트리밍을 위한 헬퍼 클래스
class VideoHelper {
    static let shared = VideoHelper()

    private init() {}

    /// 인증 헤더를 포함한 비디오 스트리밍을 위한 AVAsset과 Delegate 반환
    /// - Parameter urlString: 비디오 URL 문자열
    /// - Returns: (AVAsset, ResourceLoaderDelegate) 튜플
    func createStreamingAsset(from urlString: String) -> (AVURLAsset, VideoResourceLoaderDelegate)? {
        print("[VideoHelper] Asset 생성 시작: \(urlString)")

        guard let originalURL = URL(string: urlString) else {
            print("[VideoHelper] URL 생성 실패")
            return nil
        }

        // Custom URL scheme으로 변경
        guard var components = URLComponents(url: originalURL, resolvingAgainstBaseURL: false) else {
            print("[VideoHelper] URLComponents 생성 실패")
            return nil
        }
        components.scheme = "custom-streaming"

        guard let customURL = components.url else {
            print("[VideoHelper] Custom URL 생성 실패")
            return nil
        }

        print("[VideoHelper] Custom URL: \(customURL)")

        // Asset 및 Delegate 생성
        let asset = AVURLAsset(url: customURL)
        let delegate = VideoResourceLoaderDelegate(originalURL: originalURL)

        print("[VideoHelper] Asset과 Delegate 생성 완료")
        return (asset, delegate)
    }
}
