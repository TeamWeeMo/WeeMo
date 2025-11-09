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

    @State private var feeds: [FeedItem] = MockFeedData.sampleFeeds
    @State private var selectedFeed: FeedItem?

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                PinterestLayout(
                    numberOfColumns: 2,
                    spacing: Spacing.medium
                ) {
                    ForEach(feeds) { feed in
                        FeedCardView(item: feed)
                            // Custom Modifier 활용: 탭 제스처 + 애니메이션 + 햅틱
                            .tappableCard {
                                selectedFeed = feed
                            }
                    }
                }
                .padding(.horizontal, Spacing.base)
                .padding(.vertical, Spacing.small)
            }
            .background(.wmBg)
            .navigationTitle("피드")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // TODO: 피드 작성 화면으로 이동, 작성버튼 위치 고민
                    } label: {
                        Image(systemName: "plus")
                            .font(.app(.subHeadline2))
                            .foregroundStyle(.textMain)
                    }
                }
            }
            .navigationDestination(item: $selectedFeed) { feed in
                FeedDetailView(item: feed)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FeedView()
}

