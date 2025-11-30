//
//  PDFViewerView.swift
//  WeeMo
//
//  Created by Reimos on 2025/11/30.
//

import SwiftUI
import PDFKit

// MARK: - PDF 뷰어 래퍼
struct PDFViewerView: View {
    let pdfURL: URL?
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(pdfURL: URL?) {
        self.pdfURL = pdfURL
    }

    // 이전 버전과의 호환성을 위한 이니셜라이저 (String 타입)
    init(pdfURL: String) {
        self.pdfURL = URL(string: pdfURL)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("PDF 생성 중...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: Spacing.base) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.textSub)

                        Text(errorMessage)
                            .font(.app(.content1))
                            .foregroundColor(.textSub)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if let url = pdfURL {
                    GeneratedPDFKitView(pdfURL: url)
                } else {
                    VStack(spacing: Spacing.base) {
                        Image(systemName: "doc.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.textSub)

                        Text("PDF를 생성할 수 없습니다.")
                            .font(.app(.content1))
                            .foregroundColor(.textSub)
                    }
                }
            }
            .navigationTitle("공간 안내 문서")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.textMain)
                    }
                }
            }
        }
    }
}

// MARK: - 생성된 PDF용 PDFKit UIViewRepresentable
struct GeneratedPDFKitView: UIViewRepresentable {
    let pdfURL: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        // PDF 로드
        if let document = PDFDocument(url: pdfURL) {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // 필요시 업데이트 로직 추가
    }
}
