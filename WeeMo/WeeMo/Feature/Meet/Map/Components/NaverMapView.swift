//
//  NaverMapView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/19/25.
//

import SwiftUI
import NMapsMap

// MARK: - 네이버 지도 SwiftUI Wrapper

struct NaverMapView: UIViewRepresentable {
    @Binding var cameraPosition: CLLocationCoordinate2D
    let meets: [Meet]
//    let onMarkerTap: (Meet) -> Void
    let onRegionChange: (CLLocationCoordinate2D, Double) -> Void // center, zoom
    let onVisibleBoundsChange: (Double, Double, Double, Double) -> Void // minLat, maxLat, minLng, maxLng

    func makeUIView(context: Context) -> NMFNaverMapView {
        let mapView = NMFNaverMapView()

        // 지도 기본 설정
        mapView.showZoomControls = false
        mapView.showCompass = true
        mapView.showScaleBar = true
        mapView.showLocationButton = false

        // Coordinator 설정
        context.coordinator.mapView = mapView
//        context.coordinator.onMarkerTap = onMarkerTap
        context.coordinator.onRegionChange = onRegionChange
        context.coordinator.onVisibleBoundsChange = onVisibleBoundsChange

        // Delegate 설정
        mapView.mapView.addCameraDelegate(delegate: context.coordinator)

        // 초기 카메라 위치 설정
        let cameraUpdate = NMFCameraUpdate(
            scrollTo: NMGLatLng(
                lat: cameraPosition.latitude,
                lng: cameraPosition.longitude
            )
        )
        cameraUpdate.animation = .none
        mapView.mapView.moveCamera(cameraUpdate)

        return mapView
    }

    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
        // 카메라 위치가 변경되었는지 확인 (프로그래밍 방식 이동)
        let currentPosition = uiView.mapView.cameraPosition
        let currentCenter = CLLocationCoordinate2D(
            latitude: currentPosition.target.lat,
            longitude: currentPosition.target.lng
        )

        // 좌표 차이가 0.0001도 이상이면 카메라 이동 (약 10m)
        let latDiff = abs(currentCenter.latitude - cameraPosition.latitude)
        let lngDiff = abs(currentCenter.longitude - cameraPosition.longitude)

        if latDiff > 0.0001 || lngDiff > 0.0001 {
            let cameraUpdate = NMFCameraUpdate(
                scrollTo: NMGLatLng(
                    lat: cameraPosition.latitude,
                    lng: cameraPosition.longitude
                )
            )
            cameraUpdate.animation = .easeIn
            uiView.mapView.moveCamera(cameraUpdate)
        }

        // 마커 업데이트
        context.coordinator.updateMarkers(meets: meets, mapView: uiView.mapView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NMFMapViewCameraDelegate {
        var mapView: NMFNaverMapView?
        var markers: [String: NMFMarker] = [:] // locationKey -> Marker
        var onMarkerTap: ((Meet) -> Void)?
        var onRegionChange: ((CLLocationCoordinate2D, Double) -> Void)?
        var onVisibleBoundsChange: ((Double, Double, Double, Double) -> Void)?
        var currentZoom: Double = 13.0 // 현재 줌 레벨 추적

        func updateMarkers(meets: [Meet], mapView: NMFMapView) {
            // 현재 줌 레벨 가져오기
            let zoom = mapView.cameraPosition.zoom
            currentZoom = zoom

            // 줌 레벨에 따라 동적으로 클러스터링
            let groupedMeets = meets.clusterByZoomLevel(zoom: zoom)

            // 기존 마커 제거 (현재 그룹에 없는 것들)
            let currentLocationKeys = Set(groupedMeets.keys)
            let existingLocationKeys = Set(markers.keys)

            for locationKey in existingLocationKeys.subtracting(currentLocationKeys) {
                markers[locationKey]?.mapView = nil
                markers.removeValue(forKey: locationKey)
            }

            // 새로운 마커 추가 또는 업데이트
            for (locationKey, meetsAtLocation) in groupedMeets {
                guard let firstMeet = meetsAtLocation.first else { continue }

                // 클러스터의 중심 좌표 계산 (모든 모임의 평균 위치)
                let centerLat = meetsAtLocation.map { $0.latitude }.reduce(0, +) / Double(meetsAtLocation.count)
                let centerLng = meetsAtLocation.map { $0.longitude }.reduce(0, +) / Double(meetsAtLocation.count)

                // 기존 마커가 있는지 확인
                if let existingMarker = markers[locationKey] {
                    // 마커가 이미 있으면 개수만 업데이트
                    let currentCount = (existingMarker.userInfo["meets"] as? [Meet])?.count ?? 0
                    if currentCount != meetsAtLocation.count {
                        // 개수가 변경되었으면 마커 이미지 재생성
                        existingMarker.userInfo = [
                            "locationKey": locationKey,
                            "meets": meetsAtLocation,
                            "firstMeet": firstMeet
                        ]

                        MarkerImageGenerator.generateMarkerImage(
                            meet: firstMeet,
                            count: meetsAtLocation.count
                        ) { [weak existingMarker] image in
                            guard let marker = existingMarker, let image = image else { return }
                            DispatchQueue.main.async {
                                marker.iconImage = NMFOverlayImage(image: image)
                            }
                        }
                    }
                } else {
                    // 새 마커 생성
                    let marker = NMFMarker()
                    marker.position = NMGLatLng(lat: centerLat, lng: centerLng)

                    // 마커 정보 저장
                    marker.userInfo = [
                        "locationKey": locationKey,
                        "meets": meetsAtLocation,
                        "firstMeet": firstMeet
                    ]

                    // 커스텀 마커 이미지 생성
                    MarkerImageGenerator.generateMarkerImage(
                        meet: firstMeet,
                        count: meetsAtLocation.count
                    ) { [weak marker] image in
                        guard let marker = marker, let image = image else { return }
                        DispatchQueue.main.async {
                            marker.iconImage = NMFOverlayImage(image: image)
                            marker.width = 120
                            marker.height = 120
                            // anchor: 삼각형 끝을 좌표에 맞추도록
                            marker.anchor = CGPoint(x: 0.5, y: 0.71)
                        }
                    }

//                    // 마커 탭 핸들러 (아무 동작 없음)
//                    marker.touchHandler = { (overlay) -> Bool in
//                        // 마커 탭 시 아무 동작 없음
//                        return true
//                    }

                    marker.mapView = mapView
                    markers[locationKey] = marker
                }
            }
        }

        // MARK: - NMFMapViewCameraDelegate

        func mapView(_ mapView: NMFMapView, cameraDidChangeByReason reason: Int, animated: Bool) {
            // 지도 이동이 완료되면 중심 좌표와 줌 레벨 전달
            let position = mapView.cameraPosition
            let center = CLLocationCoordinate2D(
                latitude: position.target.lat,
                longitude: position.target.lng
            )
            let zoom = position.zoom

            onRegionChange?(center, zoom)

            // 현재 보이는 지도 영역 계산
            let bounds = mapView.contentBounds
            let minLat = bounds.southWest.lat
            let maxLat = bounds.northEast.lat
            let minLng = bounds.southWest.lng
            let maxLng = bounds.northEast.lng

            onVisibleBoundsChange?(minLat, maxLat, minLng, maxLng)
        }
    }
}
