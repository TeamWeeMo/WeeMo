//
//  SpaceCreateView.swift
//  WeeMo
//
//  Created by Reimos on 11/16/25.
//

import SwiftUI
import PhotosUI

struct SpaceCreateView: View {
    @StateObject private var store = SpaceCreateStore()
    @Environment(\.dismiss) private var dismiss

    // 이미지 피커
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.base) {
                // 이미지 선택
                ImagePickerSection(
                    selectedPhotoItem: $selectedPhotoItem,
                    selectedImage: store.state.selectedImage,
                    onImageRemove: {
                        store.send(.imageRemoved)
                    }
                )
                .padding(.horizontal, Spacing.base)

                // 제목 입력
                InputFieldSection(
                    text: Binding(
                        get: { store.state.title },
                        set: { store.send(.titleChanged($0)) }
                    ),
                    title: "공간 이름",
                    placeholder: "예) 프라이빗 풀 키친"
                )
                .padding(.horizontal, Spacing.base)

                // 가격 입력
                InputFieldSection(
                    text: Binding(
                        get: { store.state.price },
                        set: { store.send(.priceChanged($0)) }
                    ),
                    title: "시간당 가격 (원)",
                    placeholder: "예) 45000",
                    keyboardType: .numberPad
                )
                .padding(.horizontal, Spacing.base)

                // 주소 입력
                InputFieldSection(
                    text: Binding(
                        get: { store.state.address },
                        set: { store.send(.addressChanged($0)) }
                    ),
                    title: "주소",
                    placeholder: "예) 서울 마포구 연남동 123-4"
                )
                .padding(.horizontal, Spacing.base)

                // 평점 슬라이더
                RatingSliderSection(
                    rating: Binding(
                        get: { store.state.rating },
                        set: { store.send(.ratingChanged($0)) }
                    ),
                    formattedRating: store.state.formattedRating
                )
                .padding(.horizontal, Spacing.base)

                // 카테고리 선택
                CategoryPickerSection(
                    selectedCategory: Binding(
                        get: { store.state.category },
                        set: { store.send(.categoryChanged($0)) }
                    )
                )
                .padding(.horizontal, Spacing.base)

                // 인기 공간 선택
                PopularToggleSection(
                    isPopular: Binding(
                        get: { store.state.isPopular },
                        set: { store.send(.popularToggled($0)) }
                    )
                )
                .padding(.horizontal, Spacing.base)

                // 설명 입력
                DescriptionInputSection(
                    description: Binding(
                        get: { store.state.description },
                        set: { store.send(.descriptionChanged($0)) }
                    )
                )
                .padding(.horizontal, Spacing.base)

                // 해시태그 입력
                HashTagInputSection(
                    hashTagInput: Binding(
                        get: { store.state.hashTagInput },
                        set: { store.send(.hashTagInputChanged($0)) }
                    ),
                    hashTags: store.state.hashTags,
                    canAddHashTag: store.state.canAddHashTag,
                    onAddHashTag: {
                        store.send(.addHashTag)
                    },
                    onRemoveHashTag: { tag in
                        store.send(.removeHashTag(tag))
                    }
                )
                .padding(.horizontal, Spacing.base)

                // 에러 메시지
                if let errorMessage = store.state.errorMessage {
                    Text(errorMessage)
                        .font(.app(.content2))
                        .foregroundColor(.red)
                        .padding(.horizontal, Spacing.base)
                }

                // 저장 버튼
                Button(action: {
                    store.send(.submitButtonTapped)
                }) {
                    if store.state.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text("저장")
                            .font(.app(.subHeadline1))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .background(store.state.isSubmitEnabled ? Color("wmMain") : Color.gray)
                .cornerRadius(Spacing.radiusMedium)
                .disabled(!store.state.isSubmitEnabled || store.state.isLoading)
                .padding(.horizontal, Spacing.base)
                .padding(.bottom, Spacing.base)
                }
            }
        }
        .background(Color("wmBg"))
        .navigationTitle("공간 등록")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundColor(Color("textMain"))
                }
            }
        }
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            Task {
                if let newValue = newValue,
                   let data = try? await newValue.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    store.send(.imageSelected(image))
                }
            }
        }
        .onChange(of: store.state.isSubmitSuccessful) { oldValue, newValue in
            if newValue {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        SpaceCreateView()
    }
}
