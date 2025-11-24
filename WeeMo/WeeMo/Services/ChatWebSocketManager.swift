//
//  ChatWebSocketManager.swift
//  WeeMo
//
//  Created by 차지용 on 11/22/25.
//

import Foundation
import Combine

final class ChatWebSocketManager: NSObject, ObservableObject {
    static let shared = ChatWebSocketManager()

    private var webSocket: URLSessionWebSocketTask?
    private var timer: Timer?

    // 채팅 메시지 수신을 위한 Subject
    var chatMessageSubject = PassthroughSubject<ChatMessage, Never>()

    // 연결 상태
    @Published var isConnected: Bool = false

    var currentRoomId: String?
    private var isConnecting = false
    private var retryCount = 0
    private let maxRetryCount = 3

    private override init() {
        super.init()
    }

    func openWebSocket(roomId: String) {
        print("🔌 openWebSocket 호출: \(roomId)")
        print("🔌 현재 방: \(currentRoomId ?? "nil"), 연결상태: \(isConnected), 연결중: \(isConnecting)")

        // 이미 같은 방에 연결되거나 연결 중인 경우 스킵
        if currentRoomId == roomId && (isConnected || isConnecting) {
            print("🔌 이미 연결되었거나 연결 중인 방 (\(roomId)) - 스킵")
            return
        }

        // 기존 연결이 있다면 직접 cancel만 호출
        if let existingSocket = webSocket {
            print("🔌 기존 WebSocket 태스크만 취소...")
            existingSocket.cancel(with: .goingAway, reason: nil)
            webSocket = nil
            timer?.invalidate()
            timer = nil
        }

        currentRoomId = roomId
        isConnecting = true
        print("🔌 새 방으로 설정: \(roomId), 연결 시작")

        // WebSocket URL 생성
        guard let url = buildWebSocketURL(roomId: roomId) else {
            print("❌ Invalid WebSocket URL for room: \(roomId)")
            return
        }

        print("🔌 Connecting to WebSocket: \(url.absoluteString)")

        // URLRequest 생성 및 헤더 추가
        var request = URLRequest(url: url)
        request.timeoutInterval = 30

        // 인증 헤더 추가
        addAuthHeaders(to: &request)

        // URLSession 설정
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true

        // 약간의 지연 후 연결 시작 (UI 업데이트와의 충돌 방지)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
            self.webSocket = session.webSocketTask(with: request)
            print("🔌 WebSocket 태스크 생성 완료")

            self.webSocket?.resume()
            print("🔌 WebSocket 연결 시작...")
        }
    }

    func closeWebSocket() {
        print("🔌 closeWebSocket 호출")
        print("🔌 현재 webSocket: \(webSocket != nil ? "존재" : "nil")")

        if let webSocket = webSocket {
            print("🔌 WebSocket 연결 해제 중...")
            webSocket.cancel(with: .goingAway, reason: nil)
            self.webSocket = nil
        }

        currentRoomId = nil
        Task { @MainActor in
            self.isConnected = false
        }

        timer?.invalidate()
        timer = nil
        print("🔌 WebSocket 해제 완료")
    }

    private func buildWebSocketURL(roomId: String) -> URL? {
        let baseURLString = NetworkConstants.baseURL
        guard let baseURL = URL(string: baseURLString) else {
            print("❌ Invalid base URL: \(baseURLString)")
            return nil
        }

        guard let host = baseURL.host else {
            print("❌ No host in base URL")
            return nil
        }

        // NetworkConstants에서 port 사용
        let port = Int(NetworkConstants.port) ?? 30279
        let scheme = baseURL.scheme == "https" ? "wss" : "ws"

        // Socket.IO WebSocket URL 형식: ws://host:port/chats-roomId/socket.io/?EIO=4&transport=websocket
        let webSocketURLString = "\(scheme)://\(host):\(port)/chats-\(roomId)/socket.io/?EIO=4&transport=websocket"

        guard let webSocketURL = URL(string: webSocketURLString) else {
            print("❌ Failed to build WebSocket URL")
            return nil
        }

        print("🔍 WebSocket URL: \(webSocketURL.absoluteString)")
        return webSocketURL
    }

    private func addAuthHeaders(to request: inout URLRequest) {
        print("🔍 헤더 추가 시작...")

        // SeSACKey 추가
        if let sesacKey = Bundle.main.object(forInfoDictionaryKey: "SeSACKey") as? String {
            request.setValue(sesacKey, forHTTPHeaderField: "SeSACKey")
            print("✅ SeSACKey added: \(String(sesacKey.prefix(10)))...")
        } else {
            print("❌ SeSACKey not found")
        }

        // ProductId 추가
        request.setValue(NetworkConstants.productId, forHTTPHeaderField: "ProductId")
        print("✅ ProductId added: \(NetworkConstants.productId)")

        // Authorization 토큰 추가
        if let token = TokenManager.shared.accessToken {
            request.setValue(token, forHTTPHeaderField: "Authorization")
            print("✅ Authorization token added: \(String(token.prefix(20)))...")
        } else {
            print("❌ Authorization token not found")
        }

        // 모든 헤더 출력
        print("🔍 모든 헤더:")
        for (key, value) in request.allHTTPHeaderFields ?? [:] {
            print("  \(key): \(String(value.prefix(20)))...")
        }
    }
}

