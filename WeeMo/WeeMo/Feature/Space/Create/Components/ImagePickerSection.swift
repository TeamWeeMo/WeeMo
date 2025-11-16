//
//  ImagePickerSection.swift
//  WeeMo
//
//  Created by Reimos on 11/16/25.
//

import SwiftUI
import PhotosUI

struct ImagePickerSection: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    
    let selectedImage: UIImage?
    let onImageRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("공간 이미지")
                .font(.app(.subHeadline2))
                .foregroundColor(Color("textMain"))

            if let selectedImage = selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(Spacing.radiusMedium)

                    Button(action: onImageRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .padding(Spacing.small)
                    }
                }
            } else {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    VStack(spacing: Spacing.small) {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(Color("textSub"))

                        Text("이미지 선택")
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
    }
}
