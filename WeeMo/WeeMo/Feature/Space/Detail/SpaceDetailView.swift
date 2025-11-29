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
                // 미디어 갤러리 (이미지 + 동영상)
                MeetMediaGallery(fileURLs: space.imageURLs)

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

            // 본인이 작성한 공간일 때만 ... 버튼 표시
            if let currentUserId = TokenManager.shared.userId,
               currentUserId == space.creatorId {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        store.send(.showActionSheet)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18))
                            .foregroundColor(Color("wmMain"))
                    }
                }
            }
        }
        .alert("예약 확인", isPresented: Binding(
            get: { store.state.showReservationAlert },
            set: { newValue in
                if !newValue {
                    Task { @MainActor in
                        store.send(.dismissAlert)
                    }
                }
            }
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
        .confirmationDialog("", isPresented: Binding(
            get: { store.state.showActionSheet },
            set: { newValue in
                if !newValue {
                    Task { @MainActor in
                        store.send(.dismissActionSheet)
                    }
                }
            }
        ), titleVisibility: .hidden) {
            NavigationLink(destination: SpaceCreateView(mode: .edit(postId: space.id))) {
                Text("수정")
            }

            Button("삭제", role: .destructive) {
                store.send(.showDeleteAlert)
            }

            Button("취소", role: .cancel) {
                store.send(.dismissActionSheet)
            }
        }
        .alert("공간 삭제", isPresented: Binding(
            get: { store.state.showDeleteAlert },
            set: { newValue in
                if !newValue {
                    Task { @MainActor in
                        store.send(.dismissDeleteAlert)
                    }
                }
            }
        )) {
            Button("취소", role: .cancel) {
                store.send(.dismissDeleteAlert)
            }
            Button("삭제", role: .destructive) {
                store.send(.deleteSpace)
            }
        } message: {
            Text("정말 이 공간을 삭제하시겠습니까?\n삭제된 공간은 복구할 수 없습니다.")
        }
        .onChange(of: store.state.isDeleted) { _, isDeleted in
            if isDeleted {
                dismiss()
            }
        }
        .overlay {
            if store.state.isDeleting {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView("삭제 중...")
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                    )
            }
        }
    }
}
