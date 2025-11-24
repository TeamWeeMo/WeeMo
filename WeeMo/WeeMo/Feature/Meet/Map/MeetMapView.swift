//
//  MeetMapView.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//  Refactored by Watson22_YJ on 11/19/25.
//

import SwiftUI
import CoreLocation

// MARK: - MeetMapView (Naver Map)

struct MeetMapView: View {
    // MARK: - Properties

    @State private var store: MeetMapStore

    // MARK: - Initializer

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.store = MeetMapStore(networkService: networkService)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 네이버 지도
            NaverMapView(
                cameraPosition: Binding(
                    get: { store.state.cameraPosition },
                    set: { _ in }
                ),
                meets: store.state.visibleMeets,
                onRegionChange: { center, zoom in
                    store.send(.mapRegionChanged(center: center, zoom: zoom))
                },
                onVisibleBoundsChange: { minLat, maxLat, minLng, maxLng in
                    store.send(.updateVisibleBounds(minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng))
                }
            )
            .ignoresSafeArea()

            // 상단 검색바
            VStack {
                SearchBarButton(placeholder: "모임을 검색하세요") {
                    store.send(.openSearch)
                }
                    .padding(.horizontal, Spacing.base)
                    .padding(.top, Spacing.small)
                Spacer()
            }

            // 하단 영역 (현재위치 버튼 + 모임 리스트)
            VStack(spacing: 0) {
                Spacer()

                // 오른쪽 하단 현재위치 버튼
                HStack {
                    Spacer()
                    FloatingButton(icon: "location.fill") {
                        store.send(.moveToCurrentLocation)
                    }
                    .animation(.easeInOut(duration: 0.3), value: store.state.meetsInCurrentView.isEmpty)
                        .padding(.trailing, Spacing.base)
                        .padding(.bottom, store.state.meetsInCurrentView.isEmpty ? 0 : Spacing.small)
                }
                // 하단 카드 오버레이
                if !store.state.meetsInCurrentView.isEmpty {
                    bottomCardOverlay
                } else {
                    // 리스트가 없을 때는 버튼을 하단에 고정하기 위한 스페이서
                    Color.clear
                        .frame(height: 16)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.state.meetsInCurrentView.isEmpty)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .sheet(isPresented: Binding(
            get: { store.state.showingSearch },
            set: { newValue in
                if !newValue {
                    store.send(.closeSearch)
                }
            }
        )) {
            searchSheet
                .presentationDetents([.medium, .large]) // 절반 또는 전체 높이
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(false)
        }
        .navigationDestination(item: Binding(
            get: { store.state.selectedMeet },
            set: { newValue in
                if newValue == nil {
                    store.send(.clearSelectedMeet)
                }
            }
        )) { meet in
            MeetDetailView(postId: meet.postId)
        }
        .onAppear {
            store.send(.onAppear)
            store.locationManager.requestAuthorization()
        }
    }

    // MARK: - Subviews

    /// 하단 카드 오버레이 (현재 화면에 보이는 모임만 표시)
    private var bottomCardOverlay: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.medium) {
                ForEach(store.state.meetsInCurrentView) { meet in
                    MeetMapCardView(meet: meet)
                        .buttonWrapper {
                            store.send(.selectMeet(meet))
                        }
                }
            }
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.medium)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    /// 검색 시트
    private var searchSheet: some View {
        NavigationStack {
            VStack {
                // 검색바 + 검색 버튼
                HStack(spacing: Spacing.small) {
                    // 검색바
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.textSub)
                            .padding(.leading, Spacing.medium)

                        TextField("모임을 검색하세요", text: Binding(
                            get: { store.state.searchText },
                            set: { newValue in
                                store.send(.updateSearchText(newValue))
                            }
                        ))
                        .font(.app(.content2))
                        .padding(.vertical, Spacing.medium)
                        .submitLabel(.search)

                        if !store.state.searchText.isEmpty {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .buttonWrapper {
                                    store.send(.clearSearch)
                                }
                                .padding(.trailing, Spacing.small)
                        }
                    }
                    .background(.wmGray)
                    .cornerRadius(Spacing.radiusMedium)

                    // 검색 버튼
                    Text("검색")
                        .buttonWrapper {
                            store.send(.searchMeets(query: store.state.searchText))
                        }
                        .font(.app(.content1))
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.base)
                        .padding(.vertical, Spacing.medium)
                        .background(.wmMain)
                        .cornerRadius(Spacing.radiusMedium)
                }
                .padding(.horizontal, Spacing.base)
                .padding(.top, Spacing.base)

                // 검색 결과
                if store.state.isLoading {
                    LoadingView(message: "검색 중...")
                } else if store.state.isSearchEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "검색 결과가 없습니다",
                        message: "다른 키워드로 검색해보세요"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.base) {
                            ForEach(store.state.filteredMeets) { meet in
                                MeetListItemView(meet: meet)
                                    .buttonWrapper {
                                        store.send(.selectMeetFromSearch(meet))
                                    }
                            }
                        }
                        .padding(.horizontal, Spacing.base)
                        .padding(.top, Spacing.base)
                    }
                }
            }
            .navigationTitle("모임 검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        store.send(.closeSearch)
                    }
                    .font(.app(.content1))
                    .foregroundColor(.textMain)
                }
            }
            .background(.wmBg)
            .alert("알림", isPresented: Binding(
                get: { store.state.showSearchAlert },
                set: { newValue in
                    if !newValue {
                        store.send(.dismissSearchAlert)
                    }
                }
            )) {
                Button("확인", role: .cancel) {
                    store.send(.dismissSearchAlert)
                }
            } message: {
                Text(store.state.searchAlertMessage)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MeetMapView()
    }
}
