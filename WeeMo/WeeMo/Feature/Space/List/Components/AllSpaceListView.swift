//
//  AllSpaceListView.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI
import Kingfisher

struct SpaceListCardView: View {
    let space: Space
    @State private var currentImageIndex: Int = 0
    @State private var videoThumbnails: [Int: UIImage] = [:]  // index: thumbnail

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 이미지 섹션 (카드 밖으로)
            if space.imageURLs.isEmpty {
                // 이미지가 없는 경우
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 160)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    )
                    .cornerRadius(Spacing.radiusSmall)
                    .padding(.horizontal, Spacing.base)
                    .padding(.bottom, Spacing.small)
            } else if space.imageURLs.count == 1 {
                // 이미지가 1개인 경우 (동영상일 수도 있음)
                let mediaURL = space.imageURLs[0]
                let isVideo = MeetVideoHelper.isVideoFile(mediaURL)

                if isVideo {
                    // 동영상 썸네일 + 재생 아이콘
                    ZStack {
                        if let thumbnail = videoThumbnails[0] {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 160)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 160)
                                .overlay(ProgressView())
                        }

                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .cornerRadius(Spacing.radiusSmall)
                    .padding(.horizontal, Spacing.base)
                    .padding(.bottom, Spacing.small)
                    .task {
                        videoThumbnails[0] = await MeetVideoHelper.extractThumbnail(from: mediaURL)
                    }
                } else if let imageURL = URL(string: FileRouter.fileURL(from: mediaURL)) {
                    KFImage(imageURL)
                        .withAuthHeaders()
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(ProgressView())
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .clipped()
                        .cornerRadius(Spacing.radiusSmall)
                        .padding(.horizontal, Spacing.base)
                        .padding(.bottom, Spacing.small)
                }
            } else if space.imageURLs.count == 2 {
                // 이미지가 2개인 경우 (2개만 표시, 동영상일 수도 있음)
                GeometryReader { geometry in
                    let pageWidth = geometry.size.width * 0.7
                    let pageSpacing: CGFloat = Spacing.base

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: pageSpacing) {
                            ForEach(0..<2, id: \.self) { index in
                                let mediaURL = space.imageURLs[index]
                                let isVideo = MeetVideoHelper.isVideoFile(mediaURL)

                                if isVideo {
                                    // 동영상 썸네일 + 재생 아이콘
                                    ZStack {
                                        if let thumbnail = videoThumbnails[index] {
                                            Image(uiImage: thumbnail)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: pageWidth, height: 160)
                                                .clipped()
                                        } else {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: pageWidth, height: 160)
                                                .overlay(ProgressView())
                                        }

                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 50))
                                            .foregroundStyle(.white)
                                            .shadow(radius: 4)
                                    }
                                    .cornerRadius(Spacing.radiusSmall)
                                    .task {
                                        videoThumbnails[index] = await MeetVideoHelper.extractThumbnail(from: mediaURL)
                                    }
                                } else if let imageURL = URL(string: FileRouter.fileURL(from: mediaURL)) {
                                    KFImage(imageURL)
                                        .withAuthHeaders()
                                        .placeholder {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .overlay(ProgressView())
                                        }
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: pageWidth, height: 160)
                                        .clipped()
                                        .cornerRadius(Spacing.radiusSmall)
                                }
                            }
                        }
                        .padding(.leading, Spacing.base)
                        .padding(.trailing, Spacing.base)
                    }
                }
                .frame(height: 160)
                .padding(.bottom, Spacing.small)
            } else {
                // 이미지가 3개 이상인 경우
                GeometryReader { geometry in
                    let pageWidth = geometry.size.width * 0.7
                    let pageSpacing: CGFloat = Spacing.base

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: pageSpacing) {
                            // 첫 3개 이미지는 레이아웃뷰로 표시
                            imageLayoutView(imageURLs: Array(space.imageURLs.prefix(3)))
                                .frame(width: pageWidth)

                            // 4번째 이미지부터는 한 개씩 표시 (동영상일 수도 있음)
                            if space.imageURLs.count > 3 {
                                ForEach(3..<space.imageURLs.count, id: \.self) { index in
                                    let mediaURL = space.imageURLs[index]
                                    let isVideo = MeetVideoHelper.isVideoFile(mediaURL)

                                    if isVideo {
                                        // 동영상 썸네일 + 재생 아이콘
                                        ZStack {
                                            if let thumbnail = videoThumbnails[index] {
                                                Image(uiImage: thumbnail)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: pageWidth, height: 160)
                                                    .clipped()
                                            } else {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: pageWidth, height: 160)
                                                    .overlay(ProgressView())
                                            }

                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 50))
                                                .foregroundStyle(.white)
                                                .shadow(radius: 4)
                                        }
                                        .cornerRadius(Spacing.radiusSmall)
                                        .task {
                                            videoThumbnails[index] = await MeetVideoHelper.extractThumbnail(from: mediaURL)
                                        }
                                    } else if let imageURL = URL(string: FileRouter.fileURL(from: mediaURL)) {
                                        KFImage(imageURL)
                                            .withAuthHeaders()
                                            .placeholder {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .overlay(ProgressView())
                                            }
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: pageWidth, height: 160)
                                            .clipped()
                                            .cornerRadius(Spacing.radiusSmall)
                                    }
                                }
                            }
                        }
