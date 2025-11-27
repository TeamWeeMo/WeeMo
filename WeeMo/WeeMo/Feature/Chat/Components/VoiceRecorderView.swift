//
//  VoiceRecorderView.swift
//  WeeMo
//
//  Created by 차지용 on 11/27/25.
//

import SwiftUI
import AVFoundation
import Combine

struct VoiceRecorderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = VoiceRecorder()
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?

    let onVoiceRecorded: (Data) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                // 상단 취소 버튼
                HStack {
                    Button("취소") {
                        recorder.stopRecording()
                        dismiss()
                    }
                    .foregroundStyle(.white)
                    .padding()

                    Spacer()
                }

                Spacer()

                // 녹음 시간 표시
                Text(timeString(from: recordingTime))
                    .font(.system(size: 32, weight: .light, design: .monospaced))
                    .foregroundStyle(.white)

                // 녹음 버튼 (간단한 버전)
                Button {
                    print("🎤 녹음 버튼 탭됨 - 현재 녹음 상태: \(recorder.isRecording)")
                    if recorder.isRecording {
                        print("🎤 녹음 정지 호출")
                        stopRecording()
                    } else {
                        print("🎤 녹음 시작 호출")
                        startRecording()
                    }
                } label: {
                    Text(recorder.isRecording ? "녹음 중... (탭하여 정지)" : "녹음 시작")
                        .font(.app(.content1))
                        .foregroundStyle(.white)
                        .padding()
                        .background(recorder.isRecording ? Color.red : Color("wmMain"))
                        .cornerRadius(8)
                }

                Spacer()

                // 하단 컨트롤
                HStack(spacing: 60) {
                    // 삭제 버튼
                    Button {
                        recorder.stopRecording()
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.red.opacity(0.8))
                            .clipShape(Circle())
                    }

                    // 전송 버튼
                    Button {
                        sendRecording()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(Color("wmMain").opacity(0.8))
                            .clipShape(Circle())
                    }
                    .disabled(!recorder.hasRecording)
                    .opacity(recorder.hasRecording ? 1.0 : 0.5)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            recorder.checkPermission()
        }
        .onDisappear {
            stopTimer()
            recorder.stopRecording()
        }
    }

    private func startRecording() {
        recorder.startRecording()
        startTimer()
    }

    private func stopRecording() {
        recorder.stopRecording()
        stopTimer()
    }

    private func sendRecording() {
        if let recordingData = recorder.getRecordingData() {
            onVoiceRecorded(recordingData)
            dismiss()
        }
    }

    private func startTimer() {
        recordingTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingTime += 0.1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        let milliseconds = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, milliseconds)
    }
}

// MARK: - Voice Recorder
class VoiceRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var hasRecording = false

    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?

    override init() {
        super.init()
        setupAudioSession()
    }

    func checkPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                print("음성 녹음 권한이 거부되었습니다")
            }
        }
    }

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("오디오 세션 설정 실패: \(error)")
        }
    }

    func startRecording() {
        print("🎤 startRecording 호출됨")

        // 권한 상태 확인
        let permission = AVAudioSession.sharedInstance().recordPermission
        print("🎤 마이크 권한 상태: \(permission)")

        guard permission == .granted else {
            print("❌ 마이크 권한이 없습니다")
            return
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording_\(UUID().uuidString).m4a")
        recordingURL = audioFilename

        print("🎤 녹음 파일 경로: \(audioFilename)")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            // 오디오 세션 설정
            try AVAudioSession.sharedInstance().setActive(true)

            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self

            let recordStarted = audioRecorder?.record() ?? false
            print("🎤 녹음 시작 결과: \(recordStarted)")

            DispatchQueue.main.async {
                self.isRecording = recordStarted
                self.hasRecording = false
                print("🎤 isRecording 상태 업데이트: \(self.isRecording)")
            }
        } catch {
            print("❌ 녹음 시작 실패: \(error)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()

        DispatchQueue.main.async {
            self.isRecording = false
            self.hasRecording = true
        }
    }

    func getRecordingData() -> Data? {
        guard let url = recordingURL else { return nil }
        return try? Data(contentsOf: url)
    }
}

// MARK: - Audio Recorder Delegate
extension VoiceRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isRecording = false
            self.hasRecording = flag
        }
    }
}
