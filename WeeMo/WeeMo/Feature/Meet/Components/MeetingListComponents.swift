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
        .actionSheet(isPresented: $showingOptions) {
            ActionSheet(
                title: Text("정렬 기준")
                    .font(.app(.subHeadline2)),
                buttons: SortOption.allCases.map { option in
                    .default(Text(option.rawValue)
                        .font(.app(.content1))) {
                        selectedOption = option
                    }
                } + [.cancel(Text("취소")
                    .font(.app(.content1)))]
            )
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
                    let fullImageURL = meet.imageName.hasPrefix("http") ? meet.imageName : FileRouter.fileURL(from: meet.imageName)
                    if let encodedURL = fullImageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                       let url = URL(string: encodedURL) {
                        KFImage(url)
                            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 400, height: 400)))
                            .requestModifier(AnyModifier { request in
                                var newRequest = request
                                // 이미지 요청에도 필요한 헤더 추가
                                if let sesacKey = Bundle.main.object(forInfoDictionaryKey: "SeSACKey") as? String {
                                    newRequest.setValue(sesacKey, forHTTPHeaderField: "SeSACKey")
                                }
                                newRequest.setValue(NetworkConstants.productId, forHTTPHeaderField: "ProductId")
                                if let token = UserDefaults.standard.string(forKey: "accessToken") {
                                    newRequest.setValue(token, forHTTPHeaderField: "Authorization")
                                }
                                return newRequest
                            })
                            .placeholder {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 200)
                                    .overlay(
                                        Text("이미지 로딩중")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    )
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
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
                                .fill(Color.red)
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

                Text(meet.address)
                    .font(.app(.subContent1))
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
