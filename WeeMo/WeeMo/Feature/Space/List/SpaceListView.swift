//
//  SpaceSearchView.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI

struct SpaceListView: View {
    @State private var searchText: String = ""
    @State private var selectedCategory: SpaceCategory = .all

    private var filteredSpaces: [Space] {
        let categoryFiltered = selectedCategory == .all
            ? Space.mockSpaces
            : Space.mockSpaces.filter { $0.category == selectedCategory }

        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.address.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
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
                    SearchBarView(searchText: $searchText)
                        .padding(.horizontal, Spacing.base)

                    // 카테고리 탭
                    CategoryTabView(selectedCategory: $selectedCategory)
                        .padding(.top, Spacing.xSmall)

                    // 인기 공간 섹션
                    if selectedCategory == .all && searchText.isEmpty {
                        PopularSpaceSectionView(spaces: Space.mockSpaces)
                            .padding(.top, Spacing.small)
                    }

                    // 모든 공간 리스트
                    AllSpaceListView(spaces: filteredSpaces)
                        .padding(.top, searchText.isEmpty ? Spacing.base : Spacing.small)
                }
                .padding(.bottom, Spacing.base)
            }
            .background(Color("wmBg"))
            .navigationBarHidden(true)
            .navigationDestination(for: Space.self) { space in
                SpaceDetailView(space: space)
            }
        }
    }
}

#Preview {
    SpaceListView()
}
