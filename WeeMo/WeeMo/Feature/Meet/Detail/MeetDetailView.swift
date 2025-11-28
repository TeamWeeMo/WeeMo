//
//  MeetDetailView.swift
//  WeeMo
//
//  Created by 차지용 on 11/8/25.
//

import SwiftUI
import Kingfisher
import Alamofire

struct MeetDetailView: View {
    let postId: String
    @StateObject private var store = MeetDetailStore()
    @Environment(\.dismiss) private var dismiss
    @State private var showingChatAlert = false
    @State private var chatErrorMessage = ""
    @State private var navigateToChatRoom: ChatRoom? = nil

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
                    NavigationLink(value: "edit:\(meetDetail.postId)") {
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
        .alert("채팅 오류", isPresented: $showingChatAlert) {
            Button("확인") { }
        } message: {
            Text(chatErrorMessage)
        }
        .navigationDestination(item: $navigateToChatRoom) { chatRoom in
            ChatDetailView(room: chatRoom)
        }
    }

    // MARK: - Private Functions

    /// 채팅방 생성 또는 이동
    private func createChatRoom(with opponentUserId: String) {
        guard let meetDetail = store.state.meetDetail else { return }

        Task {
            do {
                print(" 채팅방 생성 시작. 상대방 ID: \(opponentUserId)")

                let networkService = NetworkService()

                // 먼저 원본 응답을 확인해보기 위해 Data로 받기
                let request = ChatRouter.createOrFetchRoom(opponentUserId: opponentUserId)
                let dataResponse = try await AF.request(request)
                    .validate()
                    .serializingData()
                    .value

                if let jsonString = String(data: dataResponse, encoding: .utf8) {
                    print(" 서버 응답 원본: \(jsonString)")
                }

                // 일단 ChatRoomDTO로 시도해보기
                let response = try JSONDecoder().decode(ChatRoomDTO.self, from: dataResponse)

                print("채팅방 생성 API 성공. 응답: \(response)")

                await MainActor.run {
                    // 서버에서 받은 실제 데이터로 ChatRoom 생성
                    let participants = response.participants.map { userDTO in
                        User(
                            userId: userDTO.userId,
                            nickname: userDTO.nick,
                            profileImageURL: userDTO.profileImage
                        )
                    }

                    var lastChat: ChatMessage? = nil
                    if let lastChatDTO = response.lastChat {
                        let sender = User(
                            userId: lastChatDTO.sender.userId,
                            nickname: lastChatDTO.sender.nick,
                            profileImageURL: lastChatDTO.sender.profileImage
                        )
                        lastChat = ChatMessage(
                            id: lastChatDTO.chatId,
                            roomId: lastChatDTO.roomId,
                            content: lastChatDTO.content,
                            createdAt: ISO8601DateFormatter().date(from: lastChatDTO.createdAt) ?? Date(),
                            sender: sender,
                            files: lastChatDTO.files
                        )
                    }

                    let chatRoom = ChatRoom(
                        id: response.roomId,
                        participants: participants,
                        lastChat: lastChat,
                        createdAt: ISO8601DateFormatter().date(from: response.createdAt) ?? Date(),
                        updatedAt: ISO8601DateFormatter().date(from: response.updatedAt) ?? Date()
                    )

                    navigateToChatRoom = chatRoom

                    print("채팅방 생성 완료. 방 ID: \(response.roomId)")
                }
            } catch {
                print(" 채팅방 생성 실패: \(error)")
                if let afError = error as? AFError {
                    print(" AFError details: \(afError)")
                }

                await MainActor.run {
                    chatErrorMessage = "채팅방 생성에 실패했습니다: \(error.localizedDescription)"
                    showingChatAlert = true
                }
            }
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

                                // 채팅하기 버튼 (본인이 아닌 경우에만 표시)
                                if let currentUserId = TokenManager.shared.userId,
                                   currentUserId != meetDetail.creator.userId {
                                    Button(action: {
                                        createChatRoom(with: meetDetail.creator.userId)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "message")
                                                .font(.system(size: 14, weight: .medium))
                                            Text("채팅")
                                                .font(.app(.subContent1))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.wmMain)
                                        .cornerRadius(16)
                                    }
                                }
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
