//
//  ChatSocketIOManager.swift
//  WeeMo
//
//  Created by 차지용 on 11/23/25.
//

import Foundation
import Combine
import SocketIO

final class ChatSocketIOManager: ObservableObject {
    static let shared = ChatSocketIOManager()

    private var socketManager: SocketManager?
    private var socket: SocketIOClient?

    // 채팅 메시지 수신을 위한 Subject
    var chatMessageSubject = PassthroughSubject<ChatMessage, Never>()

    // 채팅방 리스트 업데이트를 위한 Subject
    var chatRoomUpdateSubject = PassthroughSubject<String, Never>()

    // 연결 상태
    @Published var isConnected: Bool = false

    var currentRoomId: String?

    private init() {}

    func openWebSocket(roomId: String) {
        print("🔌 Socket.IO 연결 시작: \(roomId)")
        print("🔌 현재 방: \(currentRoomId ?? "nil"), 연결상태: \(isConnected)")

        // 이미 같은 방에 연결된 경우 스킵
        if currentRoomId == roomId && isConnected && socket?.status == .connected {
            print("🔌 이미 연결된 방 (\(roomId)) - 스킵")
            return
        }

        // 기존 연결 해제하지 않고 방만 변경

        currentRoomId = roomId

        // Socket.IO URL 생성 - 서버 스펙에 맞게: http://host:port/chats-roomId
        guard let socketURL = buildSocketIOURL(roomId: roomId) else {
            print("❌ Invalid Socket.IO URL for room: \(roomId)")
            return
        }

        print("🔌 Connecting to Socket.IO: \(socketURL.absoluteString)")

        // Socket.IO 설정 (로그 활성화)
        var config: SocketIOClientConfiguration = [
            .log(true),
            .compress,
            .extraHeaders(getAuthHeaders())
        ]

        // SocketManager 생성
        socketManager = SocketManager(socketURL: socketURL, config: config)

        // 두 가지 방식 모두 시도
        let namespacePath = "/chats-\(roomId)"
        print("🔌 네임스페이스 연결 시도: \(namespacePath)")

        // 1. 특정 네임스페이스 시도
        socket = socketManager?.socket(forNamespace: namespacePath)

        // 2. 기본 네임스페이스도 동시 연결 시도
        let defaultSocket = socketManager?.defaultSocket
        print("🔌 기본 네임스페이스도 동시 연결 시도")

        // 이벤트 리스너 설정
        setupSocketEventListeners()

        // 기본 네임스페이스에도 chat 이벤트 리스너 추가
        defaultSocket?.on("chat") { [weak self] dataArray, ack in
            print("CHAT RECEIVED FROM DEFAULT NAMESPACE", dataArray, ack)
            print("📨 [DEFAULT NS] 기본 네임스페이스에서 'chat' 이벤트 수신: \(dataArray)")
            self?.handleReceivedMessage(dataArray)
        }

        // 연결 시작 (둘 다)
        socket?.connect()
        defaultSocket?.connect()

    }

    func closeWebSocket() {
        print("🔌 Socket.IO 연결 해제 요청")

        // 강제로 해제하지 말고 상태만 업데이트
        // socket?.disconnect()
        // socket = nil
        // socketManager = nil
        // currentRoomId = nil

        Task { @MainActor in
            self.isConnected = false
        }

        print("🔌 Socket.IO 연결은 유지하되 상태만 업데이트")
    }

    private func buildSocketIOURL(roomId: String) -> URL? {
        let baseURLString = NetworkConstants.baseURL
        guard let baseURL = URL(string: baseURLString) else {
            print("❌ Invalid base URL: \(baseURLString)")
            return nil
        }

        guard let host = baseURL.host else {
            print("❌ No host in base URL")
            return nil
        }

        let port = Int(NetworkConstants.port) ?? 0

        // 다양한 네임스페이스 형태 시도
        let possiblePaths = [
            "/chats-\(roomId)",
            "/chats/\(roomId)",
            "/chat/\(roomId)",
            "/rooms/\(roomId)",
            "" // 기본 네임스페이스
        ]

        // 원래 네임스페이스로 다시 시도
        let socketIOURLString = "http://\(host):\(port)"

        guard let socketIOURL = URL(string: socketIOURLString) else {
            print("❌ Failed to build Socket.IO URL")
            return nil
        }

        print("🔍 Socket.IO URL 시도: \(socketIOURL.absoluteString)")
        print("🔍 다른 가능한 네임스페이스들:")
        for path in possiblePaths {
            print("   - http://\(host):\(port)\(path)")
        }

        return socketIOURL
    }

