//
//  FeedEditView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/9/25.
//

import SwiftUI
import PhotosUI

// MARK: - Feed 작성/수정 화면

/// 피드 작성/수정 화면
/// - 구조: 이미지 선택 영역 + 텍스트 입력 영역
struct FeedEditView: View {
    // MARK: - Mode Definition

    /// 작성/수정 모드
    enum Mode {
        case create
        case edit(Feed)

        var title: String {
            switch self {
            case .create: return "새 게시물"
            case .edit: return "게시물 수정"
            }
        }

        var actionTitle: String {
            switch self {
            case .create: return "게시"
            case .edit: return "수정"
            }
        }
    }

    // MARK: - Properties

    let mode: Mode
    @Environment(\.dismiss) private var dismiss

    // Store (MVI)
    @State private var store: FeedEditStore

    // 입력 상태 (PhotosPicker용)
    @State private var selectedPhotos: [PhotosPickerItem] = []

    // Alert
    @State private var showErrorAlert: Bool = false
    @State private var showSuccessAlert: Bool = false

    // 액션 시트 표시 여부
    @State private var showMediaActionSheet: Bool = false

    // PhotosPicker 표시 여부
    @State private var showPhotoPicker: Bool = false
    @State private var showVideoPicker: Bool = false

    // 동영상 관련
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var selectedVideoURL: URL?

    // 키보드 제어
    @FocusState private var isTextEditorFocused: Bool

    // MARK: - Initializer

