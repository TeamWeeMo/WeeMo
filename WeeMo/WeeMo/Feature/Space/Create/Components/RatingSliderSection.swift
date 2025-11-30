//
//  RatingSliderSection.swift
//  WeeMo
//
//  Created by Reimos on 11/16/25.
//

import SwiftUI

struct RatingSliderSection: View {
    @Binding var rating: Double
    
    let formattedRating: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("평점")
                    .font(.app(.subHeadline2))
                    .foregroundColor(.textMain)

                Spacer()

                Text("\(formattedRating) / 5.0")
                    .font(.app(.subHeadline2))
                    .foregroundColor(.wmMain)
            }

            Slider(
                value: $rating,
                in: 1.0...5.0,
                step: 0.5
            )
            .accentColor(.wmMain)

            HStack {
                Text("1.0")
                    .font(.app(.content2))
                    .foregroundColor(Color("textSub"))
                Spacer()
                
                Text("5.0")
                    .font(.app(.content2))
                    .foregroundColor(Color("textSub"))
            }
        }
    }
}
