//
//  MarkerImageGenerator.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/19/25.
//

import SwiftUI

// MARK: - 마커 이미지 생성 헬퍼 (SwiftUI → UIImage)

struct MarkerImageGenerator {
    /// SwiftUI View를 UIImage로 변환
    @MainActor
    static func render<Content: View>(view: Content, size: CGSize) -> UIImage {
        let controller = UIHostingController(rootView: view)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

    /// 모임 마커 이미지 생성 (SwiftUI View → UIImage)
    static func generateMarkerImage(
        meet: Meet,
        count: Int,
        completion: @escaping (UIImage?) -> Void
    ) {
        Task { @MainActor in
            let markerView = MarkerView(meet: meet, count: count)
            // padding(5)를 고려한 실제 크기: 70 + 10 = 80
            let image = render(view: markerView, size: CGSize(width: 120, height: 120))
            completion(image)
        }
    }
}

// MARK: - 위치 그룹화 헬퍼

extension Array where Element == Meet {
    /// 줌 레벨에 따라 모임들을 클러스터링 (동적 그룹화)
    func clusterByZoomLevel(zoom: Double) -> [String: [Meet]] {
        // 줌 레벨에 따라 클러스터링 정밀도 결정
        // 줌이 높을수록(가까울수록) 정밀하게, 낮을수록(멀수록) 넓게 그룹화
        let precision: Int
        switch zoom {
        case 17...21: precision = 4  // 매우 가까움 - 거의 같은 위치만 클러스터링
        case 15..<17: precision = 3  // 가까움 - 약 100m 반경
        case 13..<15: precision = 2  // 중간 - 약 1km 반경
        case 11..<13: precision = 1  // 멀리 - 약 10km 반경
        default:      precision = 0  // 매우 멀리 - 약 100km 반경
        }

        return Dictionary(grouping: self) { meet in
            let latKey = String(format: "%.\(precision)f", meet.latitude)
            let lngKey = String(format: "%.\(precision)f", meet.longitude)
            return "\(latKey),\(lngKey)"
        }
    }

    /// 같은 위치의 모임들을 그룹화 (소수점 4자리까지 비교) - 기존 메서드 유지
    func groupByLocation() -> [String: [Meet]] {
        return clusterByZoomLevel(zoom: 17) // 기본값으로 가장 정밀한 클러스터링 사용
    }
}
