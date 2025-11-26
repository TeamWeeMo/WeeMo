//
//  ChatBubbleView.swift
//  WeeMo
//
//  Created by 차지용 on 11/25/25.
//

import SwiftUI
import Kingfisher

// MARK: - Chat Bubble Component

/// 채팅 말풍선 컴포넌트
struct ChatBubble: View {
    let message: ChatMessage
    let isMine: Bool
    let showTime: Bool
    let onImageGalleryTap: (([String], Int) -> Void)?
    let onProfileTap: ((User) -> Void)?

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.small) {
            if isMine {
                // 내 메시지: 오른쪽 정렬
                Spacer(minLength: 60)
                timeLabel
                bubbleContent
            } else {
                // 상대방 메시지: 왼쪽 정렬
                profileImageView
                VStack(alignment: .leading, spacing: 2) {
                    // 상대방 이름
                    Text(message.sender.nickname)
                        .font(.app(.subContent2))
                        .foregroundStyle(.textSub)
                        .padding(.leading, 4)

                    HStack(alignment: .bottom, spacing: Spacing.small) {
                        bubbleContent
                        timeLabel
                    }
                }
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, Spacing.base)
    }

    // MARK: - Subviews

    private var profileImageView: some View {
        Button(action: {
            onProfileTap?(message.sender)
        }) {
            Group {
                if let profileURL = message.sender.profileImageURL,
                   let url = URL(string: profileURL) {
                    KFImage(url)
                        .placeholder {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 38, height: 38)
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.gray)
                                .font(.system(size: 20))
                        }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var bubbleContent: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: Spacing.xSmall) {
            if message.hasMedia {
                // 이미지/영상 메시지
                imageContentView
            }

            if !message.content.isEmpty {
                // 텍스트 메시지
                textContentView
            }
        }
    }

    private var timeLabel: some View {
        Group {
            if showTime {
                Text(message.createdAt.chatTimeString())
                    .font(.app(.subContent2))
                    .foregroundStyle(.textSub)
            }
        }
    }

    private var textContentView: some View {
        Text(message.content)
            .font(.app(.content2))
            .foregroundStyle(isMine ? .white : .textMain)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(isMine ? Color("wmMain") : Color("wmGray"))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
    }

    private var imageContentView: some View {
        ChatImageGrid(
            imageFiles: message.files,
            onImageTap: { images, index in
                onImageGalleryTap?(images, index)
            }
        )
    }
}

// MARK: - Chat Image Grid

struct ChatImageGrid: View {
    let imageFiles: [String]
    let onImageTap: (([String], Int) -> Void)?

    var body: some View {
        Group {
            switch imageFiles.count {
            case 1:
                singleImageView
            case 2:
                twoImagesView
            case 3:
                threeImagesView
            case 4...:
                fourOrMoreImagesView
            default:
                EmptyView()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
    }

    // MARK: - Image Layouts

    private var singleImageView: some View {
        ChatImageItem(
            imageURL: imageFiles[0],
            onTap: { onImageTap?(imageFiles, 0) }
        )
        .frame(maxWidth: 200, maxHeight: 200)
    }

    private var twoImagesView: some View {
        HStack(spacing: 2) {
            ForEach(Array(imageFiles.prefix(2).enumerated()), id: \.offset) { index, imageFile in
                ChatImageItem(
                    imageURL: imageFile,
                    onTap: { onImageTap?(imageFiles, index) }
                )
                .frame(width: 100, height: 100)
                .aspectRatio(1, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }

    private var threeImagesView: some View {
        HStack(spacing: 2) {
            ChatImageItem(
                imageURL: imageFiles[0],
                onTap: { onImageTap?(imageFiles, 0) }
            )
            .frame(width: 100, height: 100)
            .aspectRatio(1, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(spacing: 2) {
                ChatImageItem(
                    imageURL: imageFiles[1],
                    onTap: { onImageTap?(imageFiles, 1) }
                )
                .frame(width: 49, height: 49)
                .aspectRatio(1, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 4))

                ChatImageItem(
                    imageURL: imageFiles[2],
                    onTap: { onImageTap?(imageFiles, 2) }
                )
                .frame(width: 49, height: 49)
                .aspectRatio(1, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }

    private var fourOrMoreImagesView: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                ChatImageItem(
                    imageURL: imageFiles[0],
                    onTap: { onImageTap?(imageFiles, 0) }
                )
                .frame(width: 75, height: 75)
                .aspectRatio(1, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 4))

                ChatImageItem(
                    imageURL: imageFiles[1],
                    onTap: { onImageTap?(imageFiles, 1) }
                )
                .frame(width: 75, height: 75)
                .aspectRatio(1, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            HStack(spacing: 2) {
                ChatImageItem(
                    imageURL: imageFiles[2],
                    onTap: { onImageTap?(imageFiles, 2) }
                )
                .frame(width: 75, height: 75)
                .aspectRatio(1, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 4))

                ZStack {
                    ChatImageItem(
                        imageURL: imageFiles[3],
                        onTap: { onImageTap?(imageFiles, 3) }
                    )
                    .frame(width: 75, height: 75)
                    .aspectRatio(1, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                    if imageFiles.count > 4 {
                        Rectangle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 75, height: 75)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Text("+\(imageFiles.count - 4)")
                            .font(.app(.subContent1))
                            .foregroundStyle(.white)
                    }
                }
                .onTapGesture {
                    onImageTap?(imageFiles, 3)
                }
            }
        }
    }
}

// MARK: - Chat Image Item

struct ChatImageItem: View {
    let imageURL: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            KFImage(URL(string: FileRouter.fileURL(from: imageURL)))
                .withAuthHeaders()
                .placeholder {
                    RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            ProgressView()
                                .tint(.gray)
                        }
                }
                .onSuccess { result in
                    print("✅ 이미지 로딩 성공: \(FileRouter.fileURL(from: imageURL))")
                }
                .onFailure { error in
                    print("❌ 이미지 로딩 실패: \(FileRouter.fileURL(from: imageURL)), 에러: \(error)")
                }
                .retry(maxCount: 3, interval: .seconds(1))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        }
        .buttonStyle(PlainButtonStyle())
    }
}
