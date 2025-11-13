//
//  GrayBackgroundView.swift
//  WeeMo
//
//  Created by Lee on 11/8/25.
//

import SwiftUI

private struct CircleRoundView: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.white, in: Circle())
            .overlay(
                Circle()
                    .stroke(.wmMain, lineWidth: 1)
            )
            .font(.app(.content2))

    }
}


extension View {
    func asCircleRoundView() -> some View {
        modifier(CircleRoundView())
    }
}
