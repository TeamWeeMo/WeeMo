//
//  ImagePickerSection.swift
//  WeeMo
//
//  Created by Reimos on 11/16/25.
//

import SwiftUI
import PhotosUI

struct ImagePickerSection: View {
    @Binding var selectedPhotoItems: [PhotosPickerItem]

    let selectedImages: [UIImage]
    let maxImageCount: Int
    let onImageRemove: (Int) -> Void

    private var canAddMoreImages: Bool {
        selectedImages.count < maxImageCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("공간 이미지")
                    .font(.app(.subHeadline2))
                    .foregroundColor(Color("textMain"))

                Spacer()

                Text("\(selectedImages.count)/\(maxImageCount)")
                    .font(.app(.content2))
                    .foregroundColor(Color("textSub"))
            }

            // 가로 스크롤 이미지 리스트
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.medium) {
                    // 선택된 이미지들
                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipped()
                                .cornerRadius(Spacing.radiusMedium)
                            
                            
                            Button {
                                onImageRemove(index)
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
                            maxSelectionCount: maxImageCount - selectedImages.count,
                            matching: .images
                        ) {
                            VStack(spacing: Spacing.small) {
                                Image(systemName: "plus")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color("textSub"))

                                Text("추가")
                                    .font(.app(.content2))
                                    .foregroundColor(Color("textSub"))
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
            if selectedImages.isEmpty {
                Text("최대 \(maxImageCount)개의 이미지를 선택할 수 있습니다")
                    .font(.app(.content3))
                    .foregroundColor(Color("textSub"))
                    .padding(.top, Spacing.xSmall)
            }
        }
    }
}
