//
//  SpaceSelectionView.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI

struct SpaceInfo: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let imageName: String
}

struct SpaceSelectionView: View {
    @Binding var selectedSpace: SpaceInfo?
    @Environment(\.presentationMode) var presentationMode

    private let mockSpaces = [
        SpaceInfo(name: "모던 카페 라운지", address: "서울시 강남구 테헤란로 123", imageName: "테스트 이미지"),
        SpaceInfo(name: "코워킹 스페이스 허브", address: "서울시 마포구 홍대입구로 456", imageName: "테스트 이미지"),
        SpaceInfo(name: "북카페 리딩룸", address: "서울시 종로구 인사동길 789", imageName: "테스트 이미지"),
        SpaceInfo(name: "스터디룸 플레이스", address: "서울시 서초구 강남대로 321", imageName: "테스트 이미지")
    ]

    var body: some View {
        NavigationView {
            VStack {
                CustomNavigationBar(
                    onCancel: { presentationMode.wrappedValue.dismiss() },
                    onComplete: { presentationMode.wrappedValue.dismiss() }
                )

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(mockSpaces) { space in
                            SpaceRowView(
                                space: space,
                                isSelected: selectedSpace?.id == space.id,
                                onTap: {
                                    selectedSpace = space
                                }
                            )
                        }
                    }
                    .commonPadding()
                }
            }
            .background(Color("wmBg"))
            .navigationBarHidden(true)
        }
    }
}

struct SpaceRowView: View {
    let space: SpaceInfo
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(space.imageName)
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

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 24))
                }
            }
        }
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .buttonStyle(PlainButtonStyle())
    }
}