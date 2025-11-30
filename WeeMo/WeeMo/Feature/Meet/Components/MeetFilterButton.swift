//
//  MeetFilterButton.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/27/25.
//

import SwiftUI

/// Meet 리스트 정렬 필터 버튼
struct MeetFilterButton: View {
    @Binding var selectedOption: SortOption
    @Binding var showingOptions: Bool

    var body: some View {
        Button(action: {
            showingOptions.toggle()
        }) {
            HStack {
                Text(selectedOption.rawValue)
                    .font(.app(.content2))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
        }
        .commonButtonStyle(isSelected: false)
        .confirmationDialog("정렬 기준", isPresented: $showingOptions, titleVisibility: .visible) {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button(option.rawValue) {
                    selectedOption = option
                }
            }
            Button("취소", role: .cancel) { }
        }
    }
}
