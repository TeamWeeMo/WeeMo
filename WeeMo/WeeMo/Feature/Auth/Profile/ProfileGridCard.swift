//
//  ProfileGridCard.swift
//  WeeMo
//
//  Created by Lee on 11/10/25.
//

import SwiftUI
import Kingfisher

struct ProfileGridCard: View {
    let title: String
    let imageURL: String?

    var body: some View {
        ZStack {
            if let imageURL = imageURL, let url = URL(string: imageURL) {
                KFImage(url)
                    .withAuthHeaders()
                    .placeholder {
                        ProgressView()
                    }
                    .onFailure { error in
                        print("[ProfileGridCard] 이미지 로드 실패: \(error.localizedDescription)")
                    }
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderView
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.separator, lineWidth: 1)
        }
    }

    private var placeholderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.textSub)

            Text(title)
                .font(.app(.subContent2))
                .padding(8)
                .foregroundStyle(.wmBg)
                .lineLimit(2)
        }
    }
}

struct ProfileGridSection: View {
    let columnCount: Int
    let items: [(title: String, imageURL: String?)]

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: columnCount)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(items.indices, id: \.self) { i in
                    ProfileGridCard(title: items[i].title, imageURL: items[i].imageURL)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .frame(height: 400)
    }
}

struct HorizontalScrollSection: View {
    let items: [(title: String, imageURL: String?)]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(items.indices, id: \.self) { i in
                    HorizontalMeetingCard(title: items[i].title, imageURL: items[i].imageURL)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(height: 116)  // 100 + 16(padding)
    }
}

struct HorizontalMeetingCard: View {
    let title: String
    let imageURL: String?

    var body: some View {
        ZStack {
            if let imageURL = imageURL, let url = URL(string: imageURL) {
                KFImage(url)
                    .withAuthHeaders()
                    .placeholder {
                        ProgressView()
                    }
                    .onFailure { error in
                        print("[HorizontalMeetingCard] 이미지 로드 실패: \(error.localizedDescription)")
                    }
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderView
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.separator, lineWidth: 1)
        }
    }

    private var placeholderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.textSub)

            Text(title)
                .font(.app(.subContent2))
                .padding(8)
                .foregroundStyle(.wmBg)
                .lineLimit(2)
        }
    }
}

struct LimitedGridSection: View {
    let columnCount: Int
    let items: [(title: String, imageURL: String?)]
    let maxRows: Int

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: columnCount)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(items.indices, id: \.self) { i in
                    ProfileGridCard(title: items[i].title, imageURL: items[i].imageURL)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: CGFloat(maxRows) * 108)  // 100 + 8(spacing)
    }
}

// 240 x 260 크기의 카드
struct LargeProfileCard: View {
    let title: String
    let imageURL: String?

    var body: some View {
        ZStack {
            if let imageURL = imageURL, let url = URL(string: imageURL) {
                KFImage(url)
                    .withAuthHeaders()
                    .placeholder {
                        ProgressView()
                    }
                    .onFailure { error in
                        print("[LargeProfileCard] 이미지 로드 실패: \(error.localizedDescription)")
                    }
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderView
            }
        }
        .frame(width: 240, height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.separator, lineWidth: 1)
        }
    }

    private var placeholderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.textSub)

            Text(title)
                .font(.app(.content2))
                .padding(16)
                .foregroundStyle(.wmBg)
                .lineLimit(3)
        }
    }
}

// 작성한 모임 - 가로 스크롤 (240 x 260)
struct LargeMeetingSection: View {
    let items: [(title: String, imageURL: String?)]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(items.indices, id: \.self) { i in
                    LargeProfileCard(title: items[i].title, imageURL: items[i].imageURL)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(height: 276)  // 260 + 16(padding)
    }
}

// 작성한 피드 - 4개 이하는 1줄, 4개 초과는 2줄 (100 x 100)
struct TwoRowHorizontalSection: View {
    let items: [(title: String, imageURL: String?)]

    // 4개 이하인지 확인
    private var isSingleRow: Bool {
        items.count <= 4
    }

    // 첫 번째 행에 4개까지, 나머지는 두 번째 행에 배치
    private var columns: [[(title: String, imageURL: String?)]] {
        guard items.count > 4 else {
            return []
        }

        var result: [[(title: String, imageURL: String?)]] = []
        let secondRowCount = items.count - 4  // 두 번째 행에 들어갈 아이템 수
        var index = 0

        // 완전한 컬럼 생성 (2개 아이템: 첫 번째 행 + 두 번째 행)
        for _ in 0..<secondRowCount {
            result.append([items[index], items[index + 1]])
            index += 2
        }

        // 단일 컬럼 생성 (1개 아이템: 첫 번째 행만)
        while index < items.count {
            result.append([items[index]])
            index += 1
        }

        return result
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            if isSingleRow {
                // 4개 이하: 1줄로 표시
                HStack(spacing: 12) {
                    ForEach(items.indices, id: \.self) { i in
                        ProfileGridCard(
                            title: items[i].title,
                            imageURL: items[i].imageURL
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            } else {
                // 5개 이상: 2줄로 표시 (첫 번째 행 4개 채우기)
                HStack(alignment: .top, spacing: 12) {
                    ForEach(columns.indices, id: \.self) { colIndex in
                        VStack(alignment: .center, spacing: 8) {
                            ForEach(columns[colIndex].indices, id: \.self) { rowIndex in
                                ProfileGridCard(
                                    title: columns[colIndex][rowIndex].title,
                                    imageURL: columns[colIndex][rowIndex].imageURL
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .frame(height: isSingleRow ? 116 : 216)  // 1줄: 100 + 16 / 2줄: 100 * 2 + 8 + 16
    }
}

#Preview {
    ProfileGridCard(title: "123", imageURL: nil)
}