    private func getAuthHeaders() -> [String: String] {
        var headers: [String: String] = [:]

        // SeSACKey 추가
        if let sesacKey = Bundle.main.object(forInfoDictionaryKey: "SeSACKey") as? String {
            headers["SeSACKey"] = sesacKey
            print("✅ SeSACKey added to Socket.IO")
        }

        // ProductId 추가
        headers["ProductId"] = NetworkConstants.productId
        print("✅ ProductId added to Socket.IO: \(NetworkConstants.productId)")

        // Authorization 토큰 추가
        if let token = TokenManager.shared.accessToken {
            headers["Authorization"] = token
            print("✅ Authorization token added to Socket.IO")
        }

        return headers
    }

    private func setupSocketEventListeners() {
        guard let socket = socket else { return }

        // 연결 이벤트
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            print("SOCKET IS CONNECTED", data, ack)
            print("🔌 [OFFICIAL] Socket.IO 연결 완료")

            // 즉시 연결 상태 업데이트
            self?.isConnected = true

            Task { @MainActor in
                self?.isConnected = true
            }

            // 연결 후 즉시 채팅방 참여
            if let roomId = self?.currentRoomId {
                print("🔌 [OFFICIAL] 연결 완료 - roomId: \(roomId)")
                print("🔌 [OFFICIAL] 'chat' 이벤트 수신 대기 중...")
            }
        }

