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
    @StateObject private var viewModel = MeetDetailViewModel()

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.state.isLoading {
                VStack {
                    ProgressView("모임 정보를 불러오는 중...")
                        .padding()
                    Spacer()
                }
            } else if let errorMessage = viewModel.state.errorMessage {
                VStack(spacing: 16) {
                    Text("오류가 발생했습니다")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("다시 시도") {
                        viewModel.handle(.retryLoadMeetDetail)
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
                .padding()
            } else if let meetDetail = viewModel.state.meetDetail {
                meetDetailContent(meetDetail)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("모임 상세")
        .background(Color("wmBg"))
        .onAppear {
            viewModel.handle(.loadMeetDetail(postId: postId))
        }
    }

    @ViewBuilder
    private func meetDetailContent(_ meetDetail: MeetDetail) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // 제목과 주최자 정보
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(meetDetail.title)
                                .font(.app(.headline2))
                                .foregroundColor(Color("textMain"))

                            Spacer()

                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.wmMain)
                                    .frame(width: 40, height: 24)
                                Text(meetDetail.daysLeft)
                                    .font(.app(.subContent1))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.top, 20)

                        // 이미지를 제목 아래로 이동
                        ZStack {
                            if !meetDetail.imageName.isEmpty {
                                let fullImageURL = meetDetail.imageName.hasPrefix("http") ? meetDetail.imageName : FileRouter.fileURL(from: meetDetail.imageName)
                                if let encodedURL = fullImageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                                   let url = URL(string: encodedURL) {
                                    KFImage(url)
                                        .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 400, height: 400)))
                                        .requestModifier(AnyModifier { request in
                                            var newRequest = request
                                            if let sesacKey = Bundle.main.object(forInfoDictionaryKey: "SeSACKey") as? String {
                                                newRequest.setValue(sesacKey, forHTTPHeaderField: "SeSACKey")
                                            }
                                            newRequest.setValue(NetworkConstants.productId, forHTTPHeaderField: "ProductId")
                                            if let token = UserDefaults.standard.string(forKey: "accessToken") {
                                                newRequest.setValue(token, forHTTPHeaderField: "Authorization")
                                            }
                                            return newRequest
                                        })
                                        .placeholder {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(height: 150)
                                                .overlay(
                                                    Text("이미지 로딩중")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                )
                                        }
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 150)
                                        .cornerRadius(8)
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 150)
                                        .overlay(
                                            Text("이미지 없음")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        )
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 150)
                                    .overlay(
                                        Text("이미지 없음")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                        .frame(height: 150)
                        HStack {
                            if let profileImage = meetDetail.creator.profileImage, !profileImage.isEmpty {
                                KFImage(URL(string: profileImage))
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
                        viewModel.handle(.joinMeet(postId: meetDetail.postId))
                    }) {
                        if viewModel.state.isJoining {
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
                                .background(viewModel.state.hasJoined ? Color.gray : Color.wmMain)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(viewModel.state.isJoining || viewModel.state.hasJoined)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 34)

                    if let joinError = viewModel.state.joinErrorMessage {
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

#Preview {
    MeetDetailView(postId: "sample-post-id")
}
