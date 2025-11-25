//
//  ChatDetailView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/10/25.
//

import SwiftUI
import Kingfisher
import PhotosUI

// MARK: - 채팅 상세 화면

/// 채팅방 상세 화면 (메시지 목록 + 입력창)
struct ChatDetailView: View {
    // MARK: - Properties

    @StateObject private var store: ChatDetailStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotos: [PhotosPickerItem] = []

    init(room: ChatRoom) {
        self._store = StateObject(wrappedValue: ChatDetailStore(room: room))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 메시지 목록
            messageListView

            // 에러 메시지
            if let errorMessage = store.state.errorMessage {
                errorView(errorMessage)
            }

            // 입력창
            messageInputBar
        }
        .background(.wmBg)
        .navigationTitle(store.state.room.otherUser?.nickname ?? "채팅")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $store.state.showImageGallery) {
            ImageGalleryView(
                images: store.state.galleryImages,
                startIndex: store.state.galleryStartIndex
            )
        }
        .onTapGesture {
            // 다른 곳을 탭하면 + 메뉴 닫기
            if store.state.showPlusMenu {
                store.state.showPlusMenu = false
            }
        }
        .onAppear {
            // 30일 이내 메시지 정리 (한 번만 실행)
            store.cleanupRecentMessages()

            store.handle(.loadMessages(roomId: store.state.room.id))
            store.handle(.setupSocketConnection(roomId: store.state.room.id))
        }
        .onDisappear {
            // Socket 연결은 유지하되 다른 화면 이동을 로깅
            print("🔌 ChatDetailView onDisappear - 연결 유지")
        }
        .onChange(of: selectedPhotos) { oldValue, newValue in
            // 선택된 사진들을 Data로 변환
            Task {
                await loadSelectedImages()
            }
        }
    }

    // MARK: - Helper Methods

    /// 전송 가능한 텍스트가 있는지 확인 (이미지는 즉시 전송됨)
    private var canSendContent: Bool {
        let hasText = !store.state.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let notSending = !store.state.isSendingMessage

        return hasText && notSending
    }

    /// 텍스트 전송 (이미지는 즉시 전송되므로 텍스트만 처리)
    private func sendMessageWithContent() {
        let textContent = store.state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        print("🚀 sendMessageWithContent 호출됨")
        print("📝 텍스트: '\(textContent)'")

        // 텍스트가 있으면 텍스트 전송 (이미지는 이미 즉시 전송됨)
        if !textContent.isEmpty {
            print("📝 텍스트 전송")
            store.handle(.sendMessage(content: textContent))
        } else {
            print("❌ 전송할 텍스트 없음")
        }
    }

    /// 선택된 사진들을 Data로 변환하고 즉시 전송
    private func loadSelectedImages() async {
        // 빈 배열이면 처리하지 않음 (초기화로 인한 트리거 방지)
        guard !selectedPhotos.isEmpty else {
            return
        }

        var imageDatas: [Data] = []

        for item in selectedPhotos {
            if let data = try? await item.loadTransferable(type: Data.self) {
                imageDatas.append(data)
            }
        }

        await MainActor.run {
            store.state.selectedImages = imageDatas
            store.state.showPlusMenu = false // 메뉴 닫기
            print("📸 \(imageDatas.count)개 이미지 선택됨, 즉시 전송 시작")

            // 이미지가 있으면 즉시 전송
            if !imageDatas.isEmpty {
                sendSelectedImages()
            }
        }
    }

    /// 선택된 이미지들을 전송
    private func sendSelectedImages() {
        let imageDatas = store.state.selectedImages
        let textContent = store.state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        print("🔄 sendSelectedImages 시작")
        print("📸 전송할 이미지 개수: \(imageDatas.count)")
        print("📝 함께 보낼 텍스트: '\(textContent)'")

        guard !imageDatas.isEmpty else {
            print("❌ 이미지 데이터가 비어있음")
            return
        }

        Task {
            do {
                print("🚀 이미지 업로드 시작...")

                // 이미지 업로드 (PostRouter의 uploadFiles 사용)
                let fileDTO = try await NetworkService().upload(
                    PostRouter.uploadFiles(images: imageDatas),
                    images: imageDatas,
                    responseType: FileDTO.self
                )

                print("✅ 이미지 업로드 성공, URLs: \(fileDTO.files)")

                // 업로드된 파일 URLs로 메시지 전송 (텍스트도 함께)
                let fileURLs = fileDTO.files
                await MainActor.run {
                    print("📨 메시지 전송 시작...")
                    store.handle(.sendMessage(content: textContent, files: fileURLs))

                    // 선택된 이미지들과 텍스트 초기화
                    selectedPhotos = []
                    store.state.selectedImages = []
                    store.state.inputText = ""

                    print("📸 \(imageDatas.count)개 이미지와 텍스트 업로드 및 전송 완료")
                }

            } catch {
                await MainActor.run {
                    store.state.errorMessage = "이미지 업로드에 실패했습니다: \(error.localizedDescription)"

                    // 실패시 이미지들 초기화
                    selectedPhotos = []
                    store.state.selectedImages = []

                    print("❌ 이미지 업로드 실패: \(error)")
                }
            }
        }
    }

    // MARK: - Subviews

    private var messageListView: some View {
        ScrollViewReader { proxy in
            if store.state.isLoading && store.state.messages.isEmpty {
                // 로딩 상태
                VStack(spacing: Spacing.medium) {
                    Spacer()

                    VStack(spacing: Spacing.small) {
                        ProgressView()
                            .scaleEffect(1.2)

                        Text("메시지를 불러오는 중...")
                            .font(.app(.content2))
                            .foregroundColor(.textSub)
                    }

                    Spacer()
                }

            } else if store.state.messages.isEmpty {
                // 빈 상태
                VStack(spacing: Spacing.medium) {
                    Spacer()

                    VStack(spacing: Spacing.small) {
                        Image(systemName: "message")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.6))

                        Text("대화를 시작해보세요")
                            .font(.app(.headline1))
                            .foregroundColor(.textMain)

                        Text("첫 메시지를 보내서 대화를 시작할 수 있어요")
                            .font(.app(.content2))
                            .foregroundColor(.textSub)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                }

            } else {
                // 메시지가 있는 경우
                ScrollView {
                    VStack(spacing: Spacing.medium) {
                        // 상단 로딩 인디케이터
                        if store.state.hasMoreMessages {
                            VStack {
                                if store.state.isLoadingMore {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("이전 메시지 불러오는 중...")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, Spacing.small)
                                }
                            }
                            .frame(height: 50)
                            .onAppear {
                                if !store.state.isLoadingMore,
                                   let firstMessage = store.state.messages.first {
                                    print("스크롤 상단 도달 - 이전 메시지 로드 시작")
                                    store.handle(.loadMoreMessages(beforeMessageId: firstMessage.id))
                                }
                            }
                            .id("loadMoreTrigger")
                        }

                        // 메시지 목록
                        ForEach(Array(store.state.messages.enumerated()), id: \.element.id) { index, message in
                            ChatBubble(
                                message: message,
                                isMine: message.isMine(currentUserId: store.state.currentUserId),
                                showTime: shouldShowTime(for: message, at: index, in: store.state.messages),
                                onImageGalleryTap: { images, startIndex in
                                    store.state.galleryImages = images
                                    store.state.galleryStartIndex = startIndex
                                    store.state.showImageGallery = true
                                }
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, Spacing.base)
                }
                .refreshable {
                    if store.state.hasMoreMessages,
                       !store.state.isLoadingMore,
                       let firstMessage = store.state.messages.first {
                        print("🔄 Pull to refresh - 이전 메시지 로드 시작")
                        store.handle(.loadMoreMessages(beforeMessageId: firstMessage.id))
                    }
                }
                .task {
                    // 뷰가 나타날 때 맨 아래로 이동
                    if !store.state.messages.isEmpty, let lastMessage = store.state.messages.last {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .onChange(of: store.state.messages.count) { oldCount, newCount in
                    // 새 메시지가 추가될 때 스크롤
                    guard !store.state.messages.isEmpty, newCount > oldCount else { return }
                    if let lastMessage = store.state.messages.last {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .onChange(of: store.state.shouldScrollToBottom) { _, shouldScroll in
                    if shouldScroll, let lastMessage = store.state.messages.last {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                        // 스크롤 완료 후 flag 리셋
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            store.state.shouldScrollToBottom = false
                        }
                    }
                }
            }
        }
    }

    /// 시간 표시 여부 결정
    private func shouldShowTime(for message: ChatMessage, at index: Int, in messages: [ChatMessage]) -> Bool {
        // 배열 범위 확인
        guard index >= 0 && index < messages.count else { return true }

        // 마지막 메시지는 항상 시간 표시
        guard index < messages.count - 1 else { return true }

        let currentMessage = message
        let nextMessage = messages[index + 1]

        // 메시지 ID로 정확성 확인
        guard currentMessage.id == messages[index].id else { return true }

        // 다음 메시지와 보낸 사람이 다르면 시간 표시
        if currentMessage.sender.userId != nextMessage.sender.userId {
            return true
        }

        // 다음 메시지와 시간이 다르면 시간 표시 (분 단위로 비교)
        let calendar = Calendar.current
        let currentMinute = calendar.dateComponents([.hour, .minute], from: currentMessage.createdAt)
        let nextMinute = calendar.dateComponents([.hour, .minute], from: nextMessage.createdAt)

        return currentMinute.hour != nextMinute.hour || currentMinute.minute != nextMinute.minute
    }

    private func errorView(_ message: String) -> some View {
        HStack {
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
            Spacer()
            Button("재시도") {
                store.handle(.retryLoadMessages)
            }
            .font(.caption)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.1))
    }


    // MARK: - Subviews

    /// 메시지 입력창
    private var messageInputBar: some View {
        VStack(spacing: 0) {
            // 추가 옵션 메뉴
            if store.state.showPlusMenu {
                plusMenuView
            }

            HStack(spacing: Spacing.small) {
                // + 버튼
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.wmMain)
                    .buttonWrapper {
                        store.state.showPlusMenu.toggle()
                    }

                // 텍스트 입력
                TextField("메시지를 입력하세요", text: $store.state.inputText)
                    .font(.app(.content2))
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                            .fill(Color.gray.opacity(0.1))
                    )

                // 전송 버튼
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20))
                    .padding(.vertical, Spacing.small)
                    .foregroundStyle(.wmMain)
                    .onTapGesture {
                        print("🔘 전송 버튼 탭됨!")
                        let hasText = !store.state.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        print("📝 텍스트: '\(store.state.inputText)' 있음: \(hasText)")
                        print("🚫 전송중: \(store.state.isSendingMessage)")

                        if hasText {
                            print("✅ 텍스트 전송 시작!")
                            sendMessageWithContent()
                        } else {
                            print("❌ 전송할 텍스트 없음")
                        }
                    }
            }
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.small)
        }
        .background(.wmBg)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(Color.gray.opacity(0.3)),
            alignment: .top
        )
    }

    /// + 버튼 메뉴
    private var plusMenuView: some View {
        VStack(spacing: Spacing.medium) {
            // 상단: 옵션 버튼들
            HStack(spacing: Spacing.base) {
                // 사진 보관함
                VStack(spacing: Spacing.xSmall) {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 50, height: 50)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.white)
                            }
                    }

                    Text("사진")
                        .font(.app(.subContent2))
                        .foregroundStyle(.textSub)
                }

                // 카메라
                VStack(spacing: Spacing.xSmall) {
                    Circle()
                        .fill(.green)
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: "camera")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                        }
                        .buttonWrapper {
                            // TODO: 카메라 열기
                            print("카메라")
                            store.state.showPlusMenu = false
                        }

                    Text("카메라")
                        .font(.app(.subContent2))
                        .foregroundStyle(.textSub)
                }

                // 음성
                VStack(spacing: Spacing.xSmall) {
                    Circle()
                        .fill(.orange)
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: "mic")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                        }
                        .buttonWrapper {
                            // TODO: 음성 녹음
                            print("음성 녹음")
                            store.state.showPlusMenu = false
                        }

                    Text("음성")
                        .font(.app(.subContent2))
                        .foregroundStyle(.textSub)
                }

                Spacer()
            }
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.medium)
        .background(.wmBg)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(Color.gray.opacity(0.3)),
            alignment: .bottom
        )
    }

}

