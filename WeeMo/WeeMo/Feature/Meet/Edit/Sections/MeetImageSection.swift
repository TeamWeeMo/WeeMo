//
//  MeetImageSection.swift
//  WeeMo
//
//  Created by 차지용 on 11/19/25.
//

import SwiftUI
import PhotosUI
import Kingfisher

struct MeetImageSection: View {
    @ObservedObject var store: MeetEditViewStroe

    private var totalImageCount: Int {
        let existingCount = store.shouldKeepExistingImages ? store.existingImageURLs.count : 0
        return existingCount + store.selectedImages.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("모임 이미지 (최대 5개)")
                .font(.app(.subHeadline2))
                .foregroundColor(Color("textMain"))

            if totalImageCount > 0 {
                allImagesView
            } else {
                emptyStateView
            }
        }
    }

    private var allImagesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) {
                // 기존 이미지들 표시 (유지하는 경우)
                if store.shouldKeepExistingImages {
                    ForEach(Array(store.existingImageURLs.enumerated()), id: \.offset) { index, imageURL in
                        existingImageItemView(imageURL: imageURL, index: index)
                    }
                }

                // 새로 선택한 이미지들 표시
                ForEach(Array(store.selectedImages.enumerated()), id: \.offset) { index, image in
                    newImageItemView(image: image, index: index)
                }

                // 추가 버튼 (최대 5개까지)
                if totalImageCount < 5 {
                    addMoreButton
                }
            }
            .padding(.horizontal, 1)
        }
    }

    private var selectedImagesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) {
                ForEach(Array(store.selectedImages.enumerated()), id: \.offset) { index, image in
                    newImageItemView(image: image, index: index)
                }

                if store.selectedImages.count < 5 {
                    addMoreButton
                }
            }
            .padding(.horizontal, 1)
        }
    }
    
    // 기존 이미지 표시 (서버에서 로드)
    private func existingImageItemView(imageURL: String, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            let fullImageURL = imageURL.hasPrefix("http") ? imageURL : FileRouter.fileURL(from: imageURL)
            if let encodedURL = fullImageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: encodedURL) {
                KFImage(url)
                    .withAuthHeaders()
                    .placeholder {
                        RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            )
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipped()
                    .cornerRadius(Spacing.radiusMedium)
            } else {
                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    )
            }

            // 기존 이미지 삭제 버튼
            Button(action: {
                store.existingImageURLs.remove(at: index)
                if store.existingImageURLs.isEmpty {
                    store.shouldKeepExistingImages = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .padding(4)
            }
        }
    }

    // 새로 선택한 이미지 표시
    private func newImageItemView(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 120, height: 120)
                .clipped()
                .cornerRadius(Spacing.radiusMedium)

            Button(action: {
                store.selectedImages.remove(at: index)
                store.selectedPhotoItems.remove(at: index)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .padding(4)
            }
        }
    }

    // 레거시 함수 (하위 호환성용)
    private func imageItemView(image: UIImage, index: Int) -> some View {
        newImageItemView(image: image, index: index)
    }
    
    private var addMoreButton: some View {
        PhotosPicker(selection: $store.selectedPhotoItems, maxSelectionCount: 5 - totalImageCount, matching: .images) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .foregroundColor(Color("textSub"))
                
                Text("추가")
                    .font(.app(.subContent1))
                    .foregroundColor(Color("textSub"))
            }
            .frame(width: 120, height: 120)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(Spacing.radiusMedium)
        }
    }
    
    private var emptyStateView: some View {
        PhotosPicker(selection: $store.selectedPhotoItems, maxSelectionCount: 5, matching: .images) {
            VStack(spacing: Spacing.small) {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(Color("textSub"))
                
                Text("이미지 선택 (최대 5개)")
                    .font(.app(.content1))
                    .foregroundColor(Color("textSub"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(Spacing.radiusMedium)
        }
    }
}
