//
//  SpaceSelectionView.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI
import Combine

struct SpaceSelectionView: View {
    @Binding var selectedSpace: Space?
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = MeetEditViewModel()

    var body: some View {
        NavigationView {
            VStack {
                CustomNavigationBar(
                    onCancel: {
                        presentationMode.wrappedValue.dismiss()
                    },
                    onComplete: {
                        // 선택된 공간이 있으면 바인딩 업데이트
                        if let selected = viewModel.state.selectedSpace {
                            selectedSpace = selected
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                )

                content
            }
            .background(Color("wmBg"))
            .navigationBarHidden(true)
            .onAppear {
                viewModel.handle(.loadSpaces)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isLoadingSpaces {
            VStack {
                Spacer()
                ProgressView("공간을 불러오는 중...")
                    .frame(maxWidth: .infinity)
                Spacer()
            }
        } else if let errorMessage = viewModel.state.spacesErrorMessage {
            VStack(spacing: 16) {
                Spacer()
                Text("오류가 발생했습니다")
                    .font(.headline)
                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button("다시 시도") {
                    viewModel.handle(.retryLoadSpaces)
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .padding()
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.state.spaces) { space in
                        SpaceRowView(
                            space: space,
                            isSelected: viewModel.state.selectedSpace?.id == space.id,
                            onTap: {
                                viewModel.handle(.selectSpace(space))
                            }
                        )
                    }
                }
                .commonPadding()
            }
        }
    }
}

struct SpaceRowView: View {
    let space: Space
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(space.imageURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(space.title)
                        .font(.app(.content1))
                        .foregroundColor(Color("textMain"))

                    Text(space.address)
                        .font(.app(.content2))
                        .foregroundColor(Color("textSub"))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 24))
                }
            }
        }
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .buttonStyle(PlainButtonStyle())
    }
}
