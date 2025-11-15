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
    @StateObject private var viewModel = MeetListViewModel()

    var body: some View {
        NavigationView {
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

                    if viewModel.state.isLoading {
                        VStack {
                            ProgressView("모임을 불러오는 중...")
                                .padding()
                            Spacer()
                        }
                    } else if let errorMessage = viewModel.state.errorMessage {
                        VStack(spacing: 16) {
                            Text("오류가 발생했습니다")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("다시 시도") {
                                viewModel.handle(.retryLoadMeets)
                            }
                            .buttonStyle(.bordered)
                            Spacer()
                        }
                        .padding()
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.state.meets) { meet in
                                NavigationLink(destination: MeetDetailView(meet: meet)) {
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
                viewModel.handle(.loadMeets)
            }
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            MapViewButton()
                            FloatingActionButton()
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            )

        }
    }
}

#Preview {
    MeetListView()
}
