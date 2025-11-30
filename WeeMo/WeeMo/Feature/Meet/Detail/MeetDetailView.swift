//
//  MeetDetailView.swift
//  WeeMo
//
//  Created by 차지용 on 11/8/25.
//

import SwiftUI
import Kingfisher

// MARK: - Meet Detail View

struct MeetDetailView: View {
    // MARK: - Properties

    let postId: String
    @State private var store: MeetDetailStore
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initializer

    init(postId: String, networkService: NetworkServiceProtocol = NetworkService()) {
        self.postId = postId
        self._store = State(initialValue: MeetDetailStore(networkService: networkService))
    }

    // MARK: - Body

    var body: some View {
        content
            .toolbar {
                if let meet = store.state.meet {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        likeButton(for: meet)
                    }
                }
            }
            .toolbarRole(.editor)
            .background(.wmBg)
            .onAppear {
                store.send(.onAppear(postId: postId))
            }
            .confirmationDialog("", isPresented: Binding(
                get: { store.state.showActionSheet },
                set: { if !$0 { store.send(.dismissActionSheet) } }
            ), titleVisibility: .hidden) {
                if let meet = store.state.meet {
                    NavigationLink(destination: MeetEditView(mode: .edit(postId: meet.id))) {
                        Text("수정")
                    }

                    Button("삭제", role: .destructive) {
                        store.send(.showDeleteAlert)
                    }

                    Button("취소", role: .cancel) {
                        store.send(.dismissActionSheet)
                    }
                }
            }
            .alert("모임 삭제", isPresented: Binding(
                get: { store.state.showDeleteAlert },
                set: { if !$0 { store.send(.dismissDeleteAlert) } }
            )) {
                Button("취소", role: .cancel) {
                    store.send(.dismissDeleteAlert)
                }
                Button("삭제", role: .destructive) {
                    store.send(.deleteMeet)
                }
            } message: {
                Text("정말 이 모임을 삭제하시겠습니까?\n삭제된 모임은 복구할 수 없습니다.")
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
            .alert("채팅 오류", isPresented: Binding(
                get: { store.state.chatErrorMessage != nil },
                set: { if !$0 { store.send(.dismissChatError) } }
            )) {
                Button("확인") {
                    store.send(.dismissChatError)
                }
            } message: {
                Text(store.state.chatErrorMessage ?? "")
            }
            .navigationDestination(isPresented: Binding(
                get: { store.state.shouldNavigateToChat },
                set: { if !$0 { store.send(.clearChatNavigation) } }
            )) {
                if let chatRoom = store.state.createdChatRoom {
                    ChatDetailView(room: chatRoom)
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { store.state.shouldNavigateToSpace },
                set: { if !$0 { store.send(.clearSpaceNavigation) } }
            )) {
                if let space = store.state.loadedSpace {
                    SpaceDetailView(space: space)
                }
            }
            .alert("결제 확인", isPresented: Binding(
                get: { store.state.showPaymentConfirmAlert },
                set: { if !$0 { store.send(.dismissPaymentConfirmAlert) } }
            )) {
                Button("취소", role: .cancel) {
                    store.send(.dismissPaymentConfirmAlert)
                }
                Button("확인") {
                    store.send(.confirmPayment)
                }
            } message: {
                if let meet = store.state.meet {
                    Text(paymentConfirmMessage(meet: meet))
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { store.state.shouldNavigateToPayment },
                set: { if !$0 { store.send(.clearPaymentNavigation) } }
            )) {
                if let meet = store.state.meet {
                    MeetPaymentView(meet: meet, store: store)
                }
            }
            .alert("결제 완료", isPresented: Binding(
                get: { store.state.paymentSuccessMessage != nil },
                set: { if !$0 { store.send(.dismissPaymentSuccess) } }
            )) {
                Button("확인") {
                    store.send(.dismissPaymentSuccess)
                }
            } message: {
                Text(store.state.paymentSuccessMessage ?? "")
            }
            .alert("결제 오류", isPresented: Binding(
                get: { store.state.paymentErrorMessage != nil },
                set: { if !$0 { store.send(.dismissPaymentError) } }
            )) {
                Button("확인") {
                    store.send(.dismissPaymentError)
                }
            } message: {
                Text(store.state.paymentErrorMessage ?? "")
            }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if store.state.isLoading {
            loadingView
        } else if let errorMessage = store.state.errorMessage {
            errorView(message: errorMessage)
        } else if let meet = store.state.meet {
            meetDetailContent(meet)
        } else {
            EmptyStateView(
                icon: "questionmark.circle",
                title: "모임을 불러올 수 없습니다",
                message: "잠시 후 다시 시도해주세요",
                actionTitle: "다시 시도"
            ) {
                store.send(.onAppear(postId: postId))
            }
        }
    }

