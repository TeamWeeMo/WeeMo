//
//  CameraCaptureView.swift
//  WeeMo
//
//  Created by 차지용 on 11/27/25.
//

import SwiftUI
import AVFoundation
import Photos

struct CameraCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraManager()
    @State private var showingImageConfirmation = false
    @State private var capturedImage: UIImage?

    let onImageCaptured: (Data) -> Void

    var body: some View {
        ZStack {
            CameraPreview(session: camera.session)
                .ignoresSafeArea()

            VStack {
                // 상단 컨트롤
                HStack {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)

                    Spacer()

                    Button {
                        camera.flipCamera()
                    } label: {
                        Image(systemName: "camera.rotate")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                    }
                }
                .padding()

                Spacer()

                // 하단 촬영 버튼
                HStack {
                    Spacer()

                    Button {
                        camera.capturePhoto()
                    } label: {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 70, height: 70)
                            .overlay {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 60, height: 60)
                            }
                    }

                    Spacer()
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            camera.checkPermission()
        }
        .onReceive(camera.capturedImagePublisher) { image in
            capturedImage = image
            showingImageConfirmation = true
        }
        .sheet(isPresented: $showingImageConfirmation) {
            if let image = capturedImage {
                ImageConfirmationView(
                    image: image,
                    onConfirm: { imageData in
                        onImageCaptured(imageData)
                        dismiss()
                    },
                    onCancel: {
                        capturedImage = nil
                        showingImageConfirmation = false
                    }
                )
            }
        }
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Image Confirmation View
struct ImageConfirmationView: View {
    let image: UIImage
    let onConfirm: (Data) -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack(spacing: 20) {
                    Button("다시 찍기") {
                        onCancel()
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(8)

                    Button("전송") {
                        if let imageData = image.jpegData(compressionQuality: 0.8) {
                            onConfirm(imageData)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(8)
                }
                .padding()
            }
        }
    }
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var output = AVCapturePhotoOutput()
    @Published var capturedImagePublisher = PassthroughSubject<UIImage, Never>()

    private var currentDevice: AVCaptureDevice?
    private var currentInput: AVCaptureDeviceInput?

    override init() {
        super.init()
        setupCamera()
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    func setupCamera() {
        #if targetEnvironment(simulator)
        return
        #endif

        session.beginConfiguration()

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)

            if session.canAddInput(input) {
                session.addInput(input)
                currentDevice = device
                currentInput = input
            }

            if session.canAddOutput(output) {
                session.addOutput(output)
            }

            session.commitConfiguration()

            DispatchQueue.global(qos: .background).async {
                self.session.startRunning()
            }
        } catch {
            print("카메라 설정 실패: \(error)")
        }
    }

    func flipCamera() {
        session.beginConfiguration()

        if let currentInput = currentInput {
            session.removeInput(currentInput)
        }

        let newPosition: AVCaptureDevice.Position = currentDevice?.position == .back ? .front : .back

        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            return
        }

        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)

            if session.canAddInput(newInput) {
                session.addInput(newInput)
                currentDevice = newDevice
                currentInput = newInput
            }
        } catch {
            print("카메라 전환 실패: \(error)")
        }

        session.commitConfiguration()
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
}

// MARK: - Photo Capture Delegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }

        DispatchQueue.main.async {
            self.capturedImagePublisher.send(image)
        }
    }
}

import Combine