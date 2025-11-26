//
//  ImageGalleryView.swift
//  WeeMo
//
//  Created by Claude on 11/25/25.
//

import SwiftUI
import Kingfisher

// MARK: - Image Gallery View

struct ImageGalleryView: View {
    let images: [String]
    let startIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int

    init(images: [String], startIndex: Int = 0) {
        self.images = images
        self.startIndex = startIndex
        self._currentIndex = State(initialValue: startIndex)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if !images.isEmpty {
                    TabView(selection: $currentIndex) {
                        ForEach(images.indices, id: \.self) { index in
                            galleryImageView(for: images[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .ignoresSafeArea()

                    VStack {
                        // 상단 네비게이션
                        HStack {
                            Button("완료") {
                                dismiss()
                            }
                            .foregroundStyle(.white)
                            .font(.app(.content1))

                            Spacer()

                            Text("\(currentIndex + 1) / \(images.count)")
                                .foregroundStyle(.white)
                                .font(.app(.content2))
                        }
                        .padding()

                        Spacer()
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func galleryImageView(for imageURL: String) -> some View {
        KFImage(URL(string: FileRouter.fileURL(from: imageURL)))
            .withAuthHeaders()
            .placeholder {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
            .onSuccess { result in
                print("✅ 갤러리 이미지 로딩 성공: \(FileRouter.fileURL(from: imageURL))")
            }
            .onFailure { error in
                print("❌ 갤러리 이미지 로딩 실패: \(FileRouter.fileURL(from: imageURL)), 에러: \(error)")
            }
            .retry(maxCount: 3, interval: .seconds(1))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipped()
    }
}
