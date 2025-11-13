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

    @State private var feeds: [Feed] = MockFeedData.sampleFeeds
    @State private var selectedFeed: Feed?
    @State private var isShowingEditView: Bool = false

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
                    Image(systemName: "plus")
                        .font(.app(.subHeadline2))
                        .foregroundStyle(.textMain)
                        .buttonWrapper {
                            isShowingEditView = true
                        }
                }
            }
            .navigationDestination(item: $selectedFeed) { feed in
                FeedDetailView(item: feed)
            }
            .navigationDestination(isPresented: $isShowingEditView) {
                FeedEditView(mode: .create)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FeedView()
}

