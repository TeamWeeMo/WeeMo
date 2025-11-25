//
//  ImagePickerSection.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/24/25.
//

import SwiftUI
import PhotosUI
import Kingfisher

// MARK: - Image Picker Section

/// 이미지 선택 섹션 (Feed, Meet 등에서 재사용)
/// //TODO: - ImagePickerSection 으로 수정필요
struct ImagePickerSection2: View {
    // MARK: - Configuration

    let title: String
    let maxCount: Int
    let layout: ImagePickerLayout

    // MARK: - Bindings

    @Binding var selectedImages: [UIImage]
    @Binding var selectedPhotoItems: [PhotosPickerItem]
    @Binding var existingImageURLs: [String]
    @Binding var shouldKeepExistingImages: Bool

    // MARK: - State

    @State private var isDisabled: Bool = false

    // MARK: - Computed Properties

    private var totalImageCount: Int {
        let existingCount = shouldKeepExistingImages ? existingImageURLs.count : 0
        return existingCount + selectedImages.count
    }

    private var remainingSlots: Int {
        max(0, maxCount - totalImageCount)
    }

    // MARK: - Initializer

    init(
        title: String = "사진",
        maxCount: Int = 5,
        layout: ImagePickerLayout = .horizontal,
        selectedImages: Binding<[UIImage]>,
        selectedPhotoItems: Binding<[PhotosPickerItem]>,
        existingImageURLs: Binding<[String]> = .constant([]),
        shouldKeepExistingImages: Binding<Bool> = .constant(true)
    ) {
        self.title = title
        self.maxCount = maxCount
        self.layout = layout
        self._selectedImages = selectedImages
        self._selectedPhotoItems = selectedPhotoItems
        self._existingImageURLs = existingImageURLs
        self._shouldKeepExistingImages = shouldKeepExistingImages
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // 섹션 타이틀
            Text("\(title) (최대 \(maxCount)장)")
                .font(.app(.subHeadline2))
                .foregroundStyle(.textMain)

            // 이미지 영역
            if totalImageCount > 0 {
                imagesView
            } else {
                emptyStateView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var imagesView: some View {
        switch layout {
        case .horizontal:
            horizontalImagesView
        case .grid:
            gridImagesView
        }
    }

    /// 가로 스크롤 레이아웃
    private var horizontalImagesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) {
                // 기존 이미지 (서버에서 로드)
                if shouldKeepExistingImages {
                    ForEach(Array(existingImageURLs.enumerated()), id: \.offset) { index, imageURL in
                        existingImageCell(imageURL: imageURL, index: index)
                    }
                }

                // 새로 선택한 이미지
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                    newImageCell(image: image, index: index)
                }

                // 추가 버튼
                if totalImageCount < maxCount {
                    addButton
                }
            }
            .padding(.horizontal, 1)
        }
    }

    /// 그리드 레이아웃
    private var gridImagesView: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Spacing.small),
                GridItem(.flexible(), spacing: Spacing.small),
                GridItem(.flexible(), spacing: Spacing.small)
            ],
            spacing: Spacing.small
        ) {
            // 기존 이미지
            if shouldKeepExistingImages {
                ForEach(Array(existingImageURLs.enumerated()), id: \.offset) { index, imageURL in
                    existingImageGridCell(imageURL: imageURL, index: index)
                }
            }

            // 새로 선택한 이미지
            ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                newImageGridCell(image: image, index: index)
            }

            // 추가 버튼
            if totalImageCount < maxCount {
                addGridButton
            }
        }
    }

    /// 빈 상태 (이미지 없음)
    private var emptyStateView: some View {
        PhotosPicker(
            selection: $selectedPhotoItems,
            maxSelectionCount: maxCount,
            matching: .images
        ) {
            VStack(spacing: Spacing.small) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 48))
                    .foregroundStyle(.textSub)

                Text("사진 선택 (최대 \(maxCount)장)")
                    .font(.app(.content2))
                    .foregroundStyle(.textSub)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
        }
        .disabled(isDisabled)
    }

    // MARK: - Horizontal Layout Cells

    /// 기존 이미지 셀 (가로 스크롤)
    private func existingImageCell(imageURL: String, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            let fullImageURL = imageURL.hasPrefix("http") ? imageURL : FileRouter.fileURL(from: imageURL)
            if let encodedURL = fullImageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: encodedURL) {
                KFImage(url)
                    .withAuthHeaders()
                    .placeholder {
                        imagePlaceholder
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
            } else {
                imagePlaceholder
            }

            deleteButton {
                removeExistingImage(at: index)
            }
        }
    }

    /// 새 이미지 셀 (가로 스크롤)
    private func newImageCell(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))

            deleteButton {
                removeNewImage(at: index)
            }
        }
    }

    /// 추가 버튼 (가로 스크롤)
    private var addButton: some View {
        PhotosPicker(
            selection: $selectedPhotoItems,
            maxSelectionCount: remainingSlots,
            matching: .images
        ) {
            VStack(spacing: Spacing.xSmall) {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .foregroundStyle(.textSub)

                Text("추가")
                    .font(.app(.subContent1))
                    .foregroundStyle(.textSub)
            }
            .frame(width: 120, height: 120)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
        }
        .disabled(isDisabled)
    }

    // MARK: - Grid Layout Cells

    /// 기존 이미지 셀 (그리드)
    private func existingImageGridCell(imageURL: String, index: Int) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                let fullImageURL = imageURL.hasPrefix("http") ? imageURL : FileRouter.fileURL(from: imageURL)
                if let encodedURL = fullImageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: encodedURL) {
                    KFImage(url)
                        .withAuthHeaders()
                        .placeholder {
                            imagePlaceholder
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSmall))
                } else {
                    imagePlaceholder
                }

                deleteButton {
                    removeExistingImage(at: index)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// 새 이미지 셀 (그리드)
    private func newImageGridCell(image: UIImage, index: Int) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusSmall))

                deleteButton {
                    removeNewImage(at: index)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// 추가 버튼 (그리드)
    private var addGridButton: some View {
        PhotosPicker(
            selection: $selectedPhotoItems,
            maxSelectionCount: remainingSlots,
            matching: .images
        ) {
            RoundedRectangle(cornerRadius: Spacing.radiusSmall)
                .fill(Color.gray.opacity(0.1))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: 32))
                        .foregroundStyle(.textSub)
                }
        }
        .disabled(isDisabled)
    }

    // MARK: - Common Components

    /// 이미지 플레이스홀더
    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: Spacing.radiusMedium)
            .fill(Color.gray.opacity(0.2))
            .frame(width: 120, height: 120)
            .overlay {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
            }
    }

    /// 삭제 버튼
    private func deleteButton(action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                action()
            }
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.white)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 24, height: 24)
                )
        }
        .padding(Spacing.xSmall)
    }

    // MARK: - Actions

    private func removeExistingImage(at index: Int) {
        existingImageURLs.remove(at: index)
        if existingImageURLs.isEmpty {
            shouldKeepExistingImages = false
        }
    }

    private func removeNewImage(at index: Int) {
        selectedImages.remove(at: index)
        if index < selectedPhotoItems.count {
            selectedPhotoItems.remove(at: index)
        }
    }

    // MARK: - Modifiers

    func disabled(_ disabled: Bool) -> ImagePickerSection2 {
        var copy = self
        copy.isDisabled = disabled
        return copy
    }
}

// MARK: - Layout Type

enum ImagePickerLayout {
    case horizontal // 가로 스크롤
    case grid       // 그리드 (3열)
}

// MARK: - Preview

#Preview("가로 스크롤") {
    @Previewable @State var images: [UIImage] = []
    @Previewable @State var items: [PhotosPickerItem] = []
    @Previewable @State var existing: [String] = []
    @Previewable @State var keep: Bool = true

    ImagePickerSection2(
        title: "모임 이미지",
        maxCount: 5,
        layout: .horizontal,
        selectedImages: $images,
        selectedPhotoItems: $items,
        existingImageURLs: $existing,
        shouldKeepExistingImages: $keep
    )
    .padding()
}

#Preview("그리드") {
    @Previewable @State var images: [UIImage] = []
    @Previewable @State var items: [PhotosPickerItem] = []
    @Previewable @State var existing: [String] = []
    @Previewable @State var keep: Bool = true

    ImagePickerSection2(
        title: "사진",
        maxCount: 5,
        layout: .grid,
        selectedImages: $images,
        selectedPhotoItems: $items,
        existingImageURLs: $existing,
        shouldKeepExistingImages: $keep
    )
    .padding()
}
