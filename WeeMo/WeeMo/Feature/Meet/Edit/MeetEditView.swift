//
//  MeetEditView.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI
import PhotosUI
import Kingfisher

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

    // PhotosPicker 상태
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    // 바텀시트 상태
    @State private var showSpaceSelection: Bool = false

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

                // 5. 이미지 추가 영역
                imagePickerSection

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
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .tint(.wmMain)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(mode.actionTitle) {
                    submitMeet()
                }
                .disabled(!store.state.canSubmit)
                .foregroundStyle(store.state.canSubmit ? .wmMain : .textSub)
            }
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
            Text(mode.isEditMode ? "모임이 수정되었습니다." : "모임이 생성되었습니다.")
        }
        .alert("삭제", isPresented: .init(
            get: { store.state.showDeleteAlert },
            set: { if !$0 { store.send(.dismissDeleteAlert) } }
        )) {
            Button("취소", role: .cancel) {
                store.send(.dismissDeleteAlert)
            }
            Button("삭제", role: .destructive) {
                if let postId = mode.postId {
                    store.send(.deleteMeet(postId: postId))
                }
            }
        } message: {
            Text("정말 이 모임을 삭제하시겠습니까?")
        }
        .onChange(of: store.state.isCreated) { _, isCreated in
            if isCreated {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                store.send(.showSuccessAlert)
            }
        }
        .onChange(of: store.state.isUpdated) { _, isUpdated in
            if isUpdated {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                store.send(.showSuccessAlert)
            }
        }
        .onChange(of: store.state.isDeleted) { _, isDeleted in
            if isDeleted {
                dismiss()
            }
        }
        .onAppear {
            store.send(.onAppear)
            if case .edit(let postId) = mode {
                store.send(.loadMeetForEdit(postId: postId))
            }
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
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.medium) {
                // 공간 이미지
                spaceImageView(space: space)

                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text(space.title)
                        .font(.app(.subHeadline2))
                        .foregroundStyle(.textMain)
                        .lineLimit(1)

                    Text(space.address)
                        .font(.app(.content2))
                        .foregroundStyle(.textSub)
                        .lineLimit(1)

                    Text(space.formattedPrice)
                        .font(.app(.content2))
                        .foregroundStyle(.wmMain)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.textSub)
            }

            Divider()

            // 추가 정보 (예약일+시간, 최대 인원, 이용시간, 총비용)
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                SpaceInfoRow(title: "예약 일시", value: formattedReservationDateTime())
                SpaceInfoRow(title: "최대 인원", value: "\(space.maxPeople)명")
                SpaceInfoRow(title: "이용 시간", value: "\(store.state.totalHours)시간")
                SpaceInfoRow(title: "총 비용", value: "\((space.pricePerHour * store.state.totalHours).formatted())원")
            }
        }
        .padding(Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                .fill(Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                .stroke(Color.wmMain.opacity(0.3), lineWidth: 1)
        )
    }

    /// 공간 이미지 뷰
    @ViewBuilder
    private func spaceImageView(space: Space) -> some View {
        if let imageURL = space.imageURLs.first {
            KFImage(URL(string: FileRouter.fileURL(from: imageURL)))
                .withAuthHeaders()
                .placeholder {
                    imagePlaceholder
                }
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSmall))
        } else {
            imagePlaceholder
            
        }
    }
    /// 이미지 플레이스홀더
    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: Spacing.radiusSmall)
            .fill(Color.gray.opacity(0.2))
            .frame(width: 80, height: 80)
            .overlay {
                Image(systemName: "building.2")
                    .foregroundStyle(.textSub)
            }
    }

    /// 빈 공간 카드
    private var emptySpaceCard: some View {
        VStack(spacing: Spacing.small) {
            Image(systemName: "plus.circle")
                .font(.system(size: 32))
                .foregroundStyle(.textSub)

            Text("공간을 선택해주세요")
                .font(.app(.content2))
                .foregroundStyle(.textSub)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                .fill(Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
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

    /// 5. 이미지 추가 섹션
    private var imagePickerSection: some View {
        ImagePickerSection2(
            title: "모임 이미지",
            maxCount: 5,
            layout: .horizontal,
            selectedImages: Binding(
                get: { store.state.selectedImages },
                set: { store.send(.selectImages($0)) }
            ),
            selectedPhotoItems: $selectedPhotoItems,
            existingImageURLs: Binding(
                get: { store.state.existingImageURLs },
                set: { _ in }
            ),
            shouldKeepExistingImages: Binding(
                get: { store.state.shouldKeepExistingImages },
                set: { _ in }
            )
        )
        .onChange(of: selectedPhotoItems) { _, newItems in
            loadPhotos(from: newItems)
        }
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("완료") {
                    focusedField = nil
                }
                .font(.app(.content1))
                .foregroundStyle(.wmMain)
            }
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

    // MARK: - Helper Methods

    private func submitMeet() {
        switch mode {
        case .create:
            store.send(.createMeet)
        case .edit(let postId):
            store.send(.updateMeet(postId: postId))
        }
    }

    /// 예약 날짜+시간 포맷팅
    private func formattedReservationDateTime() -> String {
        guard let date = store.state.reservationDate,
              let startHour = store.state.reservationStartHour,
              let totalHours = store.state.reservationTotalHours else {
            return "예약 정보 없음"
        }

        let endHour = startHour + totalHours
        return ReservationFormatter.formattedDateTime(date: date, startHour: startHour, endHour: endHour)
    }

    private func loadPhotos(from items: [PhotosPickerItem]) {
        Task {
            var loadedImages: [UIImage] = []

            for item in items {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else {
                        continue
                    }
                    loadedImages.append(image)
                } catch {
                    print("이미지 로드 실패: \(error.localizedDescription)")
                }
            }

            await MainActor.run {
                store.send(.selectImages(loadedImages))
            }
        }
    }
}

// MARK: - Space Info Row

private struct SpaceInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.app(.content2))
                .foregroundStyle(.textSub)

            Spacer()

            Text(value)
                .font(.app(.content2))
                .foregroundStyle(.textMain)
        }
    }
}

// MARK: - Preview

#Preview("생성 모드") {
    NavigationStack {
        MeetEditView(mode: .create)
    }
}

#Preview("수정 모드") {
    NavigationStack {
        MeetEditView(mode: .edit(postId: "sample_post_id"))
    }
}
