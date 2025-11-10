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
struct MeetingMapCard: View {
    let meeting: Meeting

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 160, height: 80)
                    .cornerRadius(8, corners: [.topLeft, .topRight])

                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.red)
                                .frame(width: 30, height: 16)
                            Text(meeting.daysLeft)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 6)
                    .padding(.trailing, 6)
                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(meeting.title)
                    .font(.app(.subContent1))
                    .fontWeight(.semibold)
                    .foregroundColor(Color("textMain"))
                    .lineLimit(1)

                Text(meeting.date)
                    .font(.system(size: 10))
                    .foregroundColor(Color("textSub"))
                    .lineLimit(1)

                Text(meeting.location)
                    .font(.system(size: 10))
                    .foregroundColor(Color("textSub"))
                    .lineLimit(1)

                HStack {
                    Text(meeting.price)
                        .font(.system(size: 10))
                        .foregroundColor(Color("textSub"))

                    Spacer()

                    Text(meeting.participants)
                        .font(.system(size: 10))
                        .foregroundColor(Color("textSub"))
                }
            }
            .padding(8)
        }
        .frame(width: 160)
        .background(Color.white)
        .cornerRadius(8)
        .cardShadow()
    }
}