//
//  AddressSearchField.swift
//  WeeMo
//
//  Created by Reimos on 2025/11/19.
//

import SwiftUI

struct AddressSearchField: View {
    @Binding var address: String
    let onAddressSelected: (String, String, Double, Double) -> Void

    @StateObject private var store = AddressSearchStore()
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("주소")
                .font(.app(.subHeadline2))
                .foregroundColor(.textMain)

            VStack(spacing: 0) {
                // 검색 텍스트필드 + 검색 버튼
                HStack(spacing: Spacing.small) {
                    // 텍스트필드
                    HStack(spacing: Spacing.small) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(.textSub)

                        TextField("예) 문래역 스타벅스", text: $address)
                            .font(.app(.content1))
                            .foregroundColor(.textMain)
                            .focused($isFocused)
                            .onSubmit {
                                performSearch()
                            }

                        if !address.isEmpty {
                            Button {
                                address = ""
                                store.send(.clearResults)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.textSub)
                            }
                        }
                    }
                    .padding(Spacing.medium)
                    .background(Color.white)
                    .cornerRadius(Spacing.radiusMedium)
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                            .stroke(isFocused ? Color("wmMain") : Color.gray.opacity(0.3), lineWidth: 1)
                    )

                    // 검색 버튼
                    Button {
                        performSearch()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Color("wmMain"))
                            .cornerRadius(Spacing.radiusMedium)
                    }
                    .disabled(address.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(address.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                }

                // 검색 결과 드롭다운
                if store.state.showResults && (!store.state.searchResults.isEmpty || store.state.isSearching) {
                    VStack(alignment: .leading, spacing: 0) {
                        if store.state.isSearching {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("검색 중...")
                                    .font(.app(.content2))
                                    .foregroundColor(.textSub)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.medium)
                        } else {
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 0) {
                                    ForEach(store.state.searchResults) { result in
                                        AddressResultRow(result: result)
                                            .onTapGesture {
                                                // 주소 선택
                                                address = result.displayText
                                                onAddressSelected(
                                                    result.displayText,
                                                    result.roadAddress ?? "",
                                                    result.latitude,
                                                    result.longitude
                                                )
                                                store.send(.resultSelected(result))
                                                isFocused = false
                                            }

                                        if result.id != store.state.searchResults.last?.id {
                                            Divider()
                                                .padding(.leading, Spacing.base)
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 250)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(Spacing.radiusMedium)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.top, Spacing.xSmall)
                }
            }
        }
    }

    // MARK: - Private Methods
    private func performSearch() {
        guard !address.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        isFocused = false
        store.send(.search(address))
    }
}

// MARK: - Address Result Row
struct AddressResultRow: View {
    let result: AddressSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(result.displayText)
                .font(.app(.content1))
                .foregroundColor(.textMain)

            if !result.subText.isEmpty {
                Text(result.subText)
                    .font(.app(.content3))
                    .foregroundColor(.textSub)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Spacing.medium)
        .padding(.horizontal, Spacing.base)
        .contentShape(Rectangle())
    }
}
