//
//  ChatWebSocketService.swift
//  WeeMo
//
//  Created by 차지용 on 11/20/25.
//

import Foundation
import Combine

// MARK: - Chat WebSocket Service

/// 실시간 채팅을 위한 WebSocket 서비스
class ChatWebSocketService: NSObject, ObservableObject {
    static let shared = ChatWebSocketService()

    // Published 프로퍼티들
    @Published var isConnected: Bool = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    let receivedMessage = PassthroughSubject<ChatMessage, Never>()
    let typingUsers = PassthroughSubject<TypingInfo, Never>()

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private let realmService = ChatRealmService.shared

    private var currentRoomId: String?
    private var reconnectTimer: Timer?
    private var heartbeatTimer: Timer?

    private override init() {
        super.init()
        setupURLSession()
    }

    deinit {
        disconnect()
    }

    // MARK: - Connection Management

    /// WebSocket 연결
    func connect(to roomId: String) {
        guard currentRoomId != roomId || !isConnected else { return }

        disconnect() // 기존 연결 해제
        currentRoomId = roomId

        guard let url = buildWebSocketURL(roomId: roomId) else {
            print("❌ Invalid WebSocket URL")
            return
        }

        connectionStatus = .connecting
        print("🔌 Connecting to WebSocket: \(url.absoluteString)")

        var request = URLRequest(url: url)
        addAuthHeaders(to: &request)

        webSocketTask = urlSession?.webSocketTask(with: request)
        webSocketTask?.resume()

        // 메시지 수신 대기
        receiveMessage()

        // 연결 상태 확인
        checkConnection()

        // 하트비트 시작
        startHeartbeat()
    }

    /// WebSocket 연결 해제
    func disconnect() {
        print("🔌 Disconnecting WebSocket")

        currentRoomId = nil
        connectionStatus = .disconnected
        isConnected = false

        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil

        stopHeartbeat()
        stopReconnectTimer()
    }

    /// 방 전환
    func switchRoom(to roomId: String) {
        connect(to: roomId)
    }

    // MARK: - Message Operations

    /// 메시지 전송
    func sendMessage(roomId: String, content: String, files: [String]? = nil) {
        guard isConnected, let webSocketTask = webSocketTask else {
            print("⚠️ WebSocket not connected, cannot send message")
            return
        }

        let message = WebSocketMessage(
            type: .message,
            roomId: roomId,
            content: content,
            files: files,
            timestamp: Date()
        )

        guard let data = try? JSONEncoder().encode(message),
              let jsonString = String(data: data, encoding: .utf8) else {
            print("❌ Failed to encode message")
            return
        }

        let websocketMessage = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask.send(websocketMessage) { error in
            if let error = error {
                print("❌ WebSocket send error: \(error)")
            } else {
                print("✅ Message sent via WebSocket")
            }
        }
    }

    /// 타이핑 상태 전송
    func sendTyping(roomId: String, isTyping: Bool) {
        guard isConnected, let webSocketTask = webSocketTask else { return }

        let message = WebSocketMessage(
            type: .typing,
            roomId: roomId,
            content: nil,
            files: nil,
            isTyping: isTyping,
            timestamp: Date()
        )

        guard let data = try? JSONEncoder().encode(message),
              let jsonString = String(data: data, encoding: .utf8) else { return }

        let websocketMessage = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask.send(websocketMessage) { _ in }
    }

    // MARK: - Private Methods

    private func setupURLSession() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    private func buildWebSocketURL(roomId: String) -> URL? {
        // NetworkConstants에서 기본 설정 가져오기
        guard let baseURL = URL(string: NetworkConstants.baseURL) else { return nil }

        var components = URLComponents()
        components.scheme = baseURL.scheme == "https" ? "wss" : "ws"
        components.host = baseURL.host
        components.port = NetworkConstants.socketPort
        components.path = "/chats-\(roomId)"

        return components.url
    }

