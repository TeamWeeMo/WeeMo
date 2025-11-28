//
//  FileRouter.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/13/25.
//

import Foundation
import Alamofire

// MARK: - File Router

enum FileRouter: APIRouter {
    /// 파일 다운로드 (이미지, 비디오 등)
    /// - Parameter filePath: 서버에서 받은 파일 경로 (예: "/data/profiles/1763021779523.png")
    case downloadFile(filePath: String)

    // MARK: - APIRouter Implementation

    var method: HTTPMethod {
        .get
    }

    var path: String {
        let version = NetworkConstants.apiVersion
        switch self {
        case .downloadFile(let filePath):
            // filePath가 /data/... 형태로 오면 v1/data/... 로 변환 (앞의 / 제거)
            if filePath.hasPrefix("/data/") {
                return "\(version)\(filePath)"
            } else if filePath.hasPrefix("data/") {
                return "\(version)/\(filePath)"
            } else {
                // 이미 /v1/data/... 형태면 그대로 반환
                return filePath
            }
        }
    }

    var parameters: Parameters? {
        nil
    }

    var needsAuthorization: Bool {
        true
    }
}

// MARK: - File URL Helper

extension FileRouter {
    /// 파일 경로를 풀 URL로 변환하는 헬퍼
    /// - Parameter filePath: 서버에서 받은 파일 경로
    /// - Returns: 풀 URL 문자열
    static func fileURL(from filePath: String) -> String {
        var baseURL = NetworkConstants.baseURL
        let version = NetworkConstants.apiVersion
        return "\(baseURL)\(version)\(filePath)"
    }
}