    init(
        mode: Mode,
        networkService: NetworkServiceProtocol = NetworkService(),
        // TODO: 임시 accessToken 토큰 입력 필요
        temporaryToken: String = ""
    ) {
        self.mode = mode
        self.store = FeedEditStore(
            networkService: networkService,
            temporaryToken: temporaryToken
        )
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.base) {
                // 이미지 선택 영역
                imageSelectionSection

                // 텍스트 입력 영역
                textInputSection
            }
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.medium)
        }
        .background(.wmBg)
        .onTapGesture {
            // 외부 터치 시 키보드 숨김
            isTextEditorFocused = false
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.actionTitle) {
                        store.send(.submitPost)
                    }
                    .disabled(!store.state.canSubmit)
                    .foregroundStyle(store.state.canSubmit ? .wmMain : .textSub)
                }
            }
            .overlay {
                if store.state.isUploading {
                    UploadingOverlay(message: "게시글 업로드 중...")
                }
            }
            .alert("오류", isPresented: $showErrorAlert) {
                Button("확인", role: .cancel) {
                    showErrorAlert = false
                }
            } message: {
                Text(store.state.errorMessage ?? "알 수 없는 오류가 발생했습니다.")
            }
            .alert("완료", isPresented: $showSuccessAlert) {
                Button("확인", role: .cancel) {
                    showSuccessAlert = false
                    dismiss()
                }
            } message: {
                Text("게시글이 등록되었습니다.")
            }
            .onChange(of: store.state.errorMessage) { _, newValue in
                if newValue != nil {
                    showErrorAlert = true
                }
            }
            .onChange(of: store.state.isSubmitted) { _, isSubmitted in
                if isSubmitted {
                    // 햅틱 피드백
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                    // 성공 Alert 표시
                    showSuccessAlert = true
                }
            }
            .confirmationDialog("미디어 선택", isPresented: $showMediaActionSheet) {
                Button("사진 선택(최대 5장)") {
                    showPhotoPicker = true
                }
                Button("동영상 선택(최대 10MB)") {
                    showVideoPicker = true
                }
                Button("취소", role: .cancel) {
                    showMediaActionSheet = false
                }
            }
            .photosPicker(isPresented: $showPhotoPicker,
                          selection: $selectedPhotos,
                          maxSelectionCount: 5,
                          matching: .images
            )
            .onChange(of: selectedPhotos) { _, newItems in
                selectedVideoItem = nil
                selectedVideoURL = nil

                loadPhotos(from: newItems)
            }
            .photosPicker(isPresented: $showVideoPicker,
                          selection: $selectedVideoItem,
                          matching: .videos)
            .onChange(of: selectedVideoItem) { _, newItem in
                selectedPhotos = []
                store.send(.selectImages([]))

                loadVideo(from: newItem)
            }
    }

    // MARK: - Subviews

    /// 이미지 선택 영역
    private var imageSelectionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // 섹션 타이틀
            Text("미디어")
                .font(.app(.subHeadline1))
                .foregroundStyle(.textMain)

            Button {
                showMediaActionSheet = true
            } label: {
                if store.state.selectedImages.isEmpty && selectedVideoURL == nil {
                    mediaPlaceholder
                } else {
                    if let videoURL = selectedVideoURL {
                        videoPreview(url: videoURL)
                    } else {
                        imageGridView
                    }
                }
            }
            .disabled(store.state.isUploading)
        }
    }

    /// 미디어 플레이스홀더
    private var mediaPlaceholder: some View {
        RoundedRectangle(cornerRadius: Spacing.radiusMedium)
            .fill(Color.gray.opacity(0.1))
            .frame(height: 200)
            .overlay {
                VStack(spacing: Spacing.small) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundStyle(.textSub)

                    Text("사진 또는 동영상 추가")
                        .font(.app(.content2))
                        .foregroundStyle(.textSub)
                }
            }
    }

    /// 선택된 이미지 그리드
    private var imageGridView: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Spacing.small),
                GridItem(.flexible(), spacing: Spacing.small),
                GridItem(.flexible(), spacing: Spacing.small)
            ],
            spacing: Spacing.small
        ) {
            ForEach(Array(store.state.selectedImages.enumerated()), id: \.offset) { index, image in
                imageGridCell(image: image, index: index)
            }

            // 5장 미만일 때 추가 버튼
            if store.state.selectedImages.count < 5 {
                addMoreButton
            }
        }
    }

    /// 이미지 그리드 셀
    private func imageGridCell(image: UIImage, index: Int) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSmall))

                // 삭제 버튼
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 24, height: 24)
                    )
                    .buttonWrapper {
                        withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                            // Store의 이미지 제거
                            store.send(.removeImage(at: index))

                            // PhotosPicker 선택 동기화 (안전한 인덱스 체크)
                            if index < selectedPhotos.count {
                                selectedPhotos.remove(at: index)
                            }
                        }
                    }
                    .padding(Spacing.xSmall)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// 추가 버튼
    private var addMoreButton: some View {
        RoundedRectangle(cornerRadius: Spacing.radiusSmall)
            .fill(Color.gray.opacity(0.1))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Image(systemName: "plus")
                    .font(.system(size: 32))
                    .foregroundStyle(.textSub)
            }
    }

    /// 텍스트 입력 영역
    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // 섹션 타이틀
            Text("내용")
                .font(.app(.subHeadline1))
                .foregroundStyle(.textMain)

            // TextEditor (여러 줄 입력)
            ZStack(alignment: .topLeading) {
                // 플레이스홀더
                if store.state.content.isEmpty {
                    Text("무슨 일이 일어나고 있나요?")
                        .font(.app(.content2))
                        .foregroundStyle(.textSub)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }

                TextEditor(text: Binding(
                    get: { store.state.content },
                    set: { store.send(.updateContent($0))
                    }
                ))
                    .font(.app(.content2))
                    .foregroundStyle(.textMain)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 150)
                    .disabled(store.state.isUploading)
                    .focused($isTextEditorFocused)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("완료") {
                                isTextEditorFocused = false
                            }
                            .font(.app(.content1))
                            .foregroundStyle(.wmMain)
                        }
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

            // 글자 수 표시
            HStack {
                Spacer()
                Text(store.state.characterCountText)
                    .font(.app(.subContent2))
                    .foregroundStyle(store.state.isCharacterOverLimit ? .red : .textSub)
            }
        }
    }

    // MARK: - Helper Methods

    /// 사진 로드 (PhotosPickerItem -> UIImage)
    /// - Note: 선택 순서를 보장하기 위해 순차 로드
    private func loadPhotos(from items: [PhotosPickerItem]) {
        Task {
            var loadedImages: [UIImage] = []

            // 선택 순서대로 순차 로드 (인덱스 일치 보장)
            for item in items {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else {
                        continue
                    }
                    loadedImages.append(image)
                } catch {
                    // TODO: 에러 로깅 시스템 구현 - 2025.11.15
                    print("이미지 로드 실패: \(error.localizedDescription)")
                }
            }

            // 메인 스레드에서 Store 업데이트
            await MainActor.run {
                store.send(.selectImages(loadedImages))
            }
        }
    }

    private func loadVideo(from item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            do {
                guard let movie = try await item.loadTransferable(type: MovieTransferable.self) else {
                    return
                }

                await MainActor.run {
                    selectedVideoURL = movie.url
                    print("[FeedEditView] 동영상 로드 완료: \(movie.url)")
                }
            } catch {
                print("[FeedEditView] 동영상 로드 실패: \(error)")
            }
        }
    }

    private func videoPreview(url: URL) -> some View {
        RoundedRectangle(cornerRadius: Spacing.radiusMedium)
            .fill(Color.gray.opacity(0.1))
            .frame(height: 200)
            .overlay {
                VStack(spacing: Spacing.small) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.textSub)

                    Text("동영상 선택됨")
                        .font(.app(.content2))
                        .foregroundStyle(.textMain)

                    Button("삭제") {
                        selectedVideoItem = nil
                        selectedVideoURL = nil
                    }
                    .foregroundStyle(.red)
                }
            }
    }
}

struct MovieTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL.temporaryDirectory.appending(path: "movie-\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}

// MARK: - Preview

#Preview("작성 모드") {
    FeedEditView(mode: .create)
}

//#Preview("수정 모드") {
//    FeedEditView(mode: .edit(MockFeedData.sampleFeeds[0]))
//}
