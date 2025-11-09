//
//  FeedEditView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/9/25.
//

import SwiftUI
import PhotosUI

// MARK: - Feed 작성/수정 화면

/// 피드 작성/수정 화면 (Instagram 스타일)
/// - Enum Mode 패턴으로 하나의 View를 재사용
/// - 구조: 이미지 선택 영역 + 텍스트 입력 영역
struct FeedEditView: View {
    // MARK: - Mode Definition

    /// 작성/수정 모드
    enum Mode {
        case create
        case edit(FeedItem)

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

        var isEditing: Bool {
            if case .edit = self { return true }
            return false
        }

        var existingItem: FeedItem? {
            if case .edit(let item) = self { return item }
            return nil
        }
    }

    // MARK: - Properties

    let mode: Mode
    @Environment(\.dismiss) private var dismiss

    // 입력 상태
    @State private var content: String = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []

    // MARK: - Initializer

    init(mode: Mode) {
        self.mode = mode

        // 수정 모드일 경우 기존 데이터로 초기화
        if case .edit(let item) = mode {
            _content = State(initialValue: item.content)
            // TODO: 기존 이미지 로드
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
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
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.actionTitle) {
                        handleSubmit()
                    }
                    .disabled(!isFormValid)
                    .foregroundStyle(isFormValid ? .wmMain : .textSub)
                }
            }
        }
    }

    // MARK: - Subviews

    /// 이미지 선택 영역
    private var imageSelectionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // 섹션 타이틀
            Text("사진")
                .font(.app(.subHeadline1))
                .foregroundStyle(.textMain)

            // PhotosPicker
            PhotosPicker(
                selection: $selectedPhotos,
                maxSelectionCount: 5,
                matching: .images
            ) {
                if selectedImages.isEmpty {
                    // 이미지 없을 때: 플레이스홀더
                    imagePlaceholder
                } else {
                    // 이미지 있을 때: 그리드
                    imageGridView
                }
            }
            .onChange(of: selectedPhotos) { _, newItems in
                loadPhotos(from: newItems)
            }
        }
    }

    /// 이미지 플레이스홀더 (선택 전)
    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: Spacing.radiusMedium)
            .fill(Color.gray.opacity(0.1))
            .frame(height: 200)
            .overlay {
                VStack(spacing: Spacing.small) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundStyle(.textSub)

                    Text("사진 선택 (최대 5장)")
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
            ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                imageGridCell(image: image, index: index)
            }

            // 5장 미만일 때 추가 버튼
            if selectedImages.count < 5 {
                addMoreButton
            }
        }
    }

    /// 이미지 그리드 셀
    private func imageGridCell(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSmall))

            // 삭제 버튼
            Button {
                withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                    selectedImages.remove(at: index)
                    selectedPhotos.remove(at: index)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 24, height: 24)
                    )
            }
            .padding(Spacing.xSmall)
        }
    }

    /// 추가 버튼
    private var addMoreButton: some View {
        RoundedRectangle(cornerRadius: Spacing.radiusSmall)
            .fill(Color.gray.opacity(0.1))
            .frame(height: 120)
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
                if content.isEmpty {
                    Text("무슨 일이 일어나고 있나요?")
                        .font(.app(.content2))
                        .foregroundStyle(.textSub)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }

                TextEditor(text: $content)
                    .font(.app(.content2))
                    .foregroundStyle(.textMain)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 150)
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
                Text("\(content.count)/500")
                    .font(.app(.subContent2))
                    .foregroundStyle(content.count > 500 ? .red : .textSub)
            }
        }
    }

    // MARK: - Helper Methods

    /// 폼 유효성 검사
    private var isFormValid: Bool {
        // 내용이 있고, 500자 이하, 이미지가 1장 이상
        !content.isEmpty && content.count <= 500 && !selectedImages.isEmpty
    }

    /// 사진 로드 (PhotosPickerItem -> UIImage)
    private func loadPhotos(from items: [PhotosPickerItem]) {
        selectedImages = []

        for item in items {
            item.loadTransferable(type: Data.self) { result in
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            selectedImages.append(image)
                        }
                    }
                case .failure(let error):
                    print("이미지 로드 실패: \(error)")
                }
            }
        }
    }

    /// 게시/수정 처리
    private func handleSubmit() {
        // TODO: 실제 API 연동
        switch mode {
        case .create:
            print("새 게시물 작성: \(content)")
            print("이미지 \(selectedImages.count)장")
        case .edit(let item):
            print("게시물 수정: \(item.id)")
            print("새 내용: \(content)")
        }

        // 햅틱 피드백
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        dismiss()
    }
}

// MARK: - Preview

#Preview("작성 모드") {
    FeedEditView(mode: .create)
}

#Preview("수정 모드") {
    FeedEditView(mode: .edit(MockFeedData.sampleFeeds[0]))
}
