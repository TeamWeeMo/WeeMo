//
//  ChatDetailView_New.swift
//  WeeMo
//
//  Created by 차지용 on 11/25/25.
//

import SwiftUI
import PhotosUI
import Kingfisher
import Combine
struct ChatDetailView: View {
    // MARK: - Properties

    @StateObject private var store: ChatDetailStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedUser: User?
    @State private var selectedVideoURL: String?

    init(room: ChatRoom) {
        self._store = StateObject(wrappedValue: ChatDetailStore(room: room))
    }

    // MARK: - Body

    var body: some View {
        mainContentView
            .background(.wmBg)
            .navigationTitle(store.state.room.otherUser?.nickname ?? "채팅")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $store.state.showImageGallery) {
                ImageGalleryView(
                    images: store.state.galleryImages,
                    startIndex: store.state.galleryStartIndex
                )
            }
            .sheet(isPresented: Binding(
                get: { selectedVideoURL != nil },
                set: { newValue in
                    if !newValue {
                        selectedVideoURL = nil
                    }
                }
            )) {
                if let videoURL = selectedVideoURL {
                    VideoPlayerView(videoURL: videoURL)
                }
            }
            .sheet(isPresented: $store.state.showCamera) {
                CameraCaptureView { imageData in
                    store.handle(.sendCameraPhoto(data: imageData))
                }
            }
            .sheet(isPresented: $store.state.showVoiceRecorder) {
                VoiceRecorderView { voiceData in
                    store.handle(.sendVoiceRecording(data: voiceData))
                }
            }
            .onTapGesture {
                // 다른 곳을 탭하면 + 메뉴 닫기
                if store.state.showPlusMenu {
                    store.state.showPlusMenu = false
                }
            }
            .onAppear {
                handleViewAppear()
            }
            .onDisappear {
                handleViewDisappear()
            }
            .onChange(of: selectedPhotos) { oldValue, newValue in
                handlePhotosChange()
            }
            .background {
                // 숨겨진 NavigationLink로 프로필 화면 네비게이션 처리
                if let selectedUser = selectedUser {
                    NavigationLink(
                        destination: ProfileView(userId: selectedUser.userId),
                        isActive: .constant(true)
                    ) {
                        EmptyView()
                    }
                    .hidden()
                    .onAppear {
                        // 네비게이션이 완료되면 selectedUser 초기화
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.selectedUser = nil
                        }
                    }
                }
            }
    }

    private var mainContentView: some View {
        VStack(spacing: 0) {
            // 메시지 목록
            messageListView

            // 에러 메시지
            if let errorMessage = store.state.errorMessage {
                errorView(errorMessage)
            }

            // 입력창
            ChatInputBar(store: store, selectedPhotos: $selectedPhotos)
        }
    }

    // MARK: - Message List View

    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.xSmall) {
                    // 더 불러오기 버튼 (상단)
                    if !store.state.messages.isEmpty && store.state.hasMoreMessages {
                        Button("이전 메시지 더보기") {
                            if let firstMessage = store.state.messages.first {
                                store.handle(.loadMoreMessages(beforeMessageId: firstMessage.id))
                            }
                        }
                        .font(.app(.subContent1))
                        .foregroundStyle(Color("wmMain"))
                        .padding(.vertical, Spacing.small)
                        .onAppear {
                            if !store.state.isLoadingMore,
                               let firstMessage = store.state.messages.first {
                                print("스크롤 상단 도달 - 이전 메시지 로드 시작")
                                store.handle(.loadMoreMessages(beforeMessageId: firstMessage.id))
                            }
                        }
                    }

                    if store.state.isLoadingMore {
                        ProgressView("이전 메시지를 불러오는 중...")
                            .font(.app(.subContent2))
                            .foregroundStyle(.textSub)
                            .padding()
                    }

                    // 메시지 목록 (일반 순서)
                    messagesListView
                }
                .padding(.top, Spacing.small)
                .padding(.bottom, Spacing.base)
            }
            .onAppear {
                handleViewAppear()
                // 이미지 로딩을 위해 여러 번 스크롤 시도
                for delay in [0.1, 0.3, 0.6, 1.0] {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        if let lastMessage = store.state.messages.last {
                            withAnimation(.none) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .onChange(of: store.state.messages) { _, newMessages in
                // 새 메시지 추가시 이미지 로딩 고려하여 스크롤
                if let lastMessage = newMessages.last {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.none) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .refreshable {
                store.handle(.retryLoadMessages)
            }
        }
    }

    // MARK: - Computed Properties

    private var groupedMessages: [DateMessageGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.state.messages) { message in
            calendar.startOfDay(for: message.createdAt)
        }

        return grouped.map { date, messages in
            DateMessageGroup(date: date, messages: messages.sorted { $0.createdAt < $1.createdAt })
        }
        .sorted { $0.date < $1.date }
    }

    private var messagesListView: some View {
        ForEach(groupedMessages, id: \.date) { dateGroup in
            DateSeparatorView(date: dateGroup.date)
                .padding(.vertical, Spacing.medium)

            ForEach(Array(dateGroup.messages.enumerated()), id: \.element.id) { index, message in
                let showTime = shouldShowTime(for: index, in: dateGroup.messages)
                let isMine = message.sender.userId == store.state.currentUserId

                ChatBubble(
                    message: message,
                    isMine: isMine,
                    showTime: showTime,
                    onImageGalleryTap: { images, startIndex in
                        let selectedFile = images[startIndex]
                        if selectedFile.lowercased().contains(".mp4") ||
                           selectedFile.lowercased().contains(".mov") ||
                           selectedFile.lowercased().contains("video_") {
                            // 영상인 경우 VideoPlayer 표시
                            selectedVideoURL = selectedFile
                        } else {
                            // 이미지인 경우 기존 갤러리 표시
                            store.state.galleryImages = images
                            store.state.galleryStartIndex = startIndex
                            store.state.showImageGallery = true
                        }
                    },
                    onProfileTap: { user in
                        selectedUser = user
                    }
                )
                .padding(.vertical, showTime ? Spacing.xSmall : 2)
                .id(message.id)
            }
        }
    }

    private var reversedGroupedMessages: [DateMessageGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.state.messages) { message in
            calendar.startOfDay(for: message.createdAt)
        }

        return grouped.map { date, messages in
            // 각 날짜 그룹 내에서는 시간 순서대로 정렬 (오래된 것부터)
            DateMessageGroup(date: date, messages: messages.sorted { $0.createdAt < $1.createdAt })
        }
        // 날짜는 최신 날짜부터 (역순)
        .sorted { $0.date > $1.date }
    }

    // MARK: - Helper Views

    private func errorView(_ message: String) -> some View {
        VStack {
            Text("오류가 발생했습니다")
                .font(.app(.subHeadline2))
                .foregroundStyle(.textMain)
            Text(message)
                .font(.app(.content2))
                .foregroundStyle(.textSub)
                .multilineTextAlignment(.center)
            Button("다시 시도") {
                store.handle(.retryLoadMessages)
            }
            .font(.app(.content1))
            .foregroundStyle(.wmMain)
        }
        .padding()
    }

    // MARK: - Helper Methods

    private func handleViewAppear() {
        // 30일 이내 메시지 정리 (한 번만 실행)
        store.cleanupRecentMessages()

        store.handle(.loadMessages(roomId: store.state.room.id))
        store.handle(.setupSocketConnection(roomId: store.state.room.id))
    }

    private func handleViewDisappear() {
        print("ChatDetailView onDisappear - 특정 방 연결 해제")
        store.handle(.closeSocketConnection)
    }

    private func handlePhotosChange() {
        Task {
            await loadSelectedMedia()
        }
    }

    /// 시간 표시 여부 결정
    private func shouldShowTime(for index: Int, in messages: [ChatMessage]) -> Bool {
        guard index >= 0 && index < messages.count else { return true }

        let currentMessage = messages[index]
        guard index < messages.count - 1 else { return true }

        let nextMessage = messages[index + 1]
        guard currentMessage.id == messages[index].id else { return true }

        let timeDifference = nextMessage.createdAt.timeIntervalSince(currentMessage.createdAt)
        let isSameSender = currentMessage.sender.userId == nextMessage.sender.userId

        return !isSameSender || timeDifference > 60
    }

    /// 선택된 미디어(사진/동영상) 로드 및 즉시 전송
    private func loadSelectedMedia() async {
        print(" loadSelectedMedia 호출됨 - 선택된 미디어 개수: \(selectedPhotos.count)")

        var mediaDatas: [(data: Data, isVideo: Bool)] = []

        for (index, item) in selectedPhotos.enumerated() {
            print(" 파일 \(index): ContentTypes=\(item.supportedContentTypes.map { $0.identifier })")

            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    // 영상 파일 감지
                    let isVideo = item.supportedContentTypes.contains { contentType in
                        contentType.conforms(to: .movie) || contentType.conforms(to: .video)
                    }
                    mediaDatas.append((data: data, isVideo: isVideo))
                    print("파일 \(index) 로드 성공: \(data.count) bytes, 영상: \(isVideo)")
                } else {
                    print("파일 \(index) Data 변환 실패")
                }
            } catch {
                print("파일 \(index) 로드 실패: \(error)")
            }
        }

        // 선택 초기화
        selectedPhotos.removeAll()

        // 미디어가 있으면 즉시 전송
        if !mediaDatas.isEmpty {
            sendSelectedMedia(with: mediaDatas)
        }
    }

    /// 선택된 미디어를 서버에 업로드하고 메시지 전송
    private func sendSelectedMedia(with mediaDatas: [(data: Data, isVideo: Bool)]) {
        print("미디어 전송 시작: \(mediaDatas.count)개 파일")

        // 영상 파일도 지원
        let videoCount = mediaDatas.filter { $0.isVideo }.count
        let imageCount = mediaDatas.filter { !$0.isVideo }.count
        print("전송할 파일: 이미지 \(imageCount)개, 영상 \(videoCount)개")

        let allDatas = mediaDatas.map { $0.data }

        // ChatService를 통해 파일 업로드 및 메시지 전송
        Task {
            do {
                let fileURLs = try await ChatService.shared.uploadChatFiles(
                    roomId: store.state.room.id,
                    files: allDatas
                )

                await MainActor.run {
                    print("파일 업로드 성공: \(fileURLs)")
                    // 파일 URL들을 메시지로 전송 (내용은 빈 문자열)
                    store.handle(.sendMessage(content: "", files: fileURLs))
                }
            } catch {
                await MainActor.run {
                    print(" 파일 업로드 실패: \(error)")
                    store.state.errorMessage = "파일 업로드에 실패했습니다: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct DateMessageGroup {
    let date: Date
    let messages: [ChatMessage]
}

// MARK: - Date Separator View

struct DateSeparatorView: View {
    let date: Date

    private var dateString: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let messageDate = calendar.startOfDay(for: date)

        if calendar.isDate(messageDate, inSameDayAs: today) {
            return "오늘"
        } else if calendar.isDate(messageDate, equalTo: calendar.date(byAdding: .day, value: -1, to: today)!, toGranularity: .day) {
            return "어제"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")

            if calendar.isDate(messageDate, equalTo: today, toGranularity: .year) {
                formatter.dateFormat = "M월 d일 EEEE"
            } else {
                formatter.dateFormat = "yyyy년 M월 d일 EEEE"
            }

            return formatter.string(from: date)
        }
    }

    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 0.5)

            Text(dateString)
                .font(.app(.subContent2))
                .foregroundStyle(.textSub)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.xSmall)
                .background(.wmBg)

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 0.5)
        }
        .padding(.horizontal, Spacing.base)
    }
}
