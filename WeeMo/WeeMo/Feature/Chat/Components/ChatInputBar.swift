//
//  ChatInputBar.swift
//  WeeMo
//
//  Created by 차지용 on 11/25/25.
//

import SwiftUI
import PhotosUI

// MARK: - Chat Input Bar

struct ChatInputBar: View {
    @ObservedObject var store: ChatDetailStore
    @Binding var selectedPhotos: [PhotosPickerItem]

    var body: some View {
        VStack(spacing: 0) {
            // 선택된 이미지 미리보기 (더 이상 사용하지 않음 - 즉시 전송)
            // selectedImagesPreview

            // 플러스 메뉴
            if store.state.showPlusMenu {
                plusMenuView
            }

            // 입력창
            inputFieldView
        }
        .background(.wmBg)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(Color.gray.opacity(0.3)),
            alignment: .top
        )
    }

    // MARK: - Subviews

    private var plusMenuView: some View {
        HStack {
            PhotosPicker(
                selection: $selectedPhotos,
                maxSelectionCount: 5,
                matching: .images
            ) {
                VStack(spacing: 4) {
                    Circle()
                        .fill(Color("wmMain"))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.white)
                                .font(.system(size: 18))
                        }

                    Text("사진")
                        .font(.app(.subContent2))
                        .foregroundStyle(.textSub)
                }
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.small)
    }

    private var inputFieldView: some View {
        HStack(alignment: .bottom, spacing: Spacing.small) {
            // 플러스 버튼
            Button {
                store.state.showPlusMenu.toggle()
            } label: {
                Circle()
                    .fill(store.state.showPlusMenu ? Color("wmMain") : .gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: store.state.showPlusMenu ? "xmark" : "plus")
                            .foregroundStyle(store.state.showPlusMenu ? .white : .gray)
                            .font(.system(size: 16, weight: .medium))
                    }
            }
            .buttonStyle(PlainButtonStyle())

            // 텍스트 입력창
            TextField("메시지를 입력하세요", text: $store.state.inputText, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusLarge))
                .lineLimit(1...5)

            // 전송 버튼
            if canSendContent {
                Button {
                    sendMessageWithContent()
                } label: {
                    Circle()
                        .fill(Color("wmMain"))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "arrow.up")
                                .foregroundStyle(.white)
                                .font(.system(size: 16, weight: .bold))
                        }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.medium)
    }

    // MARK: - Helper Methods

    /// 전송 가능한 텍스트가 있는지 확인 (이미지는 즉시 전송됨)
    private var canSendContent: Bool {
        let hasText = !store.state.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let notSending = !store.state.isSendingMessage

        return hasText && notSending
    }

    /// 텍스트 전송 (이미지는 즉시 전송되므로 텍스트만 처리)
    private func sendMessageWithContent() {
        let textContent = store.state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        print("🚀 sendMessageWithContent 호출됨")
        print("📝 텍스트: '\(textContent)'")

        // 텍스트가 있으면 텍스트 전송 (이미지는 이미 즉시 전송됨)
        if !textContent.isEmpty {
            print("📝 텍스트 전송")
            store.handle(.sendMessage(content: textContent))
        }
    }
}
