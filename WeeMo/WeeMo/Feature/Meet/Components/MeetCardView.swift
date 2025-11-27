//
//  MeetCardView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/27/25.
//

import SwiftUI
import Kingfisher

/// 모임 리스트 카드 뷰
struct MeetCardView: View {
    let meet: Meet

    var body: some View {
        HStack(spacing: 12) {
            // 이미지 섹션
            imageSection

            // 내용 섹션
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                HStack {
                    Text(meet.title)
                        .font(.app(.content2))
                        .fontWeight(.semibold)
                        .foregroundColor(.textMain)
                        .lineLimit(2)

                    Spacer()

                    // D-day 뱃지 (조건부 색상)
                    Text(meet.dDayText)
                        .font(.app(.subContent3))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                        .background(dDayBackgroundColor(for: meet))
                        .cornerRadius(4)
                }

                HStack(spacing: Spacing.small) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(.textSub)

                    Text(meet.meetingDateText)
                        .font(.app(.subContent3))
                        .foregroundColor(.textSub)
                }

                HStack(spacing: Spacing.small) {
                    Image(systemName: "mappin.square.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.textSub)

                    Text(meet.spaceName)
                        .font(.app(.subContent3))
                        .foregroundColor(.textSub)
                        .lineLimit(1)
                }

                HStack {
                    // 프로필 이미지
                    if let profileImage = meet.creator.profileImageURL, !profileImage.isEmpty {
                        KFImage(URL(string: FileRouter.fileURL(from: profileImage)))
                            .withAuthHeaders()
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 16, height: 16)
                            .clipShape(Circle())
                    } else {
                        profilePlaceholder
                    }

                    Text(meet.creator.nickname)
                        .font(.app(.subContent3))
                        .foregroundColor(.textSub)
                        .lineLimit(1)
                }

                HStack(spacing: Spacing.xSmall) {
                    Text("참가비")
                        .font(.app(.subContent1))
                        .foregroundColor(.textSub)

                    Text(meet.priceText)
                        .font(.app(.content2))
                        .foregroundColor(.wmMain)

                    Spacer()

                    Text("\(meet.participants)/\(meet.capacity)명")
                        .font(.app(.subContent1))
                        .foregroundColor(.textSub)
                }
                .padding(.vertical, Spacing.xSmall)
                .fontWeight(.semibold)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .cardShadow()
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Image Section

    private var imageSection: some View {
        Group {
            // 이미지만 필터링 (동영상 제외)
            let imageFiles = meet.fileURLs.filter { isImageFile($0) }

            if let firstImageURL = imageFiles.first, !firstImageURL.isEmpty {
                KFImage(URL(string: FileRouter.fileURL(from: firstImageURL)))
                    .withAuthHeaders()
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 200, height: 200)))
                    .placeholder {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            )
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(8)
            } else {
                imagePlaceholder
            }
        }
    }

    // MARK: - Helpers

    /// URL이 이미지 파일인지 확인
    private func isImageFile(_ urlString: String) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "heic", "heif", "webp", "gif"]
        let lowercased = urlString.lowercased()
        return imageExtensions.contains { lowercased.hasSuffix(".\($0)") }
    }

    // MARK: - Placeholders

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            )
    }

    private var profilePlaceholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 16, height: 16)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            )
    }
}
