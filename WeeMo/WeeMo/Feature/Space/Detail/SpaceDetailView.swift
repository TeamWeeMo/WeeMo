//
//  SpaceDetailView.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI

struct SpaceDetailView: View {
    let space: Space
    @StateObject private var store: SpaceDetailStore
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initializer
    init(space: Space) {
        self.space = space
        _store = StateObject(wrappedValue: SpaceDetailStore(
            spaceId: space.id,
            pricePerHour: space.pricePerHour,
            latitude: space.latitude,
            longitude: space.longitude
        ))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // 이미지 캐러셀
                ImageCarouselView(imageURLs: space.imageURLs)

                VStack(alignment: .leading, spacing: Spacing.base) {
                    // 같은 위치 모임 섹션
                    SameLocationMeetingsSection(meetings: store.state.sameLocationMeetings)
                        .padding(.top, Spacing.xSmall)

                    // 기본 정보
                    SpaceInfoSection(space: space)
                        .padding(.leading, Spacing.base)

                    // 구분선
                    Divider()
                        .padding(.horizontal, Spacing.base)

                    // 공간 소개
                    SpaceDescriptionSection(description: space.description)
                        .padding(.horizontal, Spacing.base)

                    // 날짜 선택 캘린더 (TimelineBarView 포함)
                    DatePickerCalendarView(
                        selectedDate: Binding(
                            get: { store.state.selectedDate },
                            set: { date in
                                if let date = date {
                                    store.send(.dateSelected(date))
                                }
                            }
                        ),
                        startHour: Binding(
                            get: { store.state.startHour },
                            set: { store.send(.startHourChanged($0)) }
                        ),
                        endHour: Binding(
                            get: { store.state.endHour },
                            set: { store.send(.endHourChanged($0)) }
                        ),
                        pricePerHour: space.pricePerHour,
                        blockedHours: store.state.currentBlockedHours
                    )
                    .padding(.horizontal, Spacing.base)

                    // 예약하기 버튼
                    ReservationButton {
                        store.send(.reservationButtonTapped)
                    }
                    .padding(.horizontal, Spacing.base)

                    // 예약 정보 표시 (예약하기 버튼을 눌렀을 때만 표시)
                    if store.state.shouldShowReservationInfo {
                        ReservationInfoSection(
                            userProfileImage: store.state.userProfileImage,
                            userNickname: store.state.userNickname,
                            selectedDate: store.state.formattedDate,
                            selectedTimeSlot: store.state.formattedTimeSlot,
                            totalPrice: store.state.totalPrice
                        )
                        .padding(.horizontal, Spacing.base)
                    }

                    Spacer()
                        .frame(height: Spacing.base)
                        .padding(.bottom, Spacing.base)
                }
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .background(Color("wmBg"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            store.send(.viewAppeared)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: Spacing.xSmall) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: AppFontSize.s16.rawValue))
                            .foregroundColor(Color("textMain"))
                    }
                }
            }
        }
        .alert("예약 확인", isPresented: Binding(
            get: { store.state.showReservationAlert },
            set: { if !$0 { store.send(.dismissAlert) } }
        )) {
            Button("취소", role: .cancel) {
                // Alert 닫기
            }
            Button("확인") {
                store.send(.confirmReservation)
            }
        } message: {
            Text("\(store.state.formattedDate)\n\(store.state.formattedTimeSlot)\n\(store.state.totalPrice)\n\n예약하시겠습니까?")
        }
    }
}
