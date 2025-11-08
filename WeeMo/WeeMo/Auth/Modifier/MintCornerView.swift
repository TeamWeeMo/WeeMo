//
//  GrayBackgroundView.swift
//  WeeMo
//
//  Created by Lee on 11/8/25.
//

import SwiftUI

private struct MintCornerView: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.wmMain, lineWidth: 1)
            )
            .font(.app(.content2))

    }
}


extension View {
    func asMintCornerView() -> some View {
        modifier(MintCornerView())
    }
}
