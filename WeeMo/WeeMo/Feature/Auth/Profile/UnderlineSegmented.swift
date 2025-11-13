//
//  UnderlineSegmented.swift
//  WeeMo
//
//  Created by Lee on 11/10/25.
//

import SwiftUI

enum ProfileTab: String, CaseIterable, Identifiable {
    case posts = "내 모임"
    case groups = "찜한 모임"
    case likes = "결제한 모임"
    var id: String { rawValue }
}

struct UnderlineSegmented: View {
    @Binding var selection: ProfileTab

    var underlineNS: Namespace.ID

    var body: some View {
        HStack {
            ForEach(ProfileTab.allCases) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(tab.rawValue)
                            .font(.app(.content2))
                            .foregroundStyle(selection == tab ? .wmMain : .textSub)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, minHeight: 44)

                        ZStack {
                            Rectangle().fill(.clear).frame(height: 2)
                            if selection == tab {
                                Rectangle()
                                    .fill(.wmMain)
                                    .frame(height: 2)
                                    .matchedGeometryEffect(id: "underline", in: underlineNS)
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
        .background(.wmBg)
    }
}

#Preview {
    UnderlineSegmented_PreviewWrapper()
}


private struct UnderlineSegmented_PreviewWrapper: View {
    @State private var selection: ProfileTab = .posts
    @Namespace private var ns

    var body: some View {
        UnderlineSegmented(selection: $selection, underlineNS: ns)
            .padding()
            .background(.wmBg)
    }
}
