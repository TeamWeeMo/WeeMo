//
//  MeetMapStore.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/19/25.
//

import Foundation
import Combine
import CoreLocation

// MARK: - MeetMap Store

@Observable
final class MeetMapStore {
    // MARK: - Properties

    private(set) var state = MeetMapState()

    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // LocationManager
    let locationManager = LocationManager()

    // Combine 기반 디바운싱용 Subject
    private let mapRegionSubject = PassthroughSubject<(center: CLLocationCoordinate2D, zoom: Double), Never>()
    private let searchSubject = PassthroughSubject<String, Never>()

    // MARK: - Initializer

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
        setupMapRegionDebouncing()
        setupSearchDebouncing()
        setupLocationManager()
    }

    // MARK: - Location Setup

    private func setupLocationManager() {
        locationManager.onLocationUpdate = { [weak self] coordinate in
            self?.send(.updateUserLocation(coordinate))
        }
    }

    // MARK: - Setup

    /// 검색 디바운싱 설정 (Combine)
    private func setupSearchDebouncing() {
        searchSubject
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                self.state.lastSearchedQuery = query

                Task {
                    await self.searchMeetsByTitle(query: query)
                }
            }
            .store(in: &cancellables)
    }

    /// 지도 영역 변경 디바운싱 설정 (Combine)
    private func setupMapRegionDebouncing() {
        mapRegionSubject
            .debounce(for: .seconds(0.8), scheduler: DispatchQueue.main) // 0.8초 디바운스
            .removeDuplicates { prev, current in
                // 이전 위치와 현재 위치 비교 (거의 같으면 중복으로 간주)
                abs(prev.center.latitude - current.center.latitude) < 0.0001 &&
                abs(prev.center.longitude - current.center.longitude) < 0.0001 &&
                abs(prev.zoom - current.zoom) < 0.1
            }
            .sink { [weak self] (center, zoom) in
                guard let self = self else { return }

                // 최소 이동 거리 체크
                if self.shouldCallAPI(newCenter: center, newZoom: zoom) {
                    Task {
                        await self.loadMeetsByLocation(center: center, zoom: zoom)
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Intent Handler

    func send(_ intent: MeetMapIntent) {
        switch intent {
        case .onAppear:
            handleOnAppear()

        case .openSearch:
            state.showingSearch = true

        case .closeSearch:
            state.showingSearch = false
            state.searchText = ""
            state.filteredMeets = []
            state.hasSearched = false
            state.lastSearchedQuery = ""

        case .selectMeet(let meet):
            state.selectedMeet = meet

        case .selectMeetFromSearch(let meet):
            // 검색 시트 닫기
            state.showingSearch = false
            state.searchText = ""
            state.filteredMeets = []
            state.hasSearched = false
            state.lastSearchedQuery = ""
            // 시트 닫힘 애니메이션 후 네비게이션
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3초
                state.selectedMeet = meet
            }

        case .clearSelectedMeet:
            state.selectedMeet = nil

        case .moveToCurrentLocation:
            if let userLocation = state.userLocation {
                state.cameraPosition = userLocation
                // 현재 위치로 이동 시 해당 위치의 모임도 로드
                Task {
                    await loadMeetsByLocation(center: userLocation, zoom: state.currentZoom)
                }
            }

        case .moveToLocation(let latitude, let longitude):
            let newLocation = CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude
            )
            state.cameraPosition = newLocation
            // 특정 위치로 이동 시 해당 위치의 모임도 로드
            Task {
                await loadMeetsByLocation(center: newLocation, zoom: state.currentZoom)
            }

        case .updateSearchText(let text):
            state.searchText = text
            // 검색어 변경 시 hasSearched 초기화
            if text.isEmpty {
                state.hasSearched = false
            }

        case .searchMeets(let query):
            handleSearch(query)

        case .clearSearch:
            state.searchText = ""
            state.hasSearched = false
            state.filteredMeets = []
            state.lastSearchedQuery = ""

        case .dismissSearchAlert:
            state.showSearchAlert = false
            state.searchAlertMessage = ""

        case .updateUserLocation(let location):
            let isFirstLocation = state.userLocation == nil
            state.userLocation = location

            // 처음 위치를 받았을 때 자동으로 이동
            if isFirstLocation {
                state.cameraPosition = location
                Task {
                    await loadMeetsByLocation(center: location, zoom: state.currentZoom)
                }
            }

        case .mapRegionChanged(let center, let zoom):
            // 카메라 위치와 줌 업데이트
            state.cameraPosition = center
            state.currentZoom = zoom

            // Subject에 이벤트 전송 (Combine이 디바운싱 처리)
            mapRegionSubject.send((center: center, zoom: zoom))

        case .updateVisibleBounds(let minLat, let maxLat, let minLng, let maxLng):
            // 지도 가시 영역 업데이트 (하단 리스트 필터링용)
            state.mapVisibleBounds = (minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng)
        }
    }

    // MARK: - Public Methods

    /// 새로고침 (현재 지도 위치 기준으로 재로드)
    @MainActor
    func refresh() async {
        await loadMeetsByLocation(center: state.cameraPosition, zoom: state.currentZoom)
    }

    // MARK: - Private Methods

    private func handleOnAppear() {
        // 초기 위치로 모임 로드
        Task {
            await loadMeetsByLocation(center: state.cameraPosition, zoom: state.currentZoom)
        }
    }

    /// 위치 기반 모임 로드 (searchByLocation API 사용)
    private func loadMeetsByLocation(center: CLLocationCoordinate2D, zoom: Double) async {
        // 줌 레벨에 따라 검색 반경 계산 (km)
        // 줌이 높을수록(가까울수록) 작은 반경
        let maxDistance = calculateSearchRadius(zoom: zoom)

        do {
            let response = try await networkService.request(
                PostRouter.searchByLocation(
                    category: .meet,
                    longitude: center.longitude,
                    latitude: center.latitude,
                    maxDistance: maxDistance,
                    orderBy: "distance",
                    sortBy: "asc"
                ),
                responseType: PostListDTO.self
            )

            // DTO → Domain 변환
            let meets = response.data.map { $0.toMeet() }

            await MainActor.run {
                state.visibleMeets = meets
                state.meets = meets // 전체 목록도 업데이트 (검색용)
                state.lastAPICallLocation = center // 마지막 API 호출 위치 저장
            }

        } catch {
            await MainActor.run {
                state.errorMessage = (error as? NetworkError)?.localizedDescription ?? "모임을 불러오는데 실패했습니다."
            }
        }
    }

    /// API 호출 여부 판단 (최소 이동 거리 체크)
    private func shouldCallAPI(newCenter: CLLocationCoordinate2D, newZoom: Double) -> Bool {
        guard let lastLocation = state.lastAPICallLocation else {
            return true // 첫 호출은 무조건 실행
        }

        // 두 좌표 간 거리 계산 (미터 단위)
        let distance = calculateDistance(
            from: lastLocation,
            to: newCenter
        )

        // 줌 레벨에 따른 최소 이동 거리 (검색 반경의 30%)
        let searchRadius = Double(calculateSearchRadius(zoom: newZoom))
        let minDistance = searchRadius * 0.3

        // 최소 거리 이상 이동했으면 API 호출
        return distance >= minDistance
    }

    /// 두 좌표 간 거리 계산 (Haversine formula, 단위: 미터)
    private func calculateDistance(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        let earthRadius = 6371000.0 // 지구 반지름 (미터)

        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let deltaLat = (to.latitude - from.latitude) * .pi / 180
        let deltaLng = (to.longitude - from.longitude) * .pi / 180

        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1) * cos(lat2) *
                sin(deltaLng / 2) * sin(deltaLng / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }

    /// 줌 레벨에 따른 검색 반경 계산 (미터 단위)
    private func calculateSearchRadius(zoom: Double) -> Int {
        // 네이버 지도 줌 레벨: 0 (가장 멀리) ~ 21 (가장 가까이)
        // 줌이 높을수록 좁은 범위
        switch zoom {
        case 17...21: return 500    // 500m
        case 15..<17: return 1000   // 1km
        case 13..<15: return 3000   // 3km
        case 11..<13: return 5000   // 5km
        case 9..<11:  return 10000  // 10km
        default:      return 20000  // 20km
        }
    }

    /// 검색 처리 (Combine 디바운싱 사용)
    private func handleSearch(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        state.searchText = trimmedQuery

        // 빈 검색어 처리
        if trimmedQuery.isEmpty {
            state.filteredMeets = []
            state.hasSearched = false
            state.isLoading = false
            return
        }

        // 2글자 미만이면 Alert 표시
        if trimmedQuery.count < 2 {
            state.searchAlertMessage = "2글자 이상 입력해주세요"
            state.showSearchAlert = true
            return
        }

        // 동일한 검색어 중복 방지
        if trimmedQuery == state.lastSearchedQuery {
            return
        }

        state.hasSearched = true
        state.isLoading = true

        // Combine Subject로 전송 (디바운싱 적용)
        searchSubject.send(trimmedQuery)
    }

    /// 제목으로 모임 검색 (API)
    @MainActor
    private func searchMeetsByTitle(query: String) async {
        state.errorMessage = nil

        do {
            let response = try await networkService.request(
                PostRouter.searchByTitle(title: query, category: .meet),
                responseType: PostListDTO.self
            )

            // DTO → Entity 변환 (PostMapper 사용)
            let meets = response.data.map { $0.toMeet() }

            state.filteredMeets = meets
            state.isLoading = false
        } catch {
            state.errorMessage = (error as? NetworkError)?.localizedDescription ?? "검색 중 오류가 발생했습니다."
            state.filteredMeets = []
            state.isLoading = false
        }
    }
}
