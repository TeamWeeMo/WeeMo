//
//  MeetListComponents.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI
import Kingfisher

// MARK: - D-Day Color Helper
//TODO: - 파일분리 필요
extension View {
    /// D-Day 배경색을 결정하는 헬퍼 함수
    /// - Parameter days: 마감까지 남은 일수
    /// - Returns: 조건에 따른 배경색
    func dDayBackgroundColor(for days: Int) -> Color {
        if days < 0 {
            return .black // 이미 마감
        } else if days == 0 {
            return .red // 오늘 마감
        } else {
            return .wmMain // 기본
        }
    }
}

// MARK: - 검색바
//TODO: - 검색바 버튼추가, 실시간검색 X
struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 8)

            TextField("모임을 검색하세요", text: $text)
                .font(.app(.content2))
                .padding(.vertical, 8)
                .padding(.trailing, 8)

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 8)
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .commonPadding()
    }
}

// MARK: - 필터 버튼
//TODO: - 파일분리, 정렬관련 수정 필요
struct FilterButton: View {
    @Binding var selectedOption: SortOption
    @Binding var showingOptions: Bool

    var body: some View {
        Button(action: {
            showingOptions.toggle()
        }) {
            HStack {
                Text(selectedOption.rawValue)
                    .font(.app(.content2))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
        }
        .commonButtonStyle(isSelected: false)
        .commonPadding()
        .confirmationDialog("정렬 기준", isPresented: $showingOptions, titleVisibility: .visible) {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button(option.rawValue) {
                    selectedOption = option
                }
            }
            Button("취소", role: .cancel) { }
        }
    }
}

// MARK: - 모임 리스트 카드
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
                        .background(dDayBackgroundColor(for: meet.daysUntilDeadline))
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

                //TODO: - 주소표시 추가 필요
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

    private var imageSection: some View {
        Group {
            if let firstImageURL = meet.imageURLs.first, !firstImageURL.isEmpty {
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
            .frame(width: 20, height: 20)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            )
    }
}
