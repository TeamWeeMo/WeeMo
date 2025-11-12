//
//  MeetingMapView.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI
import MapKit

struct MeetingMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @State private var showingList = false
    @State private var showingSearch = false
    @State private var searchText = ""
    @Environment(\.presentationMode) var presentationMode

    @State private var meetings = [
        Meeting(
            title: "주말 독서 모임",
            date: "📅 2025.11.15 (토) 14:00",
            location: "📍 모던 카페 라운",
            address: "서울 강남구 테헤란로 123",
            price: "💰 15,000원/",
            participants: "👤 4 / 8명",
            imageName: "meeting1",
            daysLeft: "D-3"
        ),
        Meeting(
            title: "요리 클래스",
            date: "📅 2025.11.20 (수) 19:00",
            location: "📍 쿠킹 스튜디오 키친",
            address: "서울 마포구 홍대입구역 56",
            price: "💰 35,000원/",
            participants: "👤 6 / 10명",
            imageName: "meeting2",
            daysLeft: "D-8"
        ),
        Meeting(
            title: "등산 동호회",
            date: "📅 2025.11.17 (일) 08:00",
            location: "📍 북한산 입구",
            address: "서울 은평구 진관동 산1",
            price: "💰 무료",
            participants: "👤 12 / 15명",
            imageName: "meeting3",
            daysLeft: "D-5"
        )
    ]

    var body: some View {
        ZStack {
            // 지도 영역
            Map(coordinateRegion: $region, annotationItems: meetings) { meeting in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: 37.5665 + Double.random(in: -0.02...0.02),
                    longitude: 126.9780 + Double.random(in: -0.02...0.02)
                )) {
                    MapPinView(count: Int.random(in: 1...5))
                }
            }
            .ignoresSafeArea()

            VStack {
                Spacer()

                // 하단 리스트 영역
                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.spring(response: 0.6)) {
                            showingList.toggle()
                        }
                    }) {
                        HStack {
                            Text("모임 리스트")
                                .font(.app(.content1))
                                .fontWeight(.medium)
                                .foregroundColor(.black)

                            Spacer()

                            Image(systemName: showingList ? "chevron.down" : "chevron.up")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(12, corners: showingList ? [.topLeft, .topRight] : .allCorners)
                        .cardShadow()
                    }

                    if showingList {
                        VStack(spacing: 0) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(meetings) { meeting in
                                        NavigationLink(destination: MeetingDetailView(meeting: meeting)) {
                                            MeetingMapCard(meeting: meeting)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                            }
                            .frame(height: 140)
                        }
                        .background(Color.white)
                        .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
                        .cardShadow()
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: HStack(spacing: 12) {
                Button(action: {
                    showingSearch.toggle()
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }

                Button(action: {
                    // 현재 위치 액션
                }) {
                    Image(systemName: "location")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
            }
        )
        .sheet(isPresented: $showingSearch) {
            SearchModalView(searchText: $searchText, meetings: meetings)
        }
    }
}

#Preview {
    MeetingMapView()
}
