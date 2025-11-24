//
//  FeedView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/8/25.
//

import SwiftUI

// MARK: - Feed 메인 화면 (Pinterest Style)

struct FeedView: View {
    // MARK: - Properties

    // Store (MVI)
    @State private var store: FeedStore

    // MARK: - Initializer

    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        // TODO: 임시 accessToken 토큰 입력
        temporaryToken: String = ""
    ) {
        self.store = FeedStore(
            networkService: networkService,
            temporaryToken: temporaryToken
        )
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
                if store.state.isLoading {
                    // 로딩 중
                    LoadingView(message: "피드를 불러오는 중...")
                } else if store.state.isEmpty {
                    // 빈 상태
                    EmptyStateView(
                        icon: "photo.on.rectangle.angled",
                        title: "아직 피드가 없습니다",
                        message: "첫 피드를 작성해보세요!",
                        actionTitle: "피드 작성하기"
                    ) {
                        store.send(.createNewFeed)
                    }
                } else {
                    // 피드 목록
                    feedListView
                }
            }
            .background(.wmBg)
            .navigationTitle("피드")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "plus")
                        .font(.app(.subHeadline2))
                        .foregroundStyle(.textMain)
                        .buttonWrapper {
                            store.send(.createNewFeed)
                        }
                }
            }
            .refreshable {
                // MVI: Store의 async 메서드 직접 호출 (Intent 불필요)
                await store.refresh()
            }
            .navigationDestination(item: Binding(
                get: { store.state.selectedFeed },
                set: { newValue in
                    if newValue == nil {
                        store.send(.deselectFeed)
                    }
                }
            )) { feed in
                FeedDetailView(item: feed)
            }
            .navigationDestination(isPresented: Binding(
                get: { store.state.isShowingEditView },
                set: { newValue in
                    if !newValue {
                        store.send(.dismissEditView)
                    }
                }
            )) {
                FeedEditView(mode: .create)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                store.send(.onAppear)
            }
    }

    // MARK: - Subviews

    /// 피드 목록 뷰
    private var feedListView: some View {
        VStack(spacing: 0) {
            PinterestLayout(
                numberOfColumns: 2,
                spacing: Spacing.medium
            ) {
                ForEach(store.state.feeds) { feed in
                    FeedCardView(item: feed)
                        .tappableCard {
                            store.send(.selectFeed(feed))
                        }
                        .onAppear {
                            // 무한 스크롤: 마지막 3개 아이템 중 하나가 나타나면 더 로드
                            if shouldLoadMore(for: feed) {
                                store.send(.loadMore)
                            }
                        }
                }
            }
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.small)

            // 더 로드 중 표시
            if store.state.isLoadingMore {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.wmMain)
                    .padding(.vertical, Spacing.base)
            }
        }
    }

    // MARK: - Helper Methods

    /// 무한 스크롤 트리거 판단
    private func shouldLoadMore(for feed: Feed) -> Bool {
        guard let lastIndex = store.state.feeds.lastIndex(where: { $0.id == feed.id }),
              store.state.hasMore,
              !store.state.isLoadingMore else {
            return false
        }

        // 마지막 3개 아이템 중 하나
        return lastIndex >= store.state.feeds.count - 3
    }
}

// MARK: - Preview

#Preview {
    FeedView()
}
