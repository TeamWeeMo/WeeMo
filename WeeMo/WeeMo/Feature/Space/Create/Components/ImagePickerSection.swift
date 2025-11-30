//
//  ImagePickerSection.swift
//  WeeMo
//
//  Created by Reimos on 11/16/25.
//

import SwiftUI
import PhotosUI
import Kingfisher

struct ImagePickerSection: View {
    @Binding var selectedPhotoItems: [PhotosPickerItem]

    let existingImageURLs: [String]  // 기존 서버 이미지 URL
    let selectedImages: [UIImage]     // 새로 선택한 이미지
    let maxImageCount: Int
    let onExistingImageRemove: (Int) -> Void  // 기존 이미지 삭제
    let onNewImageRemove: (Int) -> Void       // 새 이미지 삭제

    private var totalImageCount: Int {
        existingImageURLs.count + selectedImages.count
    }

    private var canAddMoreImages: Bool {
        totalImageCount < maxImageCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("공간 이미지")
                    .font(.app(.subHeadline2))
                    .foregroundColor(.textMain)

                Spacer()

                Text("\(totalImageCount)/\(maxImageCount)")
                    .font(.app(.content2))
                    .foregroundColor(.textSub)
            }

            // 가로 스크롤 이미지 리스트
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.medium) {
                    // 기존 서버 이미지들
                    ForEach(Array(existingImageURLs.enumerated()), id: \.element) { index, urlString in
                        ZStack(alignment: .topTrailing) {
                            KFImage(URL(string: urlString))
                                .placeholder {
                                    Color.gray.opacity(0.2)
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipped()
                                .cornerRadius(Spacing.radiusMedium)

                            // 삭제 버튼
                            Button {
                                onExistingImageRemove(index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                                    .padding(Spacing.xSmall)
                            }
                        }
                    }

                    // 새로 선택한 이미지들
                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipped()
                                .cornerRadius(Spacing.radiusMedium)

                            // 삭제 버튼
                            Button {
                                onNewImageRemove(index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                                    .padding(Spacing.xSmall)
                            }
                        }
                    }

                    // 이미지 추가 버튼
                    if canAddMoreImages {
                        PhotosPicker(
                            selection: $selectedPhotoItems,
                            maxSelectionCount: maxImageCount - totalImageCount,
                            matching: .images
                        ) {
                            VStack(spacing: Spacing.small) {
                                Image(systemName: "plus")
                                    .font(.system(size: 32))
                                    .foregroundColor(.textSub)

                                Text("추가")
                                    .font(.app(.content2))
                                    .foregroundColor(.textSub)
                            }
                            .frame(width: 120, height: 120)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(Spacing.radiusMedium)
                        }
                    }
                }
            }
            .frame(height: 120)

            // 이미지가 없을 때 안내 텍스트
            if totalImageCount == 0 {
                Text("최대 \(maxImageCount)개의 이미지를 선택할 수 있습니다")
                    .font(.app(.content3))
                    .foregroundColor(.textSub)
                    .padding(.top, Spacing.xSmall)
            }
        }
    }
}
