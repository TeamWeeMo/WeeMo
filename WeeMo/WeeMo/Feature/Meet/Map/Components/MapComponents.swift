//
//  MapComponents.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI
import MapKit

// MARK: - 지도 핀 뷰
struct MapPinView: View {
    let count: Int

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 32, height: 32)

                Text("\(count)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            Triangle()
                .fill(Color.black)
                .frame(width: 12, height: 8)
                .offset(y: -2)
        }
    }
}

// MARK: - 삼각형 도형
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()

        return path
    }
}

// MARK: - 지도용 모임 카드
struct MeetMapCard: View {
    let meet: Meet

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Image("테스트 이미지")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 160, height: 70)
                    .clipped()
                    .cornerRadius(8, corners: [.topLeft, .topRight])

                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.red)
                                .frame(width: 30, height: 16)
                            Text(meet.daysLeft)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 6)
                    .padding(.trailing, 6)
                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(meet.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color("textMain"))
                    .lineLimit(1)

                Text(meet.date)
                    .font(.system(size: 9))
                    .foregroundColor(Color("textSub"))
                    .lineLimit(1)

                Text(meet.location)
                    .font(.system(size: 9))
                    .foregroundColor(Color("textSub"))
                    .lineLimit(1)

                HStack {
                    Text(meet.price)
                        .font(.system(size: 9))
                        .foregroundColor(Color("textSub"))

                    Spacer()

                    Text(meet.participants)
                        .font(.system(size: 9))
                        .foregroundColor(Color("textSub"))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .frame(width: 160, height: 120)
        .background(Color.white)
        .cornerRadius(8)
        .cardShadow()
    }
}
