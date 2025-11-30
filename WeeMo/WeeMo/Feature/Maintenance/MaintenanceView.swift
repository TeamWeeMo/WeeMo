//
//  MaintenanceView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/30/25.
//

import SwiftUI

/// 서비스 점검 중일 때 표시되는 전체 화면
struct MaintenanceView: View {

    let message: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            HStack(spacing: 4) {
                Image("WeeMoLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)

                Text("WeeMo")
                    .font(.app(.headline1))
                    .foregroundStyle(.black)
            }
            // 아이콘
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 40))
                .foregroundStyle(.textSub)
                .padding(.bottom, 8)

            // 제목
            Text("서비스 점검 중")
                .font(.app(.headline2))
                .foregroundStyle(.textMain)

            // 메시지
            Text(message)
                .font(.app(.content1))
                .foregroundStyle(.textSub)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            // 새로고침 버튼
            Button {
                // Remote Config 다시 가져오기
                Task { @MainActor in
                    try? await RemoteConfigManager.shared.fetchConfig()
                    // 앱 상태가 자동으로 업데이트됨
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("다시 확인")
                }
                .font(.app(.content1))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(.wmMain)
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.wmBg)
    }
}

#Preview {
    MaintenanceView(message: "더 나은 서비스를 위해 점검 중입니다.\n잠시 후 다시 이용해 주세요.")
}
