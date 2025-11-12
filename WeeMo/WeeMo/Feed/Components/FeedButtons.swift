//
//  FeedButtons.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/9/25.
//

import SwiftUI
import Kingfisher

// MARK: - Feed 관련 버튼 컴포넌트들

/// 프로필 이미지 버튼
/// - 프로필 이미지 + 탭 액션
struct ProfileImageButton: View {
    let url: String?
    let size: CGFloat
    let action: () -> Void

    init(url: String?, size: CGFloat = 36, action: @escaping () -> Void) {
        self.url = url
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            if let profileURL = url, let url = URL(string: profileURL) {
                // URL이 있는 경우: Kingfisher로 로드
                KFImage(url)
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                // URL이 없는 경우: 기본 아이콘
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.gray)
                            .font(.system(size: size * 0.5))
                    }
            }
        }
    }
}

// MARK: - 인터랙션 버튼

/// 인터랙션 버튼 (좋아요, 댓글, 공유 등)
struct InteractionButton: View {
    let systemImage: String
    let size: CGFloat
    let action: () -> Void

    init(systemImage: String, size: CGFloat = 24, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size))
                .foregroundStyle(.textMain)
        }
    }
}

// MARK: - 좋아요 버튼

/// 좋아요 버튼 (애니메이션 + 햅틱 내장)
struct LikeButton: View {
    @Binding var isLiked: Bool
    @Binding var likeCount: Int

    var body: some View {
        Button {
            // 애니메이션과 함께 상태 변경
            withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                isLiked.toggle()
                likeCount += isLiked ? 1 : -1
            }

            // 햅틱 피드백
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        } label: {
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .font(.system(size: 24))
                .foregroundStyle(isLiked ? .red : .textMain) //TODO: - red 색상 추가 필요
                .scaleEffect(isLiked ? 1.2 : 1.0)
                .animation(.spring(duration: 0.3, bounce: 0.4), value: isLiked)
        }
    }
}

// MARK: - Preview

#Preview("ProfileImageButton") {
    VStack(spacing: 20) {
        ProfileImageButton(url: "https://i.pravatar.cc/150?img=1", size: 36) {
            print("프로필 탭")
        }

        ProfileImageButton(url: nil, size: 36) {
            print("기본 프로필 탭")
        }
    }
    .padding()
}

#Preview("InteractionButtons") {
    HStack(spacing: 16) {
        InteractionButton(systemImage: "heart") {
            print("좋아요")
        }

        InteractionButton(systemImage: "bubble.right") {
            print("댓글")
        }

        InteractionButton(systemImage: "paperplane") {
            print("공유")
        }

        InteractionButton(systemImage: "bookmark") {
            print("북마크")
        }
    }
    .padding()
}

#Preview("LikeButton") {
    struct LikeButtonPreview: View {
        @State private var isLiked = false
        @State private var likeCount = 42

        var body: some View {
            VStack(spacing: 20) {
                LikeButton(isLiked: $isLiked, likeCount: $likeCount)

                Text("좋아요 \(likeCount)개")
                    .font(.caption)
            }
            .padding()
        }
    }

    return LikeButtonPreview()
}