// MARK: - Chat Bubble Component

/// 채팅 말풍선 컴포넌트
//TODO: - 모서리 말풍선 이미지 적용 ?
struct ChatBubble: View {
    let message: ChatMessage
    let isMine: Bool
    let showTime: Bool
    let onImageGalleryTap: (([String], Int) -> Void)?

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.small) {
            if isMine {
                // 내 메시지: 오른쪽 정렬
                Spacer(minLength: 60)
                timeLabel
                    .opacity(showTime ? 1 : 0)
                messageContent
            } else {
                // 상대방 메시지: 왼쪽 정렬
                profileImage
                messageContent
                timeLabel
                    .opacity(showTime ? 1 : 0)
                Spacer(minLength: 60)
            }
        }
    }

    // MARK: - Subviews

    /// 프로필 이미지 (상대방만)
    @ViewBuilder
    private var profileImage: some View {
        if !isMine {
                if let profileURL = message.sender.profileImageURL,
                   let url = URL(string: profileURL) {
                    KFImage(url)
                        .placeholder {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.gray)
                                .font(.system(size: 16))
                        }
                }
        }
    }

    /// 메시지 내용
    @ViewBuilder
    private var messageContent: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: Spacing.xSmall) {
            // 이미지가 있으면 표시
            if message.hasMedia {
                imageGridView
            }

            // 텍스트 메시지
            if !message.content.isEmpty {
                Text(message.content)
                    .font(.app(.content2))
                    .foregroundStyle(isMine ? .white : .textMain)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                            .fill(isMine ? Color.wmMain : Color.gray.opacity(0.1))
                    )
            }
        }
    }

    /// 시간 라벨
    private var timeLabel: some View {
        Text(message.createdAt.chatTimeString())
            .font(.app(.subContent2))
            .foregroundStyle(.textSub)
    }

    /// 이미지 그리드 뷰 (카카오톡 스타일)
    @ViewBuilder
    private var imageGridView: some View {
        let imageCount = message.files.count
        let maxDisplay = 4
        let displayImages = Array(message.files.prefix(maxDisplay))

        if imageCount == 1 {
            // 1개 이미지: 단일 이미지 표시
            singleImageView(fileURL: message.files[0])
        } else if imageCount == 2 {
            // 2개 이미지: 2x1 그리드
            HStack(spacing: 2) {
                ForEach(Array(displayImages.enumerated()), id: \.offset) { index, fileURL in
                    imageView(fileURL: fileURL)
                        .frame(width: 100, height: 100)
                }
            }
        } else if imageCount == 3 {
            // 3개 이미지: 첫 번째는 큰 이미지, 나머지 2개는 작은 이미지
            HStack(spacing: 2) {
                imageView(fileURL: displayImages[0])
                    .frame(width: 100, height: 202)

                VStack(spacing: 2) {
                    imageView(fileURL: displayImages[1])
                        .frame(width: 100, height: 100)
                    imageView(fileURL: displayImages[2])
                        .frame(width: 100, height: 100)
                }
            }
        } else {
            // 4개 이상: 2x2 그리드, 4번째에 +N 오버레이
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    squareImageView(fileURL: displayImages[0])
                    squareImageView(fileURL: displayImages[1])
                }
                HStack(spacing: 2) {
                    squareImageView(fileURL: displayImages[2])

                    ZStack {
                        squareImageView(fileURL: displayImages[3])

                        if imageCount > maxDisplay {
                            Rectangle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .overlay {
                                    Text("+\(imageCount - maxDisplay)")
                                        .font(.app(.headline1))
                                        .foregroundStyle(.white)
                                }
                        }
                    }
                    .onTapGesture {
                        onImageGalleryTap?(message.files, 3)
                    }
                }
            }
        }
    }

    /// 개별 이미지 뷰
    @ViewBuilder
    private func imageView(fileURL: String) -> some View {
        let fullURL = FileRouter.fileURL(from: fileURL)
        let _ = print("🖼️ 이미지 로딩 시도: \(fullURL)")

        if let url = URL(string: fullURL) {
            KFImage(url)
                .withAuthHeaders()
                .placeholder {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                }
                .onSuccess { result in
                    print("✅ 이미지 로딩 성공: \(fullURL)")
                }
                .onFailure { error in
                    print("❌ 이미지 로딩 실패: \(fullURL), 에러: \(error)")
                }
                .retry(maxCount: 3, interval: .seconds(1))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .onTapGesture {
                    if let index = message.files.firstIndex(of: fileURL) {
                        onImageGalleryTap?(message.files, index)
                    }
                }
        } else {
            let _ = print("❌ 잘못된 URL 형태: \(fullURL)")
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
        }
    }

    /// 정사각형 이미지 뷰 (4개 이상일 때 사용)
    @ViewBuilder
    private func squareImageView(fileURL: String) -> some View {
        let fullURL = FileRouter.fileURL(from: fileURL)
        let _ = print("🖼️ 정사각형 이미지 로딩 시도: \(fullURL)")

        if let url = URL(string: fullURL) {
            KFImage(url)
                .withAuthHeaders()
                .placeholder {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                }
                .onSuccess { result in
                    print("✅ 정사각형 이미지 로딩 성공: \(fullURL)")
                }
                .onFailure { error in
                    print("❌ 정사각형 이미지 로딩 실패: \(fullURL), 에러: \(error)")
                }
                .retry(maxCount: 3, interval: .seconds(1))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .onTapGesture {
                    if let index = message.files.firstIndex(of: fileURL) {
                        onImageGalleryTap?(message.files, index)
                    }
                }
        } else {
            let _ = print("❌ 잘못된 URL 형태: \(fullURL)")
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 100)
        }
    }

    /// 단일 이미지 뷰 (더 큰 크기)
    @ViewBuilder
    private func singleImageView(fileURL: String) -> some View {
        let fullURL = FileRouter.fileURL(from: fileURL)
        let _ = print("🖼️ 단일 이미지 로딩 시도: \(fullURL)")

        if let url = URL(string: fullURL) {
            KFImage(url)
                .withAuthHeaders()
                .placeholder {
                    RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 200, height: 150)
                }
                .onSuccess { result in
                    print("✅ 단일 이미지 로딩 성공: \(fullURL)")
                }
                .onFailure { error in
                    print("❌ 단일 이미지 로딩 실패: \(fullURL), 에러: \(error)")
                }
                .retry(maxCount: 3, interval: .seconds(1))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: 200, maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
                .onTapGesture {
                    onImageGalleryTap?(message.files, 0)
                }
        } else {
            let _ = print("❌ 잘못된 URL 형태: \(fullURL)")
            RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 200, height: 150)
        }
    }
}

// MARK: - Image Gallery View

/// 이미지 전체보기 갤러리
struct ImageGalleryView: View {
    let images: [String]
    let startIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int

    init(images: [String], startIndex: Int) {
        self.images = images
        self.startIndex = startIndex
        self._currentIndex = State(initialValue: startIndex)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                TabView(selection: $currentIndex) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, fileURL in
                        let fullURL = FileRouter.fileURL(from: fileURL)
                        if let url = URL(string: fullURL) {
                            KFImage(url)
                                .withAuthHeaders()
                                .placeholder {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("\(currentIndex + 1) / \(images.count)")
            .navigationBarTitleTextColor(.white)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: - Navigation Bar Title Color Extension

extension View {
    func navigationBarTitleTextColor(_ color: Color) -> some View {
        self.toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        let sampleRoom = ChatRoom(
            id: "sample-room-id",
            participants: [
                User(userId: "user1", nickname: "사용자1", profileImageURL: nil),
                User(userId: "user2", nickname: "사용자2", profileImageURL: nil)
            ],
            lastChat: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        ChatDetailView(room: sampleRoom)
    }
}
