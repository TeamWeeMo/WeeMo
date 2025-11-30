//
//  SpaceDetailView.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI
import Kingfisher

struct SpaceDetailView: View {
    let space: Space
    @StateObject private var store: SpaceDetailStore
    @Environment(\.dismiss) private var dismiss
    @State private var showPDFViewer = false
    @State private var generatedPDFURL: URL?
    @State private var isGeneratingPDF = false

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

            // PDF 생성 버튼
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    generatePDF()
                } label: {
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 18))
                        .foregroundColor(.wmMain)
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

            if isGeneratingPDF {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView("PDF 생성 중...")
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                    )
            }
        }
        .sheet(isPresented: $showPDFViewer) {
            PDFViewerView(pdfURL: generatedPDFURL)
        }
    }

    // MARK: - PDF 생성

    private func generatePDF() {
        isGeneratingPDF = true

        // 서버 예약 정보를 ReservationInfo 배열로 변환
        var reservationInfos: [ReservationInfo] = store.state.serverReservations.map { serverReservation in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "yyyy년 MM월 dd일"
            let dateString = formatter.string(from: serverReservation.date)
            let timeSlot = String(format: "%02d:00 - %02d:00", serverReservation.startHour, serverReservation.endHour)

            // 가격 포맷팅 (NumberFormatter 사용)
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let priceString = (numberFormatter.string(from: NSNumber(value: serverReservation.totalPrice)) ?? "\(serverReservation.totalPrice)") + "원"

            return ReservationInfo(
                userName: serverReservation.userName,
                date: dateString,
                timeSlot: timeSlot,
                totalPrice: priceString
            )
        }

        // 현재 사용자가 새로 예약한 정보가 있으면 추가
        if store.state.shouldShowReservationInfo {
            let currentReservation = ReservationInfo(
                userName: store.state.userNickname,
                date: store.state.formattedDate,
                timeSlot: store.state.formattedTimeSlot,
                totalPrice: store.state.totalPrice
            )
            reservationInfos.append(currentReservation)
        }

        print("[PDF] 총 예약 정보: \(reservationInfos.count)건")
        print("[PDF] - 서버 예약: \(store.state.serverReservations.count)건")
        print("[PDF] - 현재 예약: \(store.state.shouldShowReservationInfo ? 1 : 0)건")

        // 상세 예약 정보 출력
        for (index, info) in reservationInfos.enumerated() {
            print("[PDF] 예약 [\(index + 1)]: \(info.userName) - \(info.date) - \(info.timeSlot) - \(info.totalPrice)")
        }

        print("[PDF] 공간 이미지 URLs: \(space.imageURLs)")

        // 공간 이미지 다운로드 (첫 번째 이미지)
        if let firstImageURL = space.imageURLs.first, !firstImageURL.isEmpty {
            print("[PDF] 이미지 다운로드 시작: \(firstImageURL)")
            downloadImage(from: firstImageURL) { image in
                print("[PDF] 이미지 다운로드 완료: \(image != nil)")
                self.createPDF(with: image, reservationInfos: reservationInfos)
            }
        } else {
            print("[PDF] 이미지 없이 PDF 생성")
            // 이미지 없이 PDF 생성
            createPDF(with: nil, reservationInfos: reservationInfos)
        }
    }

    private func downloadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        // 상대 경로를 절대 경로로 변환 (v1 포함)
        let fullURLString: String
        if urlString.hasPrefix("http") {
            fullURLString = urlString
        } else {
            // FileRouter의 헬퍼 사용 (자동으로 /v1 추가)
            fullURLString = FileRouter.fileURL(from: urlString)
        }

        print("[PDF] 최종 이미지 URL: \(fullURLString)")

        guard let url = URL(string: fullURLString) else {
            print("[PDF] 유효하지 않은 URL: \(fullURLString)")
            completion(nil)
            return
        }

        KingfisherManager.shared.retrieveImage(with: url) { result in
            switch result {
            case .success(let imageResult):
                print("[PDF] 이미지 다운로드 성공")
                completion(imageResult.image)
            case .failure(let error):
                print("[PDF] 이미지 다운로드 실패: \(error)")
                completion(nil)
            }
        }
    }

    private func createPDF(with image: UIImage?, reservationInfos: [ReservationInfo]) {
        print("[PDF] createPDF 호출 - 이미지: \(image != nil), 예약정보 수: \(reservationInfos.count)")

        // PDF 생성
        if let pdfURL = SpacePDFGenerator.generatePDF(
            space: space,
            reservationInfos: reservationInfos,
            spaceImage: image
        ) {
            print("[PDF] PDF 생성 성공: \(pdfURL)")
            DispatchQueue.main.async {
                self.generatedPDFURL = pdfURL
                self.showPDFViewer = true
                self.isGeneratingPDF = false
            }
        } else {
            print("[PDF] PDF 생성 실패")
            DispatchQueue.main.async {
                self.isGeneratingPDF = false
            }
        }
    }
}
