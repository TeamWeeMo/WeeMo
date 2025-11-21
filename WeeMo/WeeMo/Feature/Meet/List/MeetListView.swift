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
    @StateObject private var store = MeetListViewStore()
    @State private var navigationPath = NavigationPath()

    var body: some View {
        ScrollView {
                VStack {
                    HStack {
                        Text("모임")
                            .font(.app(.headline2))
                            .foregroundColor(Color("textMain"))
                            .padding(.leading, 16)
                        Spacer()
                    }
                    .padding(.top)

                    SearchBar(text: $searchText)

                    FilterButton(
                        selectedOption: $selectedSortOption,
                        showingOptions: $showingSortOptions
                    )

                    if store.state.isLoading {
                        VStack {
                            ProgressView("모임을 불러오는 중...")
                                .padding()
                            Spacer()
                        }
                    } else if let errorMessage = store.state.errorMessage {
                        VStack(spacing: 16) {
                            Text("오류가 발생했습니다")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("다시 시도") {
                                store.handle(.retryLoadMeets)
                            }
                            .buttonStyle(.bordered)
                            Spacer()
                        }
                        .padding()
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(store.state.meets) { meet in
                                Button(action: {
                                    navigationPath.append(meet.postId)
                                }) {
                                    MeetCardView(meet: meet)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationBarHidden(true)
            .background(Color("wmBg"))
            .onAppear {
                store.handle(.loadMeets)
            }
            .onChange(of: selectedSortOption) { sortOption in
                print("🔄 Sort option changed to: \(sortOption.rawValue)")
                store.handle(.sortMeets(option: sortOption))
            }
            .onChange(of: searchText) { searchQuery in
                print("🔍 Search text changed to: '\(searchQuery)'")
                store.handle(.searchMeets(query: searchQuery))
            }
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Button(action: {
                                navigationPath.append("map")
                            }) {
                                HStack {
                                    Image(systemName: "map")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black)
                                    Text("지도보기")
                                        .font(.app(.content2))
                                        .foregroundColor(.black)
                                }
                                .frame(width: 130, height: 40)
                                .background(Color.white)
                                .cornerRadius(25)
                                .cardShadow()
                            }

                            Button(action: {
                                navigationPath.append("edit")
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("모임 만들기")
                                        .font(.app(.content2))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 130, height: 40)
                                .background(Color.black)
                                .cornerRadius(25)
                            }
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            )
        .navigationBarHidden(false)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: String.self) { value in
            if value == "map" {
                MeetMapView()
            } else if value == "edit" {
                MeetEditView()
            } else {
                MeetDetailView(postId: value)
            }
        }
    }
}

#Preview {
    MeetListView()
}
