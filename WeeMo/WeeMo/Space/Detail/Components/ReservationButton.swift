//
//  ReservationButton.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI

struct ReservationButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("예약하기")
                .font(.app(.subHeadline1))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.base)
                .background(Color("wmMain"))
                .cornerRadius(Spacing.radiusMedium)
        }
    }
}

#Preview {
    ReservationButton {
        print("예약하기 버튼 클릭")
    }
    .padding()
}
