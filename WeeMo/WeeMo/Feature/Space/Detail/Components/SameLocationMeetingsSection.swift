//
//  SameLocationMeetingsSection.swift
//  WeeMo
//
//  Created by Reimos on 2025/11/21.
//

import SwiftUI

// MARK: - SameLocationMeetingsSection
struct SameLocationMeetingsSection: View {
    var body: some View {
        VStack(alignment: .leading) {
            // 섹션 헤더
            HStack {
                // 모임 카드 리스트 (수평 스크롤)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xSmall) {
                        ForEach(0..<3) { index in
                            SameLocationMeetingCard(meetingIndex: index)
                        }
                    }
                }

                Spacer()
                
                Button {
                    // TODO: 전체보기 액션
                } label: {
                    HStack(spacing: Spacing.xSmall) {
                        Text("리뷰 전체보기")
                            .font(.app(.subContent1))
                            .foregroundColor(Color("textSub"))

                        Image(systemName: "chevron.right")
                            .font(.system(size: AppFontSize.s12.rawValue))
                            .foregroundColor(Color("textSub"))
                    }
                }
            }
            .padding(.horizontal, Spacing.base)
        }
        .padding(.vertical, Spacing.xSmall)
    }
}

// MARK: - SameLocationMeetingCard
struct SameLocationMeetingCard: View {
    let meetingIndex: Int

    var body: some View {
        // 모임 이미지
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 50, height: 50)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            )
            .padding(.horizontal, Spacing.xSmall)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
    }

// MARK: - Preview

#Preview {
    SameLocationMeetingsSection()
        .background(Color("wmBg"))
}