// MARK: - WebSocket Delegate
extension ChatWebSocketManager: URLSessionWebSocketDelegate {

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print(#function, "SOCKET IS CONNECTED")
        retryCount = 0  // 연결 성공시 재시도 카운트 리셋
        isConnecting = false  // 연결 완료
        Task { @MainActor in
            self.isConnected = true
        }
        receiveSocketData()

        // 연결 성공 후 ping 시작
        sendPing()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print(#function, "SOCKET IS DISCONNECTED - Code: \(closeCode.rawValue)")
        if let reason = reason, let reasonString = String(data: reason, encoding: .utf8) {
            print("🔍 Disconnect reason: \(reasonString)")
        }
        isConnecting = false  // 연결 해제시에도 플래그 리셋
        Task { @MainActor in
            self.isConnected = false
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("❌ WebSocket connection error: \(error)")
            print("🔍 Error details: \(error.localizedDescription)")

            let nsError = error as NSError
            print("🔍 Error domain: \(nsError.domain), code: \(nsError.code)")

            // -999 (취소됨) 오류는 재시도하지 않음
            if nsError.code != -999 && nsError.code != -1005 && retryCount < maxRetryCount {
                retryCount += 1
                print("🔄 WebSocket 재시도 (\(retryCount)/\(maxRetryCount))")

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if let roomId = self.currentRoomId {
                        self.openWebSocket(roomId: roomId)
                    }
                }
                return
            }
        }

        retryCount = 0
        isConnecting = false  // 연결 실패시에도 플래그 리셋
        Task { @MainActor in
            self.isConnected = false
        }
    }
}

// MARK: - Message Handling
extension ChatWebSocketManager {

    func sendMessage(roomId: String, content: String, files: [String]? = nil) {
        guard let webSocket = webSocket, isConnected else {
            print("❌ WebSocket not connected")
            return
        }

        // 메시지 JSON 구성
        var message: [String: Any] = [
            "type": "message",
            "roomId": roomId,
            "content": content,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        // files가 있으면 추가
        if let files = files {
            message["files"] = files
        }

        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: data, encoding: .utf8) else {
            print("❌ Failed to encode message")
            return
        }

        webSocket.send(.string(jsonString)) { error in
            if let error = error {
                print("❌ Send Error: \(error)")
            } else {
                print("✅ Message sent via WebSocket")
            }
        }
    }

    func receiveSocketData() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleReceivedMessage(message)

            case .failure(let error):
                print("❌ Receive Error: \(error)")
            }

            // 재귀 호출로 계속 수신
            self?.receiveSocketData()
        }
    }

    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseAndHandleMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseAndHandleMessage(text)
            }
        @unknown default:
            print("⚠️ Unknown message type")
        }
    }

    private func parseAndHandleMessage(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else { return }

        do {
            // JSON 파싱하여 ChatMessage로 변환
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let chatMessage = parseChatMessage(from: json) {

                DispatchQueue.main.async {
                    self.chatMessageSubject.send(chatMessage)
                }
            }
        } catch {
            print("❌ Failed to parse message: \(error)")
        }
    }

    private func parseChatMessage(from json: [String: Any]) -> ChatMessage? {
        // JSON에서 ChatMessage 생성 로직
        guard let chatId = json["chat_id"] as? String,
              let roomId = json["room_id"] as? String,
              let content = json["content"] as? String,
              let createdAtString = json["createdAt"] as? String,
              let senderJson = json["sender"] as? [String: Any],
              let senderId = senderJson["user_id"] as? String,
              let senderNick = senderJson["nick"] as? String else {
            return nil
        }

        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.date(from: createdAtString) ?? Date()

        let sender = User(
            userId: senderId,
            nickname: senderNick,
            profileImageURL: senderJson["profileImage"] as? String
        )

        let files = json["files"] as? [String] ?? []

        return ChatMessage(
            id: chatId,
            roomId: roomId,
            content: content,
            createdAt: createdAt,
            sender: sender,
            files: files
        )
    }

    private func sendPing() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.webSocket?.sendPing { error in
                if let error = error {
                    print("💔 Ping error: \(error.localizedDescription)")
                } else {
                    print("💓 Ping successful")
                }
            }
        }
    }
}
