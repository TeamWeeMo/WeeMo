//
//  ContentView.swift
//  WeeMo
//
//  Created by YoungJin on 11/7/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            /// 폰트, 컬러 사용 예시
            Text("안녕하세요 가나다라마바사")
                .font(.app(.headline1))
                .foregroundStyle(.textSub)
            Text("안녕하세요 가나다라마바사")
                .font(.app(.content2))
                .foregroundStyle(.textMain)
        }
        /// 패딩 사용 예시
        .padding(Spacing.xSmall)
        .background(.wmMain)
    }
}

#Preview {
    ContentView()
}
