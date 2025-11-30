//
//  MapCameraHelper.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/19/25.
//

import Foundation
import CoreLocation
import NMapsMap

// MARK: - 지도 카메라 관련 헬퍼

struct MapCameraHelper {
    /// 카메라를 특정 위치로 이동
    static func moveCamera(
        to coordinate: CLLocationCoordinate2D,
        mapView: NMFMapView,
        animated: Bool = true
    ) {
        let cameraUpdate = NMFCameraUpdate(
            scrollTo: NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
        )
        cameraUpdate.animation = animated ? .easeIn : .none
        mapView.moveCamera(cameraUpdate)
    }

    /// 여러 지점을 모두 보여주도록 카메라 조정
    static func fitBounds(
        coordinates: [CLLocationCoordinate2D],
        mapView: NMFMapView,
        paddingInsets: UIEdgeInsets = UIEdgeInsets(top: 100, left: 50, bottom: 100, right: 50)
    ) {
        guard !coordinates.isEmpty else { return }

        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLng = coordinates[0].longitude
        var maxLng = coordinates[0].longitude

        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLng = min(minLng, coordinate.longitude)
            maxLng = max(maxLng, coordinate.longitude)
        }

        let southWest = NMGLatLng(lat: minLat, lng: minLng)
        let northEast = NMGLatLng(lat: maxLat, lng: maxLng)
        let bounds = NMGLatLngBounds(southWest: southWest, northEast: northEast)

        let cameraUpdate = NMFCameraUpdate(fit: bounds, paddingInsets: paddingInsets)
        cameraUpdate.animation = .easeIn
        mapView.moveCamera(cameraUpdate)
    }

    /// 기본 서울 위치
    static let defaultSeoulLocation = CLLocationCoordinate2D(
        latitude: 37.5665,
        longitude: 126.9780
    )
}
