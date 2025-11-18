//
//  CommentBottomSheet.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/16/25.
//

import SwiftUI
import Kingfisher

// MARK: - Comment Bottom Sheet

/// 인스타그램 스타일의 댓글 바텀 시트
struct CommentBottomSheet: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var store: CommentStore
    @FocusState private var isInputFocused: Bool

    // MARK: - Initializer

    init(postId: String, networkService: NetworkServiceProtocol = NetworkService()) {
        self.store = CommentStore(postId: postId, networkService: networkService)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 댓글 목록
                commentListView

                Divider()

                // 댓글 입력창
                commentInputView
            }
            .background(.wmBg)
            .navigationTitle("댓글")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                    .foregroundStyle(.textMain)
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Subviews

    /// 댓글 목록
    private var commentListView: some View {
        Group {
            if store.state.isLoading {
                LoadingView(message: "댓글을 불러오는 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.state.isEmpty {
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right",
                    title: "댓글이 없습니다",
                    message: "첫 댓글을 작성해보세요!"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Spacing.base) {
                        ForEach(store.state.comments) { comment in
                            CommentRow(comment: comment)
                                .padding(.horizontal, Spacing.base)
                        }
                    }
                    .padding(.vertical, Spacing.base)
                }
                .refreshable {
                    store.send(.refreshComments)
                }
            }
        }
    }

    /// 댓글 입력창 (바텀 고정)
    private var commentInputView: some View {
        HStack(spacing: Spacing.medium) {
            // 텍스트 입력
            TextField("댓글을 입력하세요...", text: Binding(
                get: { store.state.commentText },
                set: { store.send(.updateComment($0)) }
            ))
            .focused($isInputFocused)
            .textFieldStyle(.plain)
            .padding(Spacing.small)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            // 전송 버튼
            Button {
                store.send(.submitComment)
                isInputFocused = false
            } label: {
                Text("게시")
                    .font(.app(.subHeadline2))
                    .foregroundStyle(store.state.canSubmit ? .wmMain : .textSub)
            }
            .disabled(!store.state.canSubmit)
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.medium)
        .background(.wmBg)
    }
}

// MARK: - Comment Row

/// 댓글 행 (프로필 + 댓글 내용)
struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            // 프로필 이미지
            KFImage(URL(string: FileRouter.fileURL(from: comment.creator.profileImageURL ?? "")))
                .profileImageSetup()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipShape(Circle())

            // 댓글 내용
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                // 닉네임
                Text(comment.creator.nickname)
                    .font(.app(.subHeadline2))
                    .foregroundStyle(.textMain)

                // 댓글 텍스트
                Text(comment.content)
                    .font(.app(.content2))
                    .foregroundStyle(.textMain)
                    .fixedSize(horizontal: false, vertical: true)

                // 작성 시간
                Text(comment.createdAt.timeAgoString())
                    .font(.app(.subContent2))
                    .foregroundStyle(.textSub)
            }

            Spacer()
        }
    }
}
