//
//  LocationManager.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/19/25.
//

import Foundation
import CoreLocation
import Combine

// MARK: - 위치 관리자

@Observable
final class LocationManager: NSObject {
    // MARK: - Properties

    private var locationManager = CLLocationManager()

    private(set) var currentLocation: CLLocationCoordinate2D?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var error: String?

    var onLocationUpdate: ((CLLocationCoordinate2D) -> Void)?

    // MARK: - Initializer

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 500 // 500m 이상 이동 시 업데이트
    }

    // MARK: - Public Methods

    /// 위치 권한 요청
    func requestAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            error = "위치 권한이 거부되었습니다. 설정에서 권한을 허용해주세요."
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        @unknown default:
            break
        }
    }

    /// 위치 업데이트 시작
    func startUpdatingLocation() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            requestAuthorization()
            return
        }

        locationManager.startUpdatingLocation()
    }

    /// 위치 업데이트 중지
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied, .restricted:
            error = "위치 권한이 거부되었습니다."
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let coordinate = location.coordinate
        currentLocation = coordinate
        onLocationUpdate?(coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = "위치를 가져오는데 실패했습니다: \(error.localizedDescription)"
    }
}
