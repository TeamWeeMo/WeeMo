//
//  MeetImageSection.swift
//  WeeMo
//
//  Created by 차지용 on 11/19/25.
//

import SwiftUI
import PhotosUI
struct MeetImageSection: View {
    @ObservedObject var store: MeetEditViewStroe
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("모임 이미지 (최대 5개)")
                .font(.app(.subHeadline2))
                .foregroundColor(Color("textMain"))
            
            if !store.selectedImages.isEmpty {
                selectedImagesView
            } else {
                emptyStateView
            }
        }
    }
    
    private var selectedImagesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) {
                ForEach(Array(store.selectedImages.enumerated()), id: \.offset) { index, image in
                    imageItemView(image: image, index: index)
                }
                
                if store.selectedImages.count < 5 {
                    addMoreButton
                }
            }
            .padding(.horizontal, 1)
        }
    }
    
    private func imageItemView(image: UIImage, index: Int) -> some View {
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
    
    private var addMoreButton: some View {
        PhotosPicker(selection: $store.selectedPhotoItems, maxSelectionCount: 5 - store.selectedImages.count, matching: .images) {
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
