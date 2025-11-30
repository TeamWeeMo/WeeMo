//
//  MeetEditView.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI
import PhotosUI
import Kingfisher
import iamport_ios

// MARK: - Meet Edit View

struct MeetEditView: View {
    // MARK: - Mode Definition

    enum Mode {
        case create
        case edit(postId: String)

        var title: String {
            switch self {
            case .create: return "모임 만들기"
            case .edit: return "모임 수정"
            }
        }

        var actionTitle: String {
            switch self {
            case .create: return "완료"
            case .edit: return "수정"
            }
        }

        var isEditMode: Bool {
            if case .edit = self { return true }
            return false
        }

        var postId: String? {
            if case .edit(let postId) = self { return postId }
            return nil
        }
    }

    // MARK: - Properties

    let mode: Mode
    @Environment(\.dismiss) private var dismiss
    @State private var store: MeetEditStore

    // 바텀시트 상태
    @State private var showSpaceSelection: Bool = false
    @State private var showCustomMediaPicker: Bool = false

    // 동영상 편집
    @State private var pendingVideoURL: URL? = nil
    @State private var showVideoOptionAlert: Bool = false
    @State private var showVideoEditor: Bool = false

    // 키보드 제어
    @FocusState private var focusedField: Field?

    enum Field {
        case title, content
    }

    // MARK: - Initializer

    init(
        mode: Mode,
        networkService: NetworkServiceProtocol = NetworkService()
    ) {
        self.mode = mode
        self._store = State(initialValue: MeetEditStore(networkService: networkService))
    }

    // MARK: - Body

    var body: some View {
        contentView
            .modifier(NavigationSetupModifier(mode: mode, store: store))
            .modifier(AlertsSetupModifier(mode: mode, store: store, dismiss: dismiss))
            .modifier(PaymentNavigationModifier(store: store))
            .modifier(LifecycleModifier(mode: mode, store: store))
            .alert("동영상 처리 방법", isPresented: $showVideoOptionAlert) {
                Button("직접 편집") {
                    showVideoEditor = true
                }
                Button("자동 압축") {
                    if let url = pendingVideoURL {
                        store.send(.autoCompressVideo(url))
                        pendingVideoURL = nil
                    }
                }
                Button("취소", role: .cancel) {
                    pendingVideoURL = nil
                }
            } message: {
                Text("동영상을 직접 편집하시겠습니까, 아니면 자동으로 압축하시겠습니까?")
            }
            .alert("압축 실패", isPresented: .init(
                get: { store.state.videoCompressionFailed },
                set: { if !$0 { store.send(.resetVideoCompressionFailed) } }
            )) {
                Button("확인", role: .cancel) {
                    pendingVideoURL = nil
                    store.send(.resetVideoCompressionFailed)
                }
            } message: {
                Text("동영상을 10MB 이하로 압축할 수 없습니다.\n동영상의 길이가 너무 길거나 화질이 높습니다.\n직접 편집을 통해 길이를 줄이거나 화질을 낮춰주세요.")
            }
            .sheet(isPresented: $showVideoEditor) {
                if let videoURL = pendingVideoURL {
                    VideoEditorView(
                        videoURL: videoURL,
                        onComplete: { mediaItem in
                            if let mediaItem = mediaItem {
                                var currentItems = store.state.selectedMediaItems
                                currentItems.append(mediaItem)
                                store.send(.selectMediaItems(currentItems))
                            }
                            // 임시 파일 삭제
                            try? FileManager.default.removeItem(at: videoURL)
                            pendingVideoURL = nil
                            showVideoEditor = false
                        },
                        onCancel: {
                            // 취소 시에도 임시 파일 삭제
                            try? FileManager.default.removeItem(at: videoURL)
                            pendingVideoURL = nil
                            showVideoEditor = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showCustomMediaPicker) {
                CustomMediaPickerView(
                    maxSelectionCount: 5 - store.state.selectedMediaItems.count,
                    onImageSelected: { images in
                        store.send(.handleSelectedImages(images))
                        showCustomMediaPicker = false
                    },
                    onVideoSelected: { videoURL in
                        // 동영상 선택 시 즉시 옵션 Alert
                        pendingVideoURL = videoURL
                        showCustomMediaPicker = false
                        showVideoOptionAlert = true
                    },
                    onDismiss: {
                        showCustomMediaPicker = false
                    }
                )
                .presentationDetents([.large])
            }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: Spacing.base) {
                // 1. 예약한 공간 선택
                spaceSelectionSection

                // 2. 모임 이름 작성 영역
                titleInputSection

                // 3. 모집 인원 작성 영역
                capacitySection

                // 4. 참가비 표시
                pricePerPersonSection

                // 5. 미디어 추가 영역 (이미지 + 동영상)
                mediaPickerSection

                // 6. 모임 소개 작성 영역
                contentInputSection

                // 7. 모집 기간 선택 영역
                recruitmentPeriodSection

                // 8. 성별 제한 선택 영역
                genderSection
            }
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.medium)
        }
        .background(.wmBg)
        .onTapGesture {
            focusedField = nil
        }
        .overlay {
            if store.state.isLoading {
                UploadingOverlay(message: mode.isEditMode ? "수정 중..." : "모임 생성 중...")
            }
        }
        .sheet(isPresented: $showSpaceSelection) {
            ReservedSpaceListView(store: store)
                .presentationDetents([.large])
        }
    }

