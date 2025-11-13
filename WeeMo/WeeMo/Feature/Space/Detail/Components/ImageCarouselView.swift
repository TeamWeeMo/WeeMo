//
//  ImageCarouselView.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI

struct ImageCarouselView: View {
    let imageURLs: [String]
    @State private var currentIndex: Int = 0

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $currentIndex) {
                ForEach(imageURLs.indices, id: \.self) { index in
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        )
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 300)

            // 커스텀 페이지 인디케이터
            Text("\(currentIndex + 1) / \(imageURLs.count)")
                .font(.app(.content2))
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .background(Color.black.opacity(0.6))
                .cornerRadius(Spacing.radiusSmall)
                .padding([.trailing, .bottom], Spacing.base)
        }
    }
}

#Preview {
    ImageCarouselView(imageURLs: ["cafe1", "cafe2", "cafe3"])
}
