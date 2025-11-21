//
//  SpaceSearchView.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI

struct SpaceListView: View {
    // MARK: - MVI Store

    @StateObject private var store = SpaceListStore()

    // MARK: - Navigation State

    @State private var isShowingCreateView = false

    var body: some View {
        ZStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Spacing.base) {
                        // 상단 타이틀
                        HStack {
                            Text("공간 찾기")
                                .font(.app(.headline1))
                                .foregroundColor(Color("textMain"))

                            Spacer()
                        }
                        .padding(.horizontal, Spacing.base)
                        .padding(.top, Spacing.small)

                        // 검색바
                        SearchBarView(
                            searchText: Binding(
                                get: { store.state.searchText },
                                set: { store.send(.searchTextChanged($0)) }
                            )
                        )
                        .padding(.horizontal, Spacing.base)

                        // 카테고리 탭
                        CategoryTabView(
                            selectedCategory: Binding(
                                get: { store.state.selectedCategory },
                                set: { store.send(.categoryChanged($0)) }
                            )
                        )
                        .padding(.top, Spacing.xSmall)

                        // 인기 공간 섹션
                        if store.state.shouldShowPopularSection {
                            PopularSpaceSectionView(spaces: store.state.popularSpaces)
                                .padding(.top, Spacing.small)
                        }

                        // 모든 공간 리스트
                        AllSpaceListView(spaces: store.state.filteredSpaces)
                            .padding(.top, store.state.searchText.isEmpty ? Spacing.base : Spacing.small)
                    }
                    .padding(.bottom, Spacing.base)
                }

                // 로딩 인디케이터
                if store.state.isLoading {
                    ProgressView("공간 목록을 불러오는 중...")
                        .padding()
                        .background(Color("wmBg").opacity(0.9))
                        .cornerRadius(Spacing.radiusMedium)
                }

                // 공간 등록 Floating 버튼
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        CreateSpaceButton {
                            isShowingCreateView = true
                        }
                        .padding(.trailing, Spacing.base)
                        .padding(.bottom, Spacing.base)
                    }
                }
            }
            .background(Color("wmBg"))
            .navigationBarHidden(true)
            .navigationDestination(for: Space.self) { space in
                SpaceDetailView(space: space)
            }
            .alert("오류", isPresented: Binding(
                get: { store.state.errorMessage != nil },
                set: { if !$0 { store.send(.refresh) } }
            )) {
                Button("확인", role: .cancel) { }
            } message: {
                if let errorMessage = store.state.errorMessage {
                    Text(errorMessage)
                }
            }
            .onAppear {
                // 화면 진입 시 데이터 로드
                store.send(.viewAppeared)
            }
            .fullScreenCover(isPresented: $isShowingCreateView) {
                NavigationStack {
                    SpaceCreateView()
                }
            }
            .onChange(of: isShowingCreateView) { oldValue, newValue in
                // 공간 등록 화면에서 돌아왔을 때 목록 새로고침
                if !newValue {
                    store.send(.refresh)
                }
            }
        .navigationBarHidden(false)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SpaceListView()
}
