//
//  GrayBackgroundView.swift
//  WeeMo
//
//  Created by Lee on 11/8/25.
//

import SwiftUI

private struct GrayBackgroundView: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.wmGray)
            .font(.app(.content2))
            .cornerRadius(10)
    }
}


extension View {
    func asGrayBackgroundView() -> some View {
        modifier(GrayBackgroundView())
    }
}