    private var loadingView: some View {
        LoadingView(message: "모임 정보를 불러오는 중...")
    }

    private func errorView(message: String) -> some View {
        EmptyStateView(
            icon: "exclamationmark.triangle",
            title: "오류가 발생했습니다",
            message: message,
            actionTitle: "다시 시도"
        ) {
            store.send(.retryLoad)
        }
    }

    // MARK: - Meet Detail Content

    private func meetDetailContent(_ meet: Meet) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // 이미지 갤러리
                MeetMediaGallery(fileURLs: meet.fileURLs)

                VStack(alignment: .leading, spacing: 0) {
                    // 제목과 D-day
                    HStack(alignment: .top, spacing: 8) {
                        Text(meet.title)
                            .font(.app(.subHeadline1))
                            .fontWeight(.semibold)
                            .foregroundColor(.textMain)
                            .lineLimit(2)

                        // 편집 버튼 (본인 글일 때만)
                        if let currentUserId = TokenManager.shared.userId,
                           currentUserId == meet.creator.userId {
                      
                            Image(systemName: "square.and.pencil")
                                .buttonWrapper {
                                    store.send(.showActionSheet)
                                }
                                .font(.system(size: 16))
                                .foregroundColor(.wmMain)
                                .offset(y: -2)
                        }
                        
                        Spacer()

                        Text(meet.dDayText)
                            .font(.app(.subContent3))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 4)
                            .background(dDayBackgroundColor(for: meet))
                            .cornerRadius(4)
                    }
                    .padding(.horizontal, Spacing.base)
                    .padding(.top, Spacing.base)

                    // 주최자 정보
                    creatorSection(meet: meet)

                    Divider()

                    // 모임 정보
                    meetInfoSection(meet: meet)

                    Divider()

                    // 모임 소개
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text("모임 소개")
                            .font(.app(.content1))
                            .fontWeight(.semibold)
                            .foregroundColor(.textMain)

