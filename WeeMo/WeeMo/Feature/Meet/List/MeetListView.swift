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

    @State private var meets: [Meet] = []

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

                    LazyVStack(spacing: 16) {
                        ForEach(meets) { meet in
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
            .navigationBarHidden(true)
            .background(Color("wmBg"))
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
