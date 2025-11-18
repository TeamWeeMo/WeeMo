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
                    .requestModifier(imageRequestModifier)
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

    private var imageRequestModifier: AnyModifier {
        AnyModifier { request in
            var r = request

            // SeSACKey 추가
            if let sesacKey = Bundle.main.object(forInfoDictionaryKey: "SeSACKey") as? String {
                r.setValue(sesacKey, forHTTPHeaderField: HTTPHeaderKey.sesacKey)
            }

            // ProductId 추가
            r.setValue(NetworkConstants.productId, forHTTPHeaderField: HTTPHeaderKey.productId)

            // Authorization 추가
            if let token = TokenManager.shared.accessToken {
                r.setValue(token, forHTTPHeaderField: HTTPHeaderKey.authorization)
            }

            return r
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
                    .requestModifier(imageRequestModifier)
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

    private var imageRequestModifier: AnyModifier {
        AnyModifier { request in
            var r = request

            // SeSACKey 추가
            if let sesacKey = Bundle.main.object(forInfoDictionaryKey: "SeSACKey") as? String {
                r.setValue(sesacKey, forHTTPHeaderField: HTTPHeaderKey.sesacKey)
            }

            // ProductId 추가
            r.setValue(NetworkConstants.productId, forHTTPHeaderField: HTTPHeaderKey.productId)

            // Authorization 추가
            if let token = TokenManager.shared.accessToken {
                r.setValue(token, forHTTPHeaderField: HTTPHeaderKey.authorization)
            }

            return r
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

struct TwoRowHorizontalSection: View {
    let items: [(title: String, imageURL: String?)]

    private var firstRowItems: [(title: String, imageURL: String?)] {
        let midIndex = (items.count + 1) / 2
        return Array(items.prefix(midIndex))
    }

    private var secondRowItems: [(title: String, imageURL: String?)] {
        let midIndex = (items.count + 1) / 2
        return Array(items.dropFirst(midIndex))
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 8) {
                // 첫 번째 행
                HStack(spacing: 12) {
                    ForEach(firstRowItems.indices, id: \.self) { i in
                        ProfileGridCard(title: firstRowItems[i].title, imageURL: firstRowItems[i].imageURL)
                    }
                }

                // 두 번째 행
                HStack(spacing: 12) {
                    ForEach(secondRowItems.indices, id: \.self) { i in
                        ProfileGridCard(title: secondRowItems[i].title, imageURL: secondRowItems[i].imageURL)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(height: 216)  // 100 * 2 + 8(spacing) + 16(padding)
    }
}

#Preview {
    ProfileGridCard(title: "123", imageURL: nil)
}