    private func addAuthHeaders(to request: inout URLRequest) {
        // TokenManager에서 토큰 가져와서 헤더 추가
        if let token = TokenManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleReceivedMessage(message)
                self?.receiveMessage() // 다음 메시지 대기
            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                self?.handleConnectionError(error)
            }
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
            print("⚠️ Unknown message type received")
        }
    }

    private func parseAndHandleMessage(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else { return }

        do {
            let wsMessage = try JSONDecoder().decode(WebSocketMessage.self, from: data)

            DispatchQueue.main.async {
                switch wsMessage.type {
                case .message:
                    self.handleChatMessage(wsMessage)
                case .typing:
                    self.handleTypingMessage(wsMessage)
                case .heartbeat:
                    break // 하트비트는 별도 처리 없음
                }
            }
        } catch {
            print("❌ Failed to parse WebSocket message: \(error)")
        }
    }

    private func handleChatMessage(_ wsMessage: WebSocketMessage) {
        guard let content = wsMessage.content else { return }

        // ChatMessage로 변환 (임시 sender 정보)
        let sender = User(
            userId: wsMessage.senderId ?? "unknown",
            nickname: wsMessage.senderName ?? "Unknown User",
            profileImageURL: nil
        )

        let chatMessage = ChatMessage(
            id: wsMessage.messageId ?? UUID().uuidString,
            roomId: wsMessage.roomId,
            content: content,
            createdAt: wsMessage.timestamp,
            sender: sender,
            files: wsMessage.files ?? []
        )

        // 로컬 저장 (ChatMessageDTO 형태로 변환 필요시)
        // try? realmService.saveChatMessage(...)

        // UI 업데이트를 위해 발행
        receivedMessage.send(chatMessage)
    }

    private func handleTypingMessage(_ wsMessage: WebSocketMessage) {
        let typingInfo = TypingInfo(
            userId: wsMessage.senderId ?? "",
            userName: wsMessage.senderName ?? "",
            isTyping: wsMessage.isTyping ?? false,
            roomId: wsMessage.roomId
        )

        typingUsers.send(typingInfo)
    }

    private func checkConnection() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if self.webSocketTask?.state == .running {
                self.isConnected = true
                self.connectionStatus = .connected
                print("✅ WebSocket connected successfully")
            } else {
                self.handleConnectionError(nil)
            }
        }
    }

    private func handleConnectionError(_ error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatus = .disconnected
            print("❌ WebSocket connection failed: \(error?.localizedDescription ?? "Unknown error")")

            // 재연결 시도
            self.startReconnectTimer()
        }
    }

    private func startReconnectTimer() {
        stopReconnectTimer()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self = self, let roomId = self.currentRoomId else { return }
            print("🔄 Attempting to reconnect WebSocket...")
            self.connect(to: roomId)
        }
    }

    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }

    private func startHeartbeat() {
        stopHeartbeat()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }

    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    private func sendHeartbeat() {
        guard isConnected, let webSocketTask = webSocketTask, let roomId = currentRoomId else { return }

        let heartbeat = WebSocketMessage(
            type: .heartbeat,
            roomId: roomId,
            timestamp: Date()
        )

        guard let data = try? JSONEncoder().encode(heartbeat),
              let jsonString = String(data: data, encoding: .utf8) else { return }

        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask.send(message) { _ in }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension ChatWebSocketService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol `protocol`: String?) {
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectionStatus = .connected
            print("✅ WebSocket opened with protocol: \(`protocol` ?? "none")")
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatus = .disconnected
            print("🔌 WebSocket closed with code: \(closeCode)")

            if closeCode != .goingAway {
                self.startReconnectTimer()
            }
        }
    }
}

// MARK: - Supporting Types

enum ConnectionStatus {
    case connecting
    case connected
    case disconnected
    case error(Error)
}

struct TypingInfo {
    let userId: String
    let userName: String
    let isTyping: Bool
    let roomId: String
}

struct WebSocketMessage: Codable {
    let type: MessageType
    let roomId: String
    let content: String?
    let files: [String]?
    let messageId: String?
    let senderId: String?
    let senderName: String?
    let isTyping: Bool?
    let timestamp: Date

    enum MessageType: String, Codable {
        case message
        case typing
        case heartbeat
    }

    init(type: MessageType, roomId: String, content: String? = nil, files: [String]? = nil, messageId: String? = nil, senderId: String? = nil, senderName: String? = nil, isTyping: Bool? = nil, timestamp: Date) {
        self.type = type
        self.roomId = roomId
        self.content = content
        self.files = files
        self.messageId = messageId
        self.senderId = senderId
        self.senderName = senderName
        self.isTyping = isTyping
        self.timestamp = timestamp
    }
}

// MARK: - NetworkConstants Extension

extension NetworkConstants {
    static let socketPort: Int? = 3001 // WebSocket 포트 (필요시 수정)
}
