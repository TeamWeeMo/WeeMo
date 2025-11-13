//
//  TimelineBarView.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI

struct TimelineBarView: View {
    let pricePerHour: Int
    @State private var startHour: Int?
    @State private var endHour: Int?

    private let hours = Array(0...24) // 0시부터 24시까지

    // 선택된 시간
    var selectedHours: Int {
        guard let start = startHour, let end = endHour else { return 0 }
        return max(0, end - start)
    }

    // 총 금액
    var totalPrice: Int {
        selectedHours * pricePerHour
    }

    // 시간이 선택된 범위 내인지 확인
    private func isInSelectedRange(_ hour: Int) -> Bool {
        guard let start = startHour, let end = endHour else { return false }
        return hour >= start && hour < end
    }

    var body: some View {
        VStack(spacing: Spacing.base) {
            // 타임라인 바 (스크롤 가능)
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: Spacing.small) {
                    // 시간 레이블 (0~24시 모두 표시)
                    HStack(spacing: 0) {
                        ForEach(0...24, id: \.self) { hour in
                            Text("\(hour)")
                                .font(.app(.subContent1))
                                .foregroundColor(Color("textSub"))
                                .frame(width: 50, alignment: .center)
                        }
                    }

                    // 타임라인 바
                    ZStack(alignment: .leading) {
                        // 배경 바
                        Rectangle()
                            .fill(Color("wmGray"))
                            .frame(width: CGFloat(24 * 50), height: 60)
                            .cornerRadius(Spacing.radiusSmall)

                        // 시간 구분선
                        HStack(spacing: 0) {
                            ForEach(0...24, id: \.self) { hour in
                                Rectangle()
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 1, height: 60)
                                    .offset(x: hour == 0 ? 0 : -0.5)
                                if hour < 24 {
                                    Spacer()
                                        .frame(width: 49)
                                }
                            }
                        }

                        // 선택된 범위 바
                        if let start = startHour, let end = endHour {
                            let segmentWidth: CGFloat = 50
                            let selectedWidth = CGFloat(end - start) * segmentWidth
                            let offsetX = CGFloat(start) * segmentWidth

                            Rectangle()
                                .fill(.blue)
                                .frame(width: selectedWidth, height: 60)
                                .cornerRadius(Spacing.radiusSmall)
                                .offset(x: offsetX)
                        }

                        // 가격 표시
                        HStack(spacing: 0) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text("\(pricePerHour.formatted())")
                                    .font(.app(.subContent2))
                                    .foregroundColor(
                                        isInSelectedRange(hour) ? .white.opacity(0.8) : Color("textSub").opacity(0.6)
                                    )
                                    .frame(width: 50, height: 60)
                            }
                        }

                        // 터치 영역
                        HStack(spacing: 0) {
                            ForEach(0..<24, id: \.self) { hour in
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 50, height: 60)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        handleTimeSelection(hour)
                                    }
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.small)
            }

            // 선택 정보
            if startHour != nil && endHour != nil {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    HStack {
                        Text("선택: \(formatHour(startHour ?? 0)) ~ \(formatHour(endHour ?? 0)) (\(selectedHours)시간)")
                            .font(.app(.content2))
                            .foregroundColor(Color("textMain"))

                        Spacer()
                    }

                    HStack(spacing: Spacing.xSmall) {
                        Image(systemName: "wonsign.circle")
                            .font(.system(size: AppFontSize.s16.rawValue))
                            .foregroundColor(Color("wmMain"))

                        Text("\(totalPrice.formatted())원")
                            .font(.app(.headline3))
                            .foregroundColor(Color("wmMain"))
                    }
                }
                .padding(Spacing.medium)
                .background(Color("wmGray").opacity(0.5))
                .cornerRadius(Spacing.radiusSmall)
            }
        }
    }

    // 시간 선택 로직
    private func handleTimeSelection(_ hour: Int) {
        if startHour == nil {
            // 첫 번째 탭: 해당 시간대 선택 (hour ~ hour+1)
            startHour = hour
            endHour = hour + 1
        } else if isInSelectedRange(hour) {
            // 선택된 범위 내의 시간을 다시 탭하면 전체 선택 해제
            startHour = nil
            endHour = nil
        } else {
            // 다른 시간을 탭하면 범위 생성
            if hour > startHour! {
                endHour = hour + 1
            } else {
                // 시작보다 이전 시간을 선택하면 범위 재설정
                endHour = startHour! + 1
                startHour = hour
            }
        }
    }

    // 시간 포맷팅
    private func formatHour(_ hour: Int) -> String {
        return String(format: "%02d:00", hour)
    }
}

#Preview {
    TimelineBarView(pricePerHour: 15000)
        .padding()
}
