//
//  MeetListComponents.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI
import Kingfisher

// MARK: - 검색바
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

// MARK: - 모임 카드
struct MeetCardView: View {
    let meet: Meet

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                if !meet.imageName.isEmpty {
                    let _ = print("🖼️ Original image URL: \(meet.imageName)")
                    let fullImageURL = meet.imageName.hasPrefix("http") ? meet.imageName : FileRouter.fileURL(from: meet.imageName)
                    let _ = print("🖼️ Full image URL with FileRouter: \(fullImageURL)")
                    if let encodedURL = fullImageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                       let url = URL(string: encodedURL) {
                        KFImage(url)
                            .withAuthHeaders()
                            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 400, height: 400)))
                            .placeholder {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 200)
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    )
                            }
                            .onFailure { error in
                                let _ = print("❌ Image loading failed for URL: \(url.absoluteString)")
                                let _ = print("❌ Error: \(error.localizedDescription)")
                            }
                            .onSuccess { result in
                                let _ = print("✅ Image loaded successfully from: \(url.absoluteString)")
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay(
                                Text("이미지 없음")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            )
                    }
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            Text("이미지 없음")
                                .font(.caption)
                                .foregroundColor(.gray)
                        )
                }
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.wmMain)
                                .frame(width: 40, height: 24)
                            Text(meet.daysLeft)
                                .font(.app(.subContent1))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                    Spacer()
                }
            }
            .frame(height: 200)
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 8) {
                Text(meet.title)
                    .font(.app(.subHeadline2))
                    .fontWeight(.semibold)
                    .foregroundColor(Color("textMain"))

                Text(meet.date)
                    .font(.app(.content2))
                    .foregroundColor(Color("textSub"))

                Text(meet.location)
                    .font(.app(.content2))
                    .foregroundColor(Color("textSub"))

                HStack {
                    Text(meet.price)
                        .font(.app(.content2))
                        .foregroundColor(Color("textSub"))

                    Spacer()

                    Text(meet.participants)
                        .font(.app(.content2))
                        .foregroundColor(Color("textSub"))
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(12)
        .cardShadow()
    }
}

// MARK: - 지도 보기 버튼
struct MapViewButton: View {
    var body: some View {
        NavigationLink(destination: MeetMapView()) {
            HStack {
                Image(systemName: "map")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                Text("지도보기")
                    .font(.app(.content2))
                    .foregroundColor(.black)
            }
            .frame(width: 130, height: 40)
            .background(Color.white)
            .cornerRadius(25)
            .cardShadow()
        }
    }
}

// MARK: - 플로팅 액션 버튼
struct FloatingActionButton: View {
    var body: some View {
        NavigationLink(destination: MeetEditView()) {
            HStack {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text("모임 만들기")
                    .font(.app(.content2))
                    .foregroundColor(.white)
            }
            .frame(width: 130, height: 40)
            .background(Color.black)
            .cornerRadius(25)
        }
    }
}

// MARK: - 모임 리스트 아이템
struct MeetListItemView: View {
    let meet: Meet

    var body: some View {
        HStack(spacing: 12) {
            // 이미지 섹션
            ZStack {
                if !meet.imageName.isEmpty {
                    let fullImageURL = meet.imageName.hasPrefix("http") ? meet.imageName : FileRouter.fileURL(from: meet.imageName)
                    if let encodedURL = fullImageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                       let url = URL(string: encodedURL) {
                        KFImage(url)
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
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(8)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                            )
                    }
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        )
                }
            }

            // 내용 섹션
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(meet.title)
                        .font(.app(.subHeadline2))
                        .fontWeight(.semibold)
                        .foregroundColor(Color("textMain"))
                        .lineLimit(1)

                    Spacer()

                    // D-day 뱃지
                    Text(meet.daysLeft)
                        .font(.app(.subContent1))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.wmMain)
                        .cornerRadius(4)
                }

                Text(meet.date)
                    .font(.app(.content2))
                    .foregroundColor(Color("textSub"))

                Text(meet.location)
                    .font(.app(.content2))
                    .foregroundColor(Color("textSub"))
                    .lineLimit(1)

                HStack {
                    // 프로필 이미지 (추후 구현)
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        )

                    Text(meet.price)
                        .font(.app(.content2))
                        .foregroundColor(Color("textSub"))

                    Spacer()

                    Text(meet.participants)
                        .font(.app(.content2))
                        .foregroundColor(Color("textSub"))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}
