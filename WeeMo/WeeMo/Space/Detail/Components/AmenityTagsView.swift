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
            HStack(spacing: Spacing.small) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.app(.content2))
                        .foregroundColor(Color("textMain"))
                        .padding(.horizontal, Spacing.medium)
                        .padding(.vertical, Spacing.small)
                        .background(Color("wmGray"))
                        .cornerRadius(Spacing.radiusLarge)
                }
            }
        }
    }
}

#Preview {
    AmenityTagsView(tags: ["#조용함", "#WiFi", "#콘센트"])
        .padding()
}
