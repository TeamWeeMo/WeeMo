//
//  ReservedSpaceListView.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//  Renamed and enhanced by Watson22_YJ on 11/25/25.
//

import SwiftUI
import Kingfisher

// MARK: - Reserved Space List View

/// 예약한 공간 리스트를 표시하고 선택할 수 있는 View
struct ReservedSpaceListView: View {
    // MARK: - Properties

    @Bindable var store: MeetEditStore
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
                .background(.wmBg)
                .navigationTitle("예약한 공간")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarRole(.editor)
                .tint(.wmMain)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("완료") {
                            store.send(.confirmSpaceSelection)
                            dismiss()
                        }
                        .disabled(store.state.selectedSpace == nil)
                        .fontWeight(.semibold)
                        .foregroundStyle(store.state.selectedSpace != nil ? .wmMain : .textSub)
                    }
                }
                .onAppear {
                    if store.state.spaces.isEmpty {
                        store.send(.loadSpaces)
                    }
                }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if store.state.isLoadingSpaces {
            loadingView
        } else if let errorMessage = store.state.spacesErrorMessage {
            errorView(message: errorMessage)
        } else if store.state.spaces.isEmpty {
            emptyView
        } else {
            spaceListView
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("공간을 불러오는 중...")
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.medium) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.textSub)

            Text("오류가 발생했습니다")
                .font(.app(.subHeadline1))
                .foregroundStyle(.textMain)

            Text(message)
                .font(.app(.content2))
                .foregroundStyle(.textSub)
                .multilineTextAlignment(.center)

            Button("다시 시도") {
                store.send(.loadSpaces)
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: Spacing.medium) {
            Spacer()

            Image(systemName: "building.2")
                .font(.system(size: 48))
                .foregroundStyle(.textSub)

            Text("예약한 공간이 없습니다")
                .font(.app(.subHeadline1))
                .foregroundStyle(.textMain)

            Text("공간을 예약하고 모임을 만들어보세요")
                .font(.app(.content2))
                .foregroundStyle(.textSub)

            Spacer()
        }
    }

    private var spaceListView: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.medium) {
                ForEach(store.state.spaces) { space in
                    ReservedSpaceRowView(
                        space: space,
                        isSelected: store.state.selectedSpace?.id == space.id,
                        onTap: {
                            store.send(.selectSpace(space))
                        }
                    )
                }
            }
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.medium)
        }
    }
}

// MARK: - Reserved Space Row View

struct ReservedSpaceRowView: View {
    let space: Space
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // 공간 이미지
                spaceImage

                // 공간 정보
                VStack(alignment: .leading, spacing: 8) {
                    // 공간 이름
                    Text(space.title)
                        .font(.app(.content1))
                        .fontWeight(.semibold)
                        .foregroundColor(.textMain)
                        .lineLimit(1)

                    // 주소
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle")
                            .font(.system(size: 12))
                            .foregroundColor(.textSub)

                        Text(space.address)
                            .font(.app(.subContent2))
                            .foregroundColor(.textSub)
                            .lineLimit(1)
                    }
                    //TODO: - 상세주소 추가

                }

                Spacer()

                // 선택 체크마크
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.wmMain)
                        .font(.system(size: 24))
                }
            }
            .padding(Spacing.medium)
        }
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.wmMain : Color.clear, lineWidth: 2)
        )
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Space Image

    private var spaceImage: some View {
        Group {
            if let imageURL = space.imageURLs.first {
                let fullImageURL = imageURL.hasPrefix("http") ? imageURL : FileRouter.fileURL(from: imageURL)

                if let url = URL(string: fullImageURL) {
                    KFImage(url)
                        .withAuthHeaders()
                        .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 120, height: 120)))
                        .placeholder {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                )
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    imagePlaceholder
                }
            } else {
                imagePlaceholder
            }
        }
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 70, height: 70)
            .overlay(
                Image(systemName: "building.2")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            )
    }
}
