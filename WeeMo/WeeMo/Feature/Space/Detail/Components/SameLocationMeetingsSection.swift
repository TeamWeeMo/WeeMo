//
//  SameLocationMeetingsSection.swift
//  WeeMo
//
//  Created by Reimos on 2025/11/21.
//

import SwiftUI
import Kingfisher

// MARK: - SameLocationMeetingsSection
struct SameLocationMeetingsSection: View {
    let meetings: [PostDTO]

    var body: some View {
        if meetings.isEmpty {
            // 모임이 없을 때도 동일한 높이 유지
            Color.clear
                .frame(height: 0)
                .padding(.vertical, Spacing.xSmall)
        } else {
            VStack(alignment: .leading) {
                // 섹션 헤더
                HStack {
                    // 모임 카드 리스트 (수평 스크롤)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.small) {
                            ForEach(meetings, id: \.postId) { meeting in
                                SameLocationMeetingCard(meeting: meeting)
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
                                .foregroundColor(.textSub)

                            Image(systemName: "chevron.right")
                                .font(.system(size: AppFontSize.s12.rawValue))
                                .foregroundColor(.textSub)
                        }
                    }
                }
                .padding(.horizontal, Spacing.base)
            }
            .padding(.vertical, Spacing.xSmall)
        }
    }
}

// MARK: - SameLocationMeetingCard
struct SameLocationMeetingCard: View {
    let meeting: PostDTO

    var body: some View {
        // 첫 번째 이미지만 표시
        if let firstImageURL = meeting.files.first {
            KFImage(URL(string: FileRouter.fileURL(from: firstImageURL)))
                .withAuthHeaders()
                .placeholder {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                        )
                }
                .retry(maxCount: 3, interval: .seconds(2))
                .onFailure { error in
                    print("[SameLocationMeetingCard] 이미지 로드 실패: \(error.localizedDescription)")
                }
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipped()
                .cornerRadius(4)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        } else {
            // 이미지가 없는 경우 플레이스홀더
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                )
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - Preview

#Preview {
    SameLocationMeetingsSection(meetings: [])
        .background(Color("wmBg"))
}