    // MARK: - Sections

    /// 1. 예약한 공간 선택 섹션
    private var spaceSelectionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("예약한 공간 선택")
                .font(.app(.subHeadline1))
                .foregroundStyle(.textMain)

            Button {
                showSpaceSelection = true
            } label: {
                if let space = store.state.selectedSpace {
                    selectedSpaceCard(space: space)
                } else {
                    emptySpaceCard
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    /// 선택된 공간 카드
    private func selectedSpaceCard(space: Space) -> some View {
        SelectedSpaceCard(
            space: space,
            reservationDate: store.state.reservationDate,
            reservationStartHour: store.state.reservationStartHour,
            reservationTotalHours: store.state.reservationTotalHours ?? store.state.totalHours,
            totalHours: store.state.totalHours
        )
    }

    /// 빈 공간 카드
    private var emptySpaceCard: some View {
        EmptyStatePlaceholder(
            systemImage: "plus.circle",
            message: "공간을 선택해주세요",
            height: 120
        )
    }

    /// 2. 모임 이름 작성 섹션
    private var titleInputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("모임 이름")
                .font(.app(.subHeadline1))
                .foregroundStyle(.textMain)

            TextField("모임 이름을 입력해주세요", text: Binding(
                get: { store.state.title },
                set: { store.send(.updateTitle($0)) }
            ))
            .font(.app(.content2))
            .padding(Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                    .fill(Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .focused($focusedField, equals: .title)
        }
    }

    /// 3. 모집 인원 섹션
    private var capacitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("모집 인원")
                .font(.app(.subHeadline1))
                .foregroundStyle(.textMain)

            HStack {
                Text("\(store.state.capacity)명")
                    .font(.app(.content1))
                    .foregroundStyle(.textMain)

                Spacer()

                Stepper("", value: Binding(
                    get: { store.state.capacity },
                    set: { store.send(.updateCapacity($0)) }
                ), in: 1...max(1, store.state.selectedSpace?.maxPeople ?? 100))
                .labelsHidden()
            }
            .padding(Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                    .fill(Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )

            if let space = store.state.selectedSpace {
                Text("최대 \(space.maxPeople)명까지 모집 가능합니다")
                    .font(.app(.subContent2))
                    .foregroundStyle(.textSub)
            }
        }
    }

    /// 4. 참가비 표시 섹션
    private var pricePerPersonSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("1인당 참가비")
                .font(.app(.subHeadline1))
                .foregroundStyle(.textMain)

            HStack {
                Text("\(store.state.calculatedPrice.formatted())원")
                    .font(.app(.headline2))
                    .foregroundStyle(.wmMain)

                Spacer()

                if store.state.selectedSpace != nil {
                    Text("= 총비용 ÷ \(store.state.capacity)명")
                        .font(.app(.subContent2))
                        .foregroundStyle(.textSub)
                }
            }
            .padding(Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                    .fill(Color.wmMain.opacity(0.1))
            )
        }
    }

    /// 5. 미디어 추가 섹션 (이미지 + 동영상)
    private var mediaPickerSection: some View {
        SimpleMediaPickerSection(
            title: "모임 미디어 (최대 5개)",
            maxCount: 5,
            selectedMediaItems: store.state.selectedMediaItems,
            onAddTapped: {
                showCustomMediaPicker = true
            },
            onRemoveItem: { index in
                var items = store.state.selectedMediaItems
                items.remove(at: index)
                store.send(.selectMediaItems(items))
            }
        )
    }

    /// 6. 모임 소개 섹션
    private var contentInputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("모임 소개")
                .font(.app(.subHeadline1))
                .foregroundStyle(.textMain)

            ZStack(alignment: .topLeading) {
                if store.state.content.isEmpty {
                    Text("모임에 대해 소개해주세요")
                        .font(.app(.content2))
                        .foregroundStyle(.textSub)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }

                TextEditor(text: Binding(
                    get: { store.state.content },
                    set: { store.send(.updateContent($0)) }
                ))
                .font(.app(.content2))
                .foregroundStyle(.textMain)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 150)
                .focused($focusedField, equals: .content)
            }
            .padding(Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                    .fill(Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }

    /// 7. 모집 기간 섹션
    private var recruitmentPeriodSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("모집 기간")
                .font(.app(.subHeadline1))
                .foregroundStyle(.textMain)

            VStack(spacing: Spacing.small) {
                // 모집 시작일
                HStack {
                    Text("시작일")
                        .font(.app(.content2))
                        .foregroundStyle(.textMain)

                    Spacer()

                    DatePicker(
                        "",
                        selection: Binding(
                            get: { store.state.recruitmentStartDate },
                            set: { store.send(.updateRecruitmentStartDate($0)) }
                        ),
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                }

                Divider()

                // 모집 종료일
                HStack {
                    Text("종료일")
                        .font(.app(.content2))
                        .foregroundStyle(.textMain)

                    Spacer()

                    DatePicker(
                        "",
                        selection: Binding(
                            get: { store.state.recruitmentEndDate },
                            set: { store.send(.updateRecruitmentEndDate($0)) }
                        ),
                        in: recruitmentEndDateRange,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                }
            }
            .padding(Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                    .fill(Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )

            Text("모집 종료일은 모임 시작 시간 이전까지 설정 가능합니다")
                .font(.app(.subContent2))
                .foregroundStyle(.textSub)
        }
    }

    /// 모집 종료일 선택 가능 범위 (안전한 Range 생성)
    private var recruitmentEndDateRange: ClosedRange<Date> {
        let startDate = store.state.recruitmentStartDate
        let meetingDate = store.state.meetingStartDate

        // meetingStartDate가 recruitmentStartDate보다 이전이면 최소 1시간 후로 설정
        let endDate = meetingDate > startDate ? meetingDate : startDate.addingTimeInterval(3600)
        return startDate...endDate
    }

    /// 8. 성별 제한 섹션
    private var genderSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("성별 제한")
                .font(.app(.subHeadline1))
                .foregroundStyle(.textMain)

            Picker("성별 제한", selection: Binding(
                get: { store.state.gender },
                set: { store.send(.updateGender($0)) }
            )) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    Text(gender.displayText).tag(gender)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - View Modifiers

    private struct NavigationSetupModifier: ViewModifier {
        let mode: MeetEditView.Mode
        let store: MeetEditStore

        func body(content: Content) -> some View {
            content
                .navigationTitle(mode.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarRole(.editor)
                .tint(.wmMain)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(mode.actionTitle) {
                            if case .create = mode {
                                store.send(.createMeet)
                            } else if case .edit(let postId) = mode {
                                store.send(.updateMeet(postId: postId))
                            }
                        }
                        .disabled(!store.state.canSubmit)
                        .foregroundStyle(store.state.canSubmit ? .wmMain : .textSub)
                    }
                }
        }
    }

    private struct AlertsSetupModifier: ViewModifier {
        let mode: MeetEditView.Mode
        let store: MeetEditStore
        let dismiss: DismissAction

        func body(content: Content) -> some View {
            content
                .alert("오류", isPresented: .init(
                    get: { store.state.showErrorAlert },
                    set: { if !$0 { store.send(.dismissErrorAlert) } }
                )) {
                    Button("확인", role: .cancel) {
                        store.send(.dismissErrorAlert)
                    }
                } message: {
                    Text(store.state.errorMessage ?? "알 수 없는 오류가 발생했습니다.")
                }
                .alert("완료", isPresented: .init(
                    get: { store.state.showSuccessAlert },
                    set: { if !$0 { store.send(.dismissSuccessAlert) } }
                )) {
                    Button("확인", role: .cancel) {
                        store.send(.dismissSuccessAlert)
                        dismiss()
                    }
                } message: {
                    Text("모임이 수정되었습니다.")
                }
                .alert("결제 필요", isPresented: .init(
                    get: { store.state.showPaymentRequiredAlert },
                    set: { if !$0 { store.send(.dismissPaymentRequiredAlert) } }
                )) {
                    Button("취소", role: .cancel) {
                        store.send(.dismissPaymentRequiredAlert)
                        dismiss()
                    }
                    Button("결제하기") {
                        store.send(.confirmPayment)
                    }
                } message: {
                    Text("모임을 작성하였습니다.\n주최자도 참가비 결제가 필요합니다.")
                }
                .alert("완료", isPresented: .init(
                    get: { store.state.paymentSuccessMessage != nil },
                    set: { if !$0 { store.send(.dismissPaymentSuccess) } }
                )) {
                    Button("확인") {
                        store.send(.dismissPaymentSuccess)
                        dismiss()
                    }
                } message: {
                    Text(store.state.paymentSuccessMessage ?? "")
                }
        }
    }

    private struct PaymentNavigationModifier: ViewModifier {
        let store: MeetEditStore

        func body(content: Content) -> some View {
            content.navigationDestination(isPresented: .init(
                get: { store.state.shouldNavigateToPayment },
                set: { if !$0 { store.send(.clearPaymentNavigation) } }
            )) {
                if let postId = store.state.createdPostId {
                    MeetPaymentView(
                        postId: postId,
                        title: store.state.title,
                        price: store.state.pricePerPerson,
                        store: store
                    )
                }
            }
        }
    }

    private struct LifecycleModifier: ViewModifier {
        let mode: MeetEditView.Mode
        let store: MeetEditStore
        @Environment(\.dismiss) private var dismiss

        func body(content: Content) -> some View {
            content
                .onChange(of: store.state.isCreated) { _, isCreated in
                    if isCreated {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
                .onChange(of: store.state.isUpdated) { _, isUpdated in
                    if isUpdated {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        store.send(.showSuccessAlert)
                    }
                }
                .onAppear {
                    store.send(.onAppear)
                    if case .edit(let postId) = mode {
                        store.send(.loadMeetForEdit(postId: postId))
                    }
                }
        }
    }

}

