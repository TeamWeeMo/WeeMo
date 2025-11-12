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
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
            .padding(.horizontal, 12)
            .background(.white, in: RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                    .stroke(.wmMain, lineWidth: 1)
                    .allowsHitTesting(false)
            )
    }
}


extension View {
    func asMintCornerView() -> some View {
        modifier(MintCornerView())
    }
}