                        Text(meet.content)
                            .font(.app(.content2))
                            .foregroundColor(.textSub)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, Spacing.base)
                    .padding(.vertical, Spacing.base)

                    // 참가하기 버튼
                    joinButton(meet: meet)

                    if let joinError = store.state.joinErrorMessage {
                        Text(joinError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, Spacing.base)
                    }
                }
            }
        }
        .ignoresSafeArea(.all, edges: .top)
    }

    // MARK: - Subviews

    private func creatorSection(meet: Meet) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: {
                // TODO: 주최자 프로필 페이지로 이동
            }) {
                HStack {
                    // 프로필 이미지
                    profileImage(for: meet.creator)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("주최자")
                            .font(.app(.subContent1))
                            .foregroundColor(.textSub)
                        Text(meet.creator.nickname)
                            .font(.app(.content4))
                            .fontWeight(.semibold)
                            .foregroundColor(.textMain)
                    }

                    Spacer()

                    // 채팅하기 버튼 (본인이 아닌 경우에만 표시)
                    if let currentUserId = TokenManager.shared.userId,
                       currentUserId != meet.creator.userId {
                        Button(action: {
                            store.send(.createChatRoom(opponentUserId: meet.creator.userId))
                        }) {
                            HStack(spacing: 4) {
                                if store.state.isCreatingChat {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "message")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("채팅")
                                        .font(.app(.subContent1))
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.wmMain)
                            .cornerRadius(16)
                        }
                        .disabled(store.state.isCreatingChat)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
    }

    private func profileImage(for user: User) -> some View {
        Group {
            if let profileImage = user.profileImageURL, !profileImage.isEmpty {
                KFImage(URL(string: FileRouter.fileURL(from: profileImage)))
                    .withAuthHeaders()
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            )
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                profilePlaceholder(nickname: user.nickname)
            }
        }
    }

    private func profilePlaceholder(nickname: String) -> some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 40, height: 40)
            .overlay(
                Text(String(nickname.prefix(1)))
                    .font(.app(.content2))
                    .fontWeight(.medium)
            )
    }

    private func meetInfoSection(meet: Meet) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("대여 공간")
                .font(.app(.content2))
                .fontWeight(.semibold)
                .foregroundColor(.textSub)
                .padding(.bottom, Spacing.xSmall)
            // 공간 정보 카드 (탭 시 상세 화면 이동)
            if !meet.spaceName.isEmpty, let spaceId = meet.spaceId {
                spaceCard(meet: meet)
                    .buttonWrapper {
                        store.send(.navigateToSpace(spaceId: spaceId))
                    }
                    .disabled(store.state.isLoadingSpace)
                .opacity(store.state.isLoadingSpace ? 0.5 : 1.0)
            }

            InfoRow(icon: "clock", title: "모집기간", content: meet.recruitmentScheduleText)

            InfoRow(icon: "figure.2.arms.open", title: "참여인원", content: "\(meet.participants) / \(meet.capacity)명")

            InfoRow(icon: "person.crop.square.on.square.angled", title: "참가조건", content: meet.gender.displayText)
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.base)
    }

    /// 공간 정보 카드
    @ViewBuilder
    private func spaceCard(meet: Meet) -> some View {
        MeetSpaceCard(
            spaceName: meet.spaceName,
            address: meet.address,
            spaceImageURL: meet.spaceImageURL,
            reservationScheduleText: meet.spaceReservationScheduleText,
            priceText: meet.priceText,
            imageSize: 60
        )
    }

    private func joinButton(meet: Meet) -> some View {
        let buttonTitle: String
        let isDisabled: Bool

        if meet.isFullyBooked {
            buttonTitle = "모집완료"
            isDisabled = true
        } else if store.state.hasJoined {
            buttonTitle = "참가완료"
            isDisabled = true
        } else {
            buttonTitle = "참가하기"
            isDisabled = false
        }

        return Button(action: {
            store.send(.showPaymentConfirmAlert)
        }) {
            if store.state.isJoining {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(.wmMain)
                    .cornerRadius(8)
            } else {
                Text(buttonTitle)
                    .font(.app(.content1))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(isDisabled ? .gray : .wmMain)
                    .cornerRadius(8)
            }
        }
        .disabled(store.state.isJoining || store.state.hasJoined || meet.isFullyBooked)
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 34)
    }
    

    /// 결제 확인 알럿 메시지 생성
    private func paymentConfirmMessage(meet: Meet) -> String {
        var message = ""
        message += "모임: \(meet.title)\n\n"
        message += "공간: \(meet.spaceName)\n"
        message += "주소: \(meet.address)\n\n"
        message += "예약시간: \(meet.spaceReservationScheduleText)\n\n"
        message += "참가비용: \(meet.priceText)"
        return message
    }

    /// 좋아요 버튼
    private func likeButton(for meet: Meet) -> some View {
        let isLiked = LikeManager.shared.isLiked(postId: meet.id)
        
        return Image(systemName: isLiked ? "heart.fill" : "heart")
            .buttonWrapper {
                LikeManager.shared.toggleLike(postId: meet.id)
            }
            .font(.system(size: 16))
            .foregroundColor(isLiked ? .red : .gray)
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let title: String
    let content: String
    var contentColor: Color = .textMain

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.app(.subContent1))
                    .fontWeight(.semibold)
                    .foregroundColor(.textSub)

                Text(content)
                    .font(.app(.subContent1))
                    .foregroundColor(contentColor)
            }

            Spacer()
        }
    }
}


#Preview {
    NavigationStack {
        MeetDetailView(postId: "sample-post-id")
    }
}
