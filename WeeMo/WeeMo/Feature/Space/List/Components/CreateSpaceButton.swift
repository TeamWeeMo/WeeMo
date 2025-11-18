//
//  CreateSpaceButton.swift
//  WeeMo
//
//  Created by Reimos on 11/16/25.
//

import SwiftUI

struct CreateSpaceButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.small) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text("공간 등록하기")
                    .font(.app(.subHeadline2))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.medium)
            .background(Color("wmMain"))
            .cornerRadius(Spacing.radiusLarge)
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                CreateSpaceButton {
                    print("공간 등록하기 클릭")
                }
                .padding()
            }
        }
    }
}