        // 연결 해제 이벤트 - 문서에 따른 정확한 형식
        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("SOCKET IS DISCONNECTED", data, ack)
            print("🔌 [OFFICIAL] Socket.IO 연결 해제됨")
            Task { @MainActor in
                self?.isConnected = false
            }
        }

        // 에러 이벤트 - 문서에 따른 인증 오류 확인
        socket.on(clientEvent: .error) { data, ack in
            print("❌ Socket.IO 에러: \(data)")

            // 인증 관련 에러 확인
            if let errorData = data.first as? [String: Any],
               let message = errorData["message"] as? String {
                print("🚨 인증 에러 메시지: \(message)")

                if message.contains("SeSACKey") {
                    print("🔑 SeSACKey 검증 실패")
                } else if message.contains("ProductId") {
                    print("🆔 ProductId 검증 실패")
                } else if message.contains("액세스 토큰") || message.contains("accessToken") {
                    print("🎫 액세스 토큰 검증 실패")
                } else if message.contains("Forbidden") {
                    print("🚫 사용자 조회 권한 없음")
                } else if message.contains("Invalid namespace") {
                    print("📍 네임스페이스 형식 오류")
                } else if message.contains("채팅방을 찾을 수 없습니다") {
                    print("🏠 존재하지 않는 채팅방")
                } else if message.contains("채팅방 참여자가 아닙니다") {
                    print("👥 채팅방 참여 권한 없음")
                }
            }
        }

        // 모든 이벤트 수신 (완전한 디버깅)
        socket.onAny { event in
            print("📨 [ALL EVENTS] 이벤트: '\(event.event)' | 데이터: \(event.items ?? [])")
            print("📨 [EVENT TYPE] \(type(of: event.items?.first))")

            // 모든 이벤트에서 메시지 가능성 확인 (ping 제외)
            let systemEvents = ["ping", "pong", "statusChange", "websocketUpgrade", "connect", "disconnect"]
            if !systemEvents.contains(event.event) {
                print("🔍 [NON-SYSTEM EVENT] 커스텀 이벤트 상세 분석: '\(event.event)'")
                print("🔍 [DATA COUNT] 데이터 개수: \(event.items?.count ?? 0)")

                // 각 데이터 항목 상세 분석
                if let items = event.items {
                    for (index, item) in items.enumerated() {
                        print("🔍 [DATA \(index)] 타입: \(type(of: item)), 내용: \(item)")

                        // Dictionary 형태인지 확인
                        if let dict = item as? [String: Any] {
                            print("🔍 [DICT KEYS] \(dict.keys.sorted())")

                            // 메시지 관련 키들 확인
                            let messageKeys = ["content", "message", "text", "chat", "body", "data"]
                            for key in messageKeys {
                                if dict.keys.contains(key) {
                                    print("🎯 [POTENTIAL MESSAGE KEY] 발견된 메시지 키: '\(key)' = \(dict[key] ?? "nil")")
                                }
                            }

                            // chat_id, room_id 등 메시지 식별자 확인
                            let idKeys = ["chat_id", "chatId", "id", "room_id", "roomId", "sender", "user", "from"]
                            for key in idKeys {
                                if dict.keys.contains(key) {
                                    print("🆔 [MESSAGE ID KEY] 발견된 ID 키: '\(key)' = \(dict[key] ?? "nil")")
                                }
                            }
                        }
                    }
                }

                // 메시지 파싱 시도
                print("🧪 [PARSE ATTEMPT] 메시지 파싱 시도...")
                self.handleReceivedMessage(event.items ?? [])
            }

            // 에러 관련 이벤트들 특별 처리
            if event.event.contains("error") || event.event.contains("fail") || event.event.contains("deny") {
                print("🚨 [ERROR EVENT] 에러 이벤트 감지: \(event.event)")
                print("🚨 [ERROR DATA] 에러 상세: \(event.items ?? [])")

                // 문서에 있는 소켓 인증 에러 확인
                if let errorMessage = event.items?.first as? String {
                    print("🔍 [AUTH ERROR] 에러 메시지: \(errorMessage)")

                    if errorMessage.contains("새싹키(SeSACKey) 검증 실패") || errorMessage.contains("This service sesac_memolease only") {
                        print("🔑 [AUTH ERROR] SeSACKey 검증 실패")
                    } else if errorMessage.contains("서비스 식별자(ProductId)를 찾을 수 없습니다") {
                        print("🆔 [AUTH ERROR] ProductId 검증 실패")
                    } else if errorMessage.contains("액세스 토큰이 만료되었습니다") {
                        print("⏰ [AUTH ERROR] 액세스 토큰 만료")
                    } else if errorMessage.contains("인증할 수 없는 엑세스 토큰입니다") {
                        print("🎫 [AUTH ERROR] 유효하지 않은 accessToken")
                    } else if errorMessage.contains("Forbidden") {
                        print("🚫 [AUTH ERROR] user_id 조회 권한 없음")
                    } else if errorMessage.contains("Invalid namespace") {
                        print("📍 [SOCKET ERROR] 네임스페이스 형식 오류")
                    } else if errorMessage.contains("채팅방을 찾을 수 없습니다") {
                        print("🏠 [SOCKET ERROR] 존재하지 않는 채팅방")
                    } else if errorMessage.contains("채팅방 참여자가 아닙니다") {
                        print("👥 [SOCKET ERROR] 채팅방 참여 권한 없음")
                    }
                }
            }
        }

        // 메시지 수신 이벤트 - 서버에서 사용하는 이벤트 이름에 맞게 수정 필요
        socket.on("message") { [weak self] data, ack in
            print("📨 'message' 이벤트 수신: \(data)")
            self?.handleReceivedMessage(data)
        }

        // 문서에 따른 정확한 채팅 수신 이벤트
        socket.on("chat") { [weak self] dataArray, ack in
            print("CHAT RECEIVED", dataArray, ack)
            print("📨 [OFFICIAL] 'chat' 이벤트 수신: \(dataArray)")
            self?.handleReceivedMessage(dataArray)
        }

        // 서버에서 보낼 가능성이 높은 이벤트들 추가
        socket.on("send") { [weak self] data, ack in
            print("📨 'send' 이벤트 수신: \(data)")
            self?.handleReceivedMessage(data)
        }

        socket.on("receive") { [weak self] data, ack in
            print("📨 'receive' 이벤트 수신: \(data)")
            self?.handleReceivedMessage(data)
        }

        socket.on("newMessage") { [weak self] data, ack in
            print("📨 'newMessage' 이벤트 수신: \(data)")
            self?.handleReceivedMessage(data)
        }

        socket.on("receiveMessage") { [weak self] data, ack in
            print("📨 'receiveMessage' 이벤트 수신: \(data)")
            self?.handleReceivedMessage(data)
        }

        // 추가 가능한 이벤트 이름들
        socket.on("messageReceived") { [weak self] data, ack in
            print("📨 'messageReceived' 이벤트 수신: \(data)")
            self?.handleReceivedMessage(data)
        }

        socket.on("chatMessage") { [weak self] data, ack in
            print("📨 'chatMessage' 이벤트 수신: \(data)")
            self?.handleReceivedMessage(data)
        }

        socket.on("broadcast") { [weak self] data, ack in
            print("📨 'broadcast' 이벤트 수신: \(data)")
            self?.handleReceivedMessage(data)
        }

        socket.on("room_message") { [weak self] data, ack in
            print("📨 'room_message' 이벤트 수신: \(data)")
            self?.handleReceivedMessage(data)
        }

        // 한국어 이벤트 이름들도 시도
        socket.on("메시지") { [weak self] data, ack in
            print("📨 '메시지' 이벤트 수신: \(data)")
            self?.handleReceivedMessage(data)
        }

        socket.on("채팅") { [weak self] data, ack in
            print("📨 '채팅' 이벤트 수신: \(data)")
            self?.handleReceivedMessage(data)
        }

        // 일반적인 서버 이벤트 이름들
        socket.on("update") { [weak self] data, ack in
            print("📨 'update' 이벤트 수신: \(data)")
            self?.handleReceivedMessage(data)
        }

        socket.on("notification") { [weak self] data, ack in
            print("📨 'notification' 이벤트 수신: \(data)")
            self?.handleReceivedMessage(data)
        }

        socket.on("event") { [weak self] data, ack in
            print("📨 'event' 이벤트 수신: \(data)")
            self?.handleReceivedMessage(data)
        }

        socket.on("data") { [weak self] data, ack in
            print("📨 'data' 이벤트 수신: \(data)")
            self?.handleReceivedMessage(data)
        }

        // 방 참여 관련 이벤트들 - 더 상세한 로깅
        socket.on("joined") { [weak self] data, ack in
            print("✅ [SUCCESS] 'joined' 이벤트 수신: \(data)")
        }

        socket.on("joinSuccess") { [weak self] data, ack in
            print("✅ [SUCCESS] 'joinSuccess' 이벤트 수신: \(data)")
        }

        socket.on("room_joined") { [weak self] data, ack in
            print("✅ [SUCCESS] 'room_joined' 이벤트 수신: \(data)")
        }

        socket.on("error") { [weak self] data, ack in
            print("❌ [JOIN ERROR] 방 참여 에러: \(data)")
        }

        socket.on("join_error") { [weak self] data, ack in
            print("❌ [JOIN ERROR] 방 참여 실패: \(data)")
        }

        socket.on("unauthorized") { [weak self] data, ack in
            print("❌ [AUTH ERROR] 인증 실패: \(data)")
        }

        // 일반적인 Socket.IO 서버에서 사용하는 이벤트 이름들
        socket.on("response") { [weak self] data, ack in
            print("📨 'response' 이벤트 수신: \(data)")
            // 메시지 관련 응답인지 확인
            if let firstData = data.first as? [String: Any],
               let content = firstData["content"] as? String {
                self?.handleReceivedMessage(data)
            }
        }

        // 서버에서 클라이언트에게 보내는 일반적인 이벤트들
        socket.on("serverMessage") { [weak self] data, ack in
            print("📨 'serverMessage' 이벤트 수신: \(data)")
            self?.handleReceivedMessage(data)
        }

        socket.on("clientMessage") { [weak self] data, ack in
            print("📨 'clientMessage' 이벤트 수신: \(data)")
            self?.handleReceivedMessage(data)
        }
    }

    private func handleReceivedMessage(_ data: [Any]) {
        guard let messageData = data.first else {
            print("❌ Socket.IO 메시지 데이터 없음")
            return
        }

        print("📨 Socket.IO 메시지 수신 시도: \(messageData)")
        print("📨 데이터 타입: \(type(of: messageData))")

        // 다양한 형식 시도
        var messageDict: [String: Any]?

        if let dict = messageData as? [String: Any] {
            messageDict = dict
        } else if let string = messageData as? String {
            print("🔄 문자열 데이터 감지, JSON 파싱 시도: \(string)")
            if let data = string.data(using: .utf8),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                messageDict = dict
            }
        } else {
            print("❌ 지원하지 않는 메시지 데이터 형식: \(type(of: messageData))")
            return
        }

        guard let dict = messageDict else {
            print("❌ 메시지 딕셔너리 파싱 실패")
            return
        }

        print("📨 파싱된 메시지 딕셔너리: \(dict)")

        // 다양한 키 형식 지원
        let chatId = dict["chat_id"] as? String ?? dict["chatId"] as? String ?? dict["id"] as? String
        let roomId = dict["room_id"] as? String ?? dict["roomId"] as? String
        let content = dict["content"] as? String ?? dict["message"] as? String ?? dict["text"] as? String
        let createdAt = dict["createdAt"] as? String ?? dict["created_at"] as? String ?? dict["timestamp"] as? String

        guard let finalChatId = chatId,
              let finalRoomId = roomId,
              let finalContent = content,
              let finalCreatedAt = createdAt else {
            print("❌ 필수 메시지 필드 누락:")
            print("   chatId: \(chatId ?? "nil")")
            print("   roomId: \(roomId ?? "nil")")
            print("   content: \(content ?? "nil")")
            print("   createdAt: \(createdAt ?? "nil")")
            return
        }

        // 발신자 정보 파싱 (다양한 형식 지원)
        var senderDict: [String: Any]?
        if let sender = dict["sender"] as? [String: Any] {
            senderDict = sender
        } else if let from = dict["from"] as? [String: Any] {
            senderDict = from
        } else if let user = dict["user"] as? [String: Any] {
            senderDict = user
        }

        guard let sender = senderDict,
              let senderId = sender["user_id"] as? String ?? sender["userId"] as? String ?? sender["id"] as? String,
              let senderNick = sender["nick"] as? String ?? sender["nickname"] as? String ?? sender["name"] as? String else {
            print("❌ 발신자 정보 누락: \(dict)")
            return
        }

        let files = dict["files"] as? [String] ?? []
        let profileImage = sender["profileImage"] as? String ?? sender["profile_image"] as? String

        // ChatMessage 객체 생성
        let senderUser = User(
            userId: senderId,
            nickname: senderNick,
            profileImageURL: profileImage
        )

        let chatMessage = ChatMessage(
            id: finalChatId,
            roomId: finalRoomId,
            content: finalContent,
            createdAt: ISO8601DateFormatter().date(from: finalCreatedAt) ?? Date(),
            sender: senderUser,
            files: files
        )

        DispatchQueue.main.async {
            self.chatMessageSubject.send(chatMessage)
            // 채팅방 리스트도 업데이트
            self.chatRoomUpdateSubject.send(chatMessage.roomId)
        }

        print("✅ Socket.IO 메시지 변환 완료: \(chatMessage.content)")
        print("🔄 채팅방 리스트 업데이트 신호 전송: \(chatMessage.roomId)")
    }

    func sendMessage(roomId: String, content: String, files: [String]? = nil) {
        // 연결 상태 확인 및 재연결 시도
        guard let socket = socket else {
            print("❌ Socket.IO 객체가 없음 - 재연결 시도")
            openWebSocket(roomId: roomId)
            return
        }

        // socket.status와 isConnected 모두 확인
        guard isConnected && socket.status == .connected else {
            print("❌ Socket.IO 연결되지 않음 - isConnected: \(isConnected), socket.status: \(socket.status)")
            print("🔄 메시지 전송 취소 - 연결 상태 불안정")
            return
        }

        print("🚀 Socket.IO 메시지 전송 시도: \(content)")

        let messageData: [String: Any] = [
            "roomId": roomId,
            "content": content,
            "files": files ?? [],
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        print("📤 전송 데이터: \(messageData)")

        // 연결 상태를 한번 더 확인
        guard socket.status == .connected else {
            print("❌ 전송 직전 연결 상태 확인 실패: \(socket.status)")
            return
        }

        // 서버에서 지원할 가능성이 높은 이벤트들 시도
        socket.emit("sendMessage", messageData)
        socket.emit("message", messageData)
        socket.emit("chat", messageData)
        socket.emit("send", messageData)
        socket.emit("newMessage", messageData)

        print("✅ Socket.IO 메시지 전송 완료: \(content)")
    }

    private func joinRoom(roomId: String) {
        print("🏠 [OFFICIAL] 문서에 따르면 네임스페이스 연결로 자동 방 참여됨")
        print("🏠 [OFFICIAL] 별도 방 참여 emit 불필요 - 'chat' 이벤트만 수신하면 됨")
    }

    private func setupRoomJoinSuccessListener() {
        guard let socket = socket else { return }

        // 다양한 방 참여 성공 이벤트들 리스닝
        let successEvents = [
            "joinSuccess", "joined", "roomJoined", "join_success",
            "room_joined", "enterSuccess", "subscribeSuccess",
            "joinedRoom", "joinedChat", "connected", "ready"
        ]

        for event in successEvents {
            socket.once(event) { data, _ in
                print("✅ [JOIN SUCCESS] '\(event)' 이벤트 수신: \(data)")
            }
        }

        // 방 참여 실패 이벤트들도 리스닝
        let failureEvents = [
            "joinError", "join_error", "joinFailed", "join_failed",
            "roomError", "room_error", "subscribeError", "enterError"
        ]

        for event in failureEvents {
            socket.once(event) { data, _ in
                print("❌ [JOIN FAILED] '\(event)' 이벤트 수신: \(data)")
            }
        }
    }
}
