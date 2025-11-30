//
//  SpaceImageView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/27/25.
//

import SwiftUI
import Kingfisher

/// 공간 이미지 뷰 (URL, 사이즈, 플레이스홀더 지원)
struct SpaceImageView: View {
    let imageURL: String?
    let size: CGFloat
    let cornerRadius: CGFloat
    let placeholderIcon: String

    init(
        imageURL: String?,
        size: CGFloat = 80,
        cornerRadius: CGFloat = Spacing.radiusSmall,
        placeholderIcon: String = "building.2"
    ) {
        self.imageURL = imageURL
        self.size = size
        self.cornerRadius = cornerRadius
        self.placeholderIcon = placeholderIcon
    }

    var body: some View {
        Group {
            if let imageURL = imageURL, !imageURL.isEmpty {
                KFImage(URL(string: FileRouter.fileURL(from: imageURL)))
                    .withAuthHeaders()
                    .placeholder {
                        WeeMoImagePlaceholder(
                            systemImage: placeholderIcon,
                            size: size,
                            cornerRadius: cornerRadius
                        )
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                WeeMoImagePlaceholder(
                    systemImage: placeholderIcon,
                    size: size,
                    cornerRadius: cornerRadius
                )
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SpaceImageView(imageURL: nil, size: 80)
        SpaceImageView(imageURL: nil, size: 60)
        SpaceImageView(imageURL: "sample.jpg", size: 100)
    }
    .padding()
}
