//
//  MarkerView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/19/25.
//

import SwiftUI
import Kingfisher

// MARK: - 지도 마커 SwiftUI View (작고 심플한 버전)

struct MarkerView: View {
    let meet: Meet
    let count: Int

    var body: some View {
        ZStack {
            // 메인 마커 핀 (중앙 배치)
            VStack(spacing: -2) { // 원형과 삼각형 살짝 겹치도록
                // 원형 이미지
                imageSection
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(.wmMain, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)

                // 삼각형 포인터
                Triangle()
                    .fill(.wmMain)
                    .frame(width: 10, height: 10)
                    .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
            }

            // 개수 배지 (오른쪽 위)
            if count > 1 {
                VStack {
                    HStack {
                        Spacer()
                        countBadge
                    }
                    Spacer()
                }
                .padding(.top, 2)
                .padding(.trailing, 2)
            }
        }
        .frame(width: 70, height: 70)
        .padding(5) // 그림자와 배지를 위한 여백
        .background(Color.clear)
    }

    // MARK: - Subviews

    /// 이미지 섹션 (작은 원형)
    private var imageSection: some View {
        Group {
            if let firstImageURL = meet.firstImageURL, !firstImageURL.isEmpty {
                let fullImageURL = FileRouter.fileURL(from: firstImageURL)
                KFImage(URL(string: fullImageURL))
                    .withAuthHeaders()
                    .placeholder {
                        placeholderImage
                    }
                    .retry(maxCount: 2, interval: .seconds(1))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholderImage
            }
        }
    }

    /// 플레이스홀더 이미지
    private var placeholderImage: some View {
        ZStack {
            Circle()
                .fill(Color.wmMain.opacity(0.3))

            Image(systemName: "map.fill")
                .font(.system(size: 18))
                .foregroundColor(.wmMain)
        }
    }

    /// 개수 배지 (작고 외부에 배치)
    private var countBadge: some View {
        ZStack {
            Circle()
                .fill(.red)
                .frame(width: 20, height: 20)

            Text("\(count)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 삼각형 Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
