//
//  MeetListView.swift
//  WeeMo
//
//  Created by 차지용 on 11/7/25.
//

import SwiftUI

struct MeetListView: View {
    @State private var searchText = ""
    @State private var selectedSortOption: SortOption = .registrationDate
    @State private var showingSortOptions = false
    @State private var store = MeetListStore()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack {
                    SearchBar(text: $searchText)

                    FilterButton(
                        selectedOption: $selectedSortOption,
                        showingOptions: $showingSortOptions
                    )

                    if store.state.isLoading {
                        LoadingView(message: "모임을 불러오는 중...")
                    } else if let errorMessage = store.state.errorMessage {
                        EmptyStateView(
                            icon: "exclamationmark.triangle",
                            title: "오류가 발생했습니다",
                            message: errorMessage,
                            actionTitle: "다시 시도"
                        ) {
                            store.send(.retryLoadMeets)
                        }
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(store.state.meets.enumerated()), id: \.element.id) { index, meet in
                                NavigationLink(value: meet.id) {
                                    MeetCardView(meet: meet)
                                }
                                .onAppear {
                                    // 마지막에서 3번째 아이템이 나타날 때 더 로드
                                    if index >= store.state.meets.count - 3 && store.state.hasMoreData && !store.state.isLoadingMore {
                                        store.send(.loadMoreMeets)
                                    }
                                }
                            }

                            // 로딩 인디케이터 (더 불러올 데이터가 있을 때만)
                            if store.state.isLoadingMore && store.state.hasMoreData {
                                HStack {
                                    Spacer()
                                    ProgressView("더 불러오는 중...")
                                        .padding()
                                    Spacer()
                                }
                            }
                        }
                        .padding(.top, Spacing.base)
                    }
                }
                .background(.wmBg)
                .onAppear {
                    if store.state.meets.isEmpty {
                        store.send(.loadMeets)
                    }
                }
                .onChange(of: selectedSortOption) { _, sortOption in
                    store.send(.sortMeets(option: sortOption))
                }
                .onChange(of: searchText) { _, searchQuery in
                    store.send(.searchMeets(query: searchQuery))
                }
            }

            // Floating Buttons
            VStack(spacing: Spacing.medium) {
                NavigationLink(value: HomeRoute.meetMap) {
                    Image(systemName: "map")
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                        .frame(width: 56, height: 56)
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }

                NavigationLink(value: HomeRoute.meetEdit) {
                    Image(systemName: "plus")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(.wmMain)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .toolbarRole(.editor)
        .tint(.wmMain)
    }
}

#Preview {
    MeetListView()
}
