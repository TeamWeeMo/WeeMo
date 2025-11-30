//
//  AmenityTagsView.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI

struct AmenityTagsView: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack() {
                ForEach(tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.app(.subContent1))
                        .foregroundColor(.blue)
                        .padding(.horizontal, Spacing.xSmall)
                }
            }
        }
    }
}

#Preview {
    AmenityTagsView(tags: ["#조용함", "#WiFi", "#콘센트"])
        .padding()
}
