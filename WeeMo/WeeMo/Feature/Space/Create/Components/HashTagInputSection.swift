//
//  HashTagInputSection.swift
//  WeeMo
//
//  Created by Reimos on 11/16/25.
//

import SwiftUI

struct HashTagInputSection: View {
    @Binding var hashTagInput: String
    
    let hashTags: [String]
    let canAddHashTag: Bool
    let onAddHashTag: () -> Void
    let onRemoveHashTag: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("해시태그")
                .font(.app(.subHeadline2))
                .foregroundColor(Color("textMain"))

            // 해시태그 입력 필드
            HStack(spacing: Spacing.small) {
                TextField("예) 풀파티", text: $hashTagInput)
                    .font(.app(.content1))
                    .padding(Spacing.medium)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(Spacing.radiusSmall)

                Button(action: onAddHashTag) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(canAddHashTag ? Color("wmMain") : Color.gray)
                }
                .disabled(!canAddHashTag)
            }

            // 추가된 해시태그 목록
            if !hashTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.small) {
                        ForEach(hashTags, id: \.self) { tag in
                            HStack(spacing: Spacing.xSmall) {
                                Text("#\(tag)")
                                    .font(.app(.content2))
                                    .foregroundColor(Color("wmMain"))

                                Button(action: {
                                    onRemoveHashTag(tag)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color("textSub"))
                                }
                            }
                            .padding(.horizontal, Spacing.medium)
                            .padding(.vertical, Spacing.small)
                            .background(Color("wmMain").opacity(0.1))
                            .cornerRadius(Spacing.radiusLarge)
                        }
                    }
                }
            }
        }
    }
}
