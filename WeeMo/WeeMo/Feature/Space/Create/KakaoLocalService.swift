//
//  KakaoLocalService.swift
//  WeeMo
//
//  Created by Reimos on 2025/11/19.
//

import Foundation

// MARK: - Kakao Address Search Response

struct KakaoAddressSearchResponse: Codable {
    let documents: [KakaoDocument]
    let meta: KakaoMeta
}

struct KakaoDocument: Codable {
    let placeName: String?
    let addressName: String
    let roadAddressName: String?
    let x: String  // longitude
    let y: String  // latitude

    enum CodingKeys: String, CodingKey {
        case placeName = "place_name"
        case addressName = "address_name"
        case roadAddressName = "road_address_name"
        case x, y
    }
}

struct KakaoMeta: Codable {
    let totalCount: Int

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
    }
}

// MARK: - Address Search Result Model

struct AddressSearchResult: Identifiable {
    let id = UUID()
    let placeName: String
    let address: String
    let roadAddress: String?
    let latitude: Double
    let longitude: Double

    var displayText: String {
        if !placeName.isEmpty {
            return placeName
        }
        return roadAddress ?? address
    }

    var subText: String {
        if !placeName.isEmpty {
            return roadAddress ?? address
        }
        return ""
    }
}

// MARK: - Kakao Local Service

final class KakaoLocalService {
    private let baseURL = "https://dapi.kakao.com"

    // Info.plist에서 KakaoKey 읽어오기
    private var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "KakaoKey") as? String else {
            return ""
        }
        return key
    }

    // MARK: - 주소 검색

    /// 키워드로 장소 검색
    func searchAddress(query: String) async throws -> [AddressSearchResult] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }

        print("[KakaoLocalService] 검색 쿼리: \(query)")
        print("[KakaoLocalService] API Key: \(apiKey.isEmpty ? "없음" : "설정됨")")

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/v2/local/search/keyword.json?query=\(encodedQuery)&size=15"

        guard let url = URL(string: urlString) else {
            throw NetworkError.badRequest("유효하지 않은 URL입니다.")
        }

        print("[KakaoLocalService] 요청 URL: \(urlString)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("KakaoAK \(apiKey)", forHTTPHeaderField: "Authorization")

        // KA 헤더 추가 (iOS 앱에서 필수)
        let kaHeader = "os/ios origin/\(Bundle.main.bundleIdentifier ?? "com.TeamWeeMo.WeeMo")"
        request.setValue(kaHeader, forHTTPHeaderField: "KA")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("[KakaoLocalService] HTTPURLResponse 변환 실패")
            throw NetworkError.badRequest("잘못된 응답 형식")
        }

        print("[KakaoLocalService] 응답 상태 코드: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            // 응답 데이터 출력 (에러 메시지 확인용)
            if let errorString = String(data: data, encoding: .utf8) {
                print("[KakaoLocalService] 에러 응답: \(errorString)")
            }
            throw NetworkError.badRequest("주소 검색 실패 (HTTP \(httpResponse.statusCode))")
        }

        // 응답 데이터 출력 (디버깅용)
        if let responseString = String(data: data, encoding: .utf8) {
            print("[KakaoLocalService] 응답 데이터: \(responseString)")
        }

        let decoder = JSONDecoder()
        do {
            let kakaoResponse = try decoder.decode(KakaoAddressSearchResponse.self, from: data)
            print("[KakaoLocalService] 검색 결과: \(kakaoResponse.documents.count)개")

            return kakaoResponse.documents.compactMap { doc in
                guard let lat = Double(doc.y),
                      let lon = Double(doc.x) else {
                    return nil
                }

                return AddressSearchResult(
                    placeName: doc.placeName ?? "",
                    address: doc.addressName,
                    roadAddress: doc.roadAddressName,
                    latitude: lat,
                    longitude: lon
                )
            }
        } catch {
            print("[KakaoLocalService] 디코딩 에러: \(error)")
            throw NetworkError.decodingFailed(error)
        }
    }
}