//                        .padding(Spacing.base)
                        .padding(.leading, Spacing.base)
                        .padding(.trailing, Spacing.base)
                    }
                }
                .frame(height: 160)
                .padding(.bottom, Spacing.small)
            }

            // 공간 정보 카드
            VStack(alignment: .leading, spacing: Spacing.small) {
                // 제목
                Text(space.title)
                    .font(.app(.subHeadline2))
                    .foregroundColor(Color("textMain"))
                    .lineLimit(1)

                // 주소
                Text(space.address)
                    .font(.app(.content4))
                    .foregroundColor(Color("textSub"))
                    .lineLimit(1)

                // 별점과 가격
                HStack {
                    HStack(spacing: Spacing.xSmall) {
                        Image(systemName: "star.fill")
                            .font(.system(size: AppFontSize.s12.rawValue))
                            .foregroundColor(.yellow)

                        Text(space.formattedRating)
                            .font(.app(.subContent1))
                            .foregroundColor(Color("textMain"))
                    }

                    Spacer()

                    Text(space.formattedPrice)
                        .font(.app(.subHeadline2))
                        .foregroundColor(Color("wmMain"))
                }
            }
            .padding(Spacing.medium)
            .background(Color.white)
            .cornerRadius(Spacing.radiusSmall)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .padding(.horizontal, Spacing.base)
        }
    }

    // MARK: - Helper Views

    /// 첫 3개 이미지 레이아웃 (좌측 큰 이미지 + 우측 작은 이미지 2개, 동영상 썸네일 지원)
    @ViewBuilder
    private func imageLayoutView(imageURLs: [String]) -> some View {
        GeometryReader { geometry in
            let imageSpacing: CGFloat = 2 // 좌우 및 상하 이미지 간 간격
            let rightImageWidth: CGFloat = 120 // 우측 이미지 섹션 고정 너비
            let leftImageWidth = geometry.size.width - rightImageWidth - imageSpacing

            HStack(spacing: imageSpacing) {
                // 좌측 큰 이미지 (동영상일 수도 있음)
                let leftMediaURL = imageURLs[0]
                let isLeftVideo = MeetVideoHelper.isVideoFile(leftMediaURL)

                if isLeftVideo {
                    // 동영상 썸네일 + 재생 아이콘
                    ZStack {
                        if let thumbnail = videoThumbnails[0] {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: leftImageWidth, height: 160)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: leftImageWidth, height: 160)
                                .overlay(ProgressView())
                        }

                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .task {
                        videoThumbnails[0] = await MeetVideoHelper.extractThumbnail(from: leftMediaURL)
                    }
                } else if let imageURL = URL(string: FileRouter.fileURL(from: leftMediaURL)) {
                    KFImage(imageURL)
                        .withAuthHeaders()
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(ProgressView())
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: leftImageWidth, height: 160)
                        .clipped()
                }

                // 우측 작은 이미지 2개 (세로 배치, 동영상일 수도 있음)
                VStack(spacing: imageSpacing) {
                    ForEach(1..<min(3, imageURLs.count), id: \.self) { index in
                        let mediaURL = imageURLs[index]
                        let isVideo = MeetVideoHelper.isVideoFile(mediaURL)

                        if isVideo {
                            // 동영상 썸네일 + 재생 아이콘
                            ZStack {
                                if let thumbnail = videoThumbnails[index] {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: rightImageWidth, height: (160 - imageSpacing) / 2)
                                        .clipped()
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: rightImageWidth, height: (160 - imageSpacing) / 2)
                                        .overlay(ProgressView().scaleEffect(0.7))
                                }

                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 4)
                            }
                            .task {
                                videoThumbnails[index] = await MeetVideoHelper.extractThumbnail(from: mediaURL)
                            }
                        } else if let imageURL = URL(string: FileRouter.fileURL(from: mediaURL)) {
                            KFImage(imageURL)
                                .withAuthHeaders()
                                .placeholder {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(ProgressView())
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: rightImageWidth, height: (160 - imageSpacing) / 2)
                                .clipped()
                        }
                    }
                }
            }
        }
        .cornerRadius(Spacing.radiusSmall)
        .frame(height: 160)
    }
}

struct AllSpaceListView: View {
    let spaces: [Space]

    var body: some View {
        LazyVStack(spacing: Spacing.base) {
            ForEach(spaces) { space in
                NavigationLink(value: space) {
                    SpaceListCardView(space: space)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}
