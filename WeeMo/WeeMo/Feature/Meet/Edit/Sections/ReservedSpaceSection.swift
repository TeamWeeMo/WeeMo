//
//  ReservedSpaceSection.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI
import Kingfisher

struct ReservedSpaceSection: View {
    @Binding var selectedSpace: Space?
    @State private var showingSpaceSelection = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "예약한 공간")

            Button(action: {
                showingSpaceSelection = true
            }) {
                HStack {
                    if let space = selectedSpace {
                        // 선택된 공간이 있을 때
                        if let imageURL = space.imageURLs.first {
                            // FileRouter를 사용하여 올바른 URL 생성
                            let fullImageURL = imageURL.hasPrefix("http") ? imageURL : FileRouter.fileURL(from: imageURL)
                            if let url = URL(string: fullImageURL) {
                            KFImage(url)
                                .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 120, height: 120)))
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
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color("imagePlaceholder"))
                                        .frame(width: 60, height: 60)
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipped()
                                .cornerRadius(8)
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color("imagePlaceholder"))
                                .frame(width: 60, height: 60)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(space.title)
                                .font(.app(.content1))
                                .foregroundColor(Color("textMain"))

                            Text(space.address)
                                .font(.app(.content2))
                                .foregroundColor(Color("textSub"))
                        }

                        Spacer()

                        Text("변경")
                            .font(.app(.content2))
                            .foregroundColor(.blue)
                    } else {
                        // 선택된 공간이 없을 때
                        ImagePlaceholder(
                            systemName: "plus.circle",
                            text: "공간 선택하기",
                            size: 32
                        )
                        .frame(maxWidth: .infinity, minHeight: 80)
                    }
                }
            }
            .cardStyle()
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingSpaceSelection) {
            SpaceSelectionView(selectedSpace: $selectedSpace)
        }
    }
}
