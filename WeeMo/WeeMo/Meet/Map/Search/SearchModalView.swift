//
//  SearchModalView.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI

struct SearchModalView: View {
    @Binding var searchText: String
    let meetings: [Meeting]
    @Environment(\.presentationMode) var presentationMode

    var filteredMeetings: [Meeting] {
        if searchText.isEmpty {
            return meetings
        } else {
            return meetings.filter { meeting in
                meeting.title.localizedCaseInsensitiveContains(searchText) ||
                meeting.location.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 검색바
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 12)

                    TextField("모임을 검색하세요", text: $searchText)
                        .font(.app(.content2))
                        .padding(.vertical, 12)
                        .padding(.trailing, 12)

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 12)
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .commonPadding()
                .padding(.top, 20)

                // 검색 결과
                if filteredMeetings.isEmpty && !searchText.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("검색 결과가 없습니다")
                            .font(.app(.content1))
                            .foregroundColor(Color("textSub"))
                            .padding(.top, 16)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredMeetings) { meeting in
                                NavigationLink(destination: MeetingDetailView(meeting: meeting)) {
                                    MeetingCardView(meeting: meeting)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .onTapGesture {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("모임 검색")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("닫기") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.app(.content1))
                .foregroundColor(Color("textMain"))
            )
            .background(Color("wmBg"))
        }
    }
}