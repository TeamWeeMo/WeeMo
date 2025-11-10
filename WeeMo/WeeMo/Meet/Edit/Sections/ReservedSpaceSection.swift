//
//  ReservedSpaceSection.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI

struct ReservedSpaceSection: View {
    @State private var selectedSpace: SpaceInfo? = nil
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
                        Image("테스트 이미지")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipped()
                            .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(space.name)
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
