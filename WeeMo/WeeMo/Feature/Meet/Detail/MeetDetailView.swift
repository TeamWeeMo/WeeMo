//
//  MeetDetailView.swift
//  WeeMo
//
//  Created by 차지용 on 11/8/25.
//

import SwiftUI
import Kingfisher

struct MeetDetailView: View {
    let postId: String
    @StateObject private var store = MeetDetailStore()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            if store.state.isLoading {
                VStack {
                    ProgressView("모임 정보를 불러오는 중...")
                        .padding()
                    Spacer()
                }
            } else if let errorMessage = store.state.errorMessage {
                VStack(spacing: 16) {
                    Text("오류가 발생했습니다")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("다시 시도") {
                        store.handle(.retryLoadMeetDetail)
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
                .padding()
            } else if let meetDetail = store.state.meetDetail {
                meetDetailContent(meetDetail)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("모임 상세")
        .navigationBarBackButtonHidden(false)
        .toolbar {
            if let meetDetail = store.state.meetDetail,
               let currentUserId = TokenManager.shared.userId,
               currentUserId == meetDetail.creator.userId {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: MeetEditView(editingPostId: meetDetail.postId)) {
                        Text("수정")
                            .font(.app(.content2))
                            .foregroundColor(Color.wmMain)
                    }
                }
            }
        }
        .background(Color("wmBg"))
        .onAppear {
            store.handle(.loadMeetDetail(postId: postId))
        }
    }

    @ViewBuilder
    private func meetDetailContent(_ meetDetail: MeetDetail) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // 이미지 갤러리
                    MeetImageGallery(imageNames: meetDetail.imageNames)

                    // 제목과 D-day를 이미지 아래에 배치
                    HStack {
                        Text(meetDetail.title)
                            .font(.app(.headline2))
                            .fontWeight(.bold)
                            .foregroundColor(Color("textMain"))
                            .lineLimit(2)

                        Spacer()

                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.wmMain)
                                .frame(width: 50, height: 28)
                            Text(meetDetail.daysLeft)
                                .font(.app(.subContent1))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // 주최자 정보
                    VStack(alignment: .leading, spacing: 16) {
                        Button(action: {
                            // TODO: 주최자 프로필 페이지로 이동
                            print("주최자 프로필 클릭: \(meetDetail.creator.nickname)")
                        }) {
                            HStack {
                                if let profileImage = meetDetail.creator.profileImage, !profileImage.isEmpty {
                                    let fullImageURL = profileImage.hasPrefix("http") ? profileImage : FileRouter.fileURL(from: profileImage)
                                    if let encodedURL = fullImageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                                       let url = URL(string: encodedURL) {
                                        KFImage(url)
                                            .withAuthHeaders()
                                            .placeholder {
                                                Circle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 40, height: 40)
                                                    .overlay(
                                                        Text(String(meetDetail.creator.nickname.prefix(1)))
                                                            .font(.app(.content2))
                                                            .fontWeight(.medium)
                                                    )
                                            }
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Text(String(meetDetail.creator.nickname.prefix(1)))
                                                    .font(.app(.content2))
                                                    .fontWeight(.medium)
                                            )
                                    }
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text(String(meetDetail.creator.nickname.prefix(1)))
                                                .font(.app(.content2))
                                                .fontWeight(.medium)
                                        )
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("주최자")
                                        .font(.app(.subContent1))
                                        .foregroundColor(Color("textSub"))
                                    Text(meetDetail.creator.nickname)
                                        .font(.app(.content2))
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("textMain"))
                                }

                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)

                    Divider()

                    // 모임 정보
                    VStack(alignment: .leading, spacing: 20) {
                        InfoRow(icon: "calendar", title: "일정", content: meetDetail.date)

                        InfoRow(icon: "location", title: "장소", content: meetDetail.location.isEmpty ? "장소 미정" : meetDetail.location)

                        InfoRow(icon: "dollarsign.circle", title: "참가비용", content: meetDetail.price, isBlue: true)

                        InfoRow(icon: "person.2", title: "참여 인원", content: "\(meetDetail.currentParticipants) / \(meetDetail.capacity)명")

                        InfoRow(icon: "person.crop.circle", title: "참가 조건", content: meetDetail.gender)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)

                    Divider()

                    // 모임 소개
                    VStack(alignment: .leading, spacing: 12) {
                        Text("모임 소개")
                            .font(.app(.subHeadline2))
                            .fontWeight(.semibold)
                            .foregroundColor(Color("textMain"))

                        Text(meetDetail.content)
                            .font(.app(.content2))
                            .foregroundColor(Color("textSub"))
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)

                    // 참가하기 버튼
                    Button(action: {
                        store.handle(.joinMeet(postId: meetDetail.postId))
                    }) {
                        if store.state.isJoining {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color.wmMain)
                                .cornerRadius(8)
                        } else {
                            Text("\(meetDetail.price) 참가하기")
                                .font(.app(.content1))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(store.state.hasJoined ? Color.gray : Color.wmMain)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(store.state.isJoining || store.state.hasJoined)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 34)

                    if let joinError = store.state.joinErrorMessage {
                        Text(joinError)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("모임 상세")
        .background(Color("wmBg"))
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let content: String
    var isBlue: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.app(.content2))
                    .foregroundColor(Color("textSub"))

                Text(content)
                    .font(.app(.content2))
                    .foregroundColor(isBlue ? .blue : Color("textMain"))
                    .fontWeight(isBlue ? .medium : .regular)
            }

            Spacer()
        }
    }
}

// MARK: - 모임 이미지 갤러리
struct MeetImageGallery: View {
    let imageNames: [String]
    @State private var currentIndex = 0

    var body: some View {
        ZStack {
            if !imageNames.isEmpty {
                TabView(selection: $currentIndex) {
                    ForEach(Array(imageNames.enumerated()), id: \.offset) { index, imageName in
                        let fullImageURL = imageName.hasPrefix("http") ? imageName : FileRouter.fileURL(from: imageName)
                        if let encodedURL = fullImageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                           let url = URL(string: encodedURL) {
                            KFImage(url)
                                .withAuthHeaders()
                                .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 400, height: 400)))
                                .placeholder {
                                    RoundedRectangle(cornerRadius: 0)
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay(
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                        )
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 250)
                                .clipped()
                                .tag(index)
                        } else {
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 250)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                )
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 250)

                // 이미지 인디케이터
                if imageNames.count > 1 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 8) {
                                ForEach(0..<imageNames.count, id: \.self) { index in
                                    Circle()
                                        .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(20)
                            Spacer()
                        }
                        .padding(.bottom, 20)
                    }
                }
            } else {
                // 이미지가 없을 때
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 250)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
            }
        }
        .frame(height: 250)
    }
}

#Preview {
    MeetDetailView(postId: "sample-post-id")
}
