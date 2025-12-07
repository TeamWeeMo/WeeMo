//
//  VisionService.swift
//  WeeMo
//
//  Created by Reimos on 2024/12/04.
//

import UIKit
import Vision

// MARK: - Vision Service

/// Vision Framework를 활용한 이미지 분석 서비스
final class VisionService {

    // MARK: - Singleton

    static let shared = VisionService()
    private init() {}

    // MARK: - Image Classification

    /// 이미지에서 사물/장면 인식 후 해시태그 추출
    /// - Parameters:
    ///   - image: 분석할 UIImage
    ///   - maxResults: 최대 결과 개수 (기본값: 5)
    ///   - minConfidence: 최소 신뢰도 (기본값: 0.6)
    /// - Returns: 인식된 한글 해시태그 배열
    func analyzeImageForHashTags(
        _ image: UIImage,
        maxResults: Int = 5,
        minConfidence: Float = 0.6
    ) async -> [String] {
        // 시뮬레이터 감지 - 더미 데이터 반환
        #if targetEnvironment(simulator)
        print("[VisionService] 시뮬레이터 감지")
        print("[VisionService] Vision Framework는 실기기에서만 정상 작동")
        print("[VisionService] 시뮬레이터용 더미 해시태그를 반환")

        // 시뮬레이터용 더미 해시태그 (데모용)
        let dummyTags = ["침실", "거실", "아늑한", "모던", "인테리어", "조명", "창문", "가구"]
        let randomCount = min(Int.random(in: 3...6), maxResults)
        let shuffled = dummyTags.shuffled()
        let result = Array(shuffled.prefix(randomCount))

        print("[VisionService] 더미 해시태그 반환: \(result)")
        return result
        #endif

        // 이미지를 JPEG로 변환하여 호환성 향상
        guard let imageData = image.jpegData(compressionQuality: 0.8),
              let processedImage = UIImage(data: imageData),
              let cgImage = processedImage.cgImage else {
            print("[VisionService] 이미지 변환 실패")
            return []
        }

        print("[VisionService] 이미지 크기: \(cgImage.width) x \(cgImage.height)")

        return await withCheckedContinuation { continuation in
            var isResumed = false  // 중복 resume 방지

            let request = VNClassifyImageRequest { request, error in
                guard !isResumed else { return }

                if let error = error {
                    print("[VisionService] 이미지 분석 실패: \(error.localizedDescription)")
                    isResumed = true
                    continuation.resume(returning: [])
                    return
                }

                guard let results = request.results as? [VNClassificationObservation] else {
                    print("[VisionService] 결과 변환 실패")
                    isResumed = true
                    continuation.resume(returning: [])
                    return
                }

                print("[VisionService] 전체 인식 결과 개수: \(results.count)")

                // 신뢰도 필터링 + 상위 N개 선택
                let filteredResults = results.filter { $0.confidence >= minConfidence }
                print("[VisionService] 신뢰도 \(minConfidence) 이상 결과: \(filteredResults.count)개")

                let tags = filteredResults
                    .prefix(maxResults)
                    .compactMap { observation -> String? in
                        let identifier = observation.identifier
                        let confidence = observation.confidence

                        print("[VisionService] 인식: \(identifier) (신뢰도: \(String(format: "%.2f", confidence)))")

                        // 영어 → 한글 변환
                        return self.translateToKorean(identifier)
                    }

                print("[VisionService] 번역된 해시태그: \(tags)")
                print("[VisionService] 최종 해시태그 개수: \(tags.count)")

                isResumed = true
                continuation.resume(returning: Array(tags))
            }

            // 옵션 추가: 이미지 방향 고려
            let options: [VNImageOption: Any] = [:]
            let handler = VNImageRequestHandler(cgImage: cgImage, options: options)

            do {
                print("[VisionService] Vision 분석 시작...")
                try handler.perform([request])
            } catch {
                if !isResumed {
                    print("[VisionService] 분석 실행 실패: \(error.localizedDescription)")
                    isResumed = true
                    continuation.resume(returning: [])
                }
            }
        }
    }

    // MARK: - Translation Dictionary

    /// 영어 → 한글 해시태그 변환
    /// - Parameter identifier: Vision Framework가 인식한 영어 단어
    /// - Returns: 한글 해시태그 (없으면 nil)
    private func translateToKorean(_ identifier: String) -> String? {
        // 소문자로 변환
        let lowercased = identifier.lowercased()

        // 영어 → 한글 사전
        let dictionary: [String: String] = [
            // 자연/풍경
            "ocean": "바다",
            "sea": "바다",
            "beach": "해변",
            "water": "물",
            "mountain": "산",
            "tree": "나무",
            "forest": "숲",
            "sky": "하늘",
            "sunset": "일몰",
            "sunrise": "일출",
            "lake": "호수",
            "river": "강",
            "park": "공원",
            "garden": "정원",
            "nature": "자연",
            "landscape": "풍경",
            "scenery": "경치",
            
            // 실내/가구
            "bedroom": "침실",
            "bed": "침대",
            "kitchen": "주방",
            "living room": "거실",
            "table": "테이블",
            "chair": "의자",
            "desk": "책상",
            "sofa": "소파",
            "window": "창문",
            "door": "문",
            "furniture": "가구",
            "interior": "인테리어",
            
            // 파티/행사
            "balloon": "풍선",
            "party": "파티",
            "cake": "케이크",
            "celebration": "축하",
            "birthday": "생일",
            "decoration": "장식",
            "gift": "선물",
            
            // 스튜디오/작업공간
            "studio": "스튜디오",
            "office": "사무실",
            "workspace": "작업공간",
            "computer": "컴퓨터",
            "laptop": "노트북",
            "monitor": "모니터",
            "keyboard": "키보드",
            "screen": "화면",
            
            // 카페/음식
            "cafe": "카페",
            "coffee": "커피",
            "tea": "차",
            "restaurant": "식당",
            "food": "음식",
            "dining": "식사",
            "cup": "컵",
            "mug": "머그컵",
            
            // 조명/분위기
            "light": "조명",
            "lamp": "램프",
            "lighting": "밝기",
            "candle": "양초",
            "bright": "밝은",
            "dark": "어두운",
            
            // 식물/꽃
            "plant": "식물",
            "flower": "꽃",
            "bouquet": "꽃다발",
            "vase": "화병",
            
            // 스타일/형용사
            "modern": "모던",
            "contemporary": "현대적",
            "minimalist": "미니멀",
            "cozy": "아늑한",
            "spacious": "넓은",
            "luxury": "럭셔리",
            "elegant": "우아한",
            "vintage": "빈티지",
            "rustic": "소박한",
            "clean": "깔끔한",
            
            // 도시/건물
            "building": "건물",
            "architecture": "건축",
            "city": "도시",
            "urban": "도심",
            "downtown": "시내",
            
            // 기타
            "book": "책",
            "shelf": "선반",
            "bookshelf": "책장",
            "mirror": "거울",
            "picture": "그림",
            "painting": "회화",
            "art": "예술",
            "photo": "사진",
            "frame": "액자",
            "curtain": "커튼",
            "pillow": "베개",
            "cushion": "쿠션",
            "blanket": "담요"
        ]

        return dictionary[lowercased]
    }
}
