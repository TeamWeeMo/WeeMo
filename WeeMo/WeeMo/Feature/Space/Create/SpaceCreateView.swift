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

    // 이미지 피커 (다중 선택)
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.base) {
                // 이미지 선택
                ImagePickerSection(
                    selectedPhotoItems: $selectedPhotoItems,
                    selectedImages: store.state.selectedImages,
                    maxImageCount: SpaceCreateState.maxImageCount,
                    onImageRemove: { index in
                        store.send(.imageRemoved(at: index))
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

                // 주소 검색
                AddressSearchField(
                    address: Binding(
                        get: { store.state.address },
                        set: { store.send(.addressChanged($0)) }
                    ),
                    onAddressSelected: { address, latitude, longitude in
                        store.send(.addressSelected(
                            address: address,
                            latitude: latitude,
                            longitude: longitude
                        ))
                    }
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

                // 편의시설 (주차, 화장실)
                FacilityToggleSection(
                    hasParking: Binding(
                        get: { store.state.hasParking },
                        set: { store.send(.parkingToggled($0)) }
                    ),
                    hasRestroom: Binding(
                        get: { store.state.hasRestroom },
                        set: { store.send(.restroomToggled($0)) }
                    )
                )
                .padding(.horizontal, Spacing.base)

                // 최대 인원
                MaxCapacityInputSection(
                    maxCapacity: Binding(
                        get: { store.state.maxCapacity },
                        set: { store.send(.maxCapacityChanged($0)) }
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
        .onChange(of: selectedPhotoItems) { oldValue, newValue in
            Task {
                // 새로 추가된 아이템만 처리
                let newItems = newValue.filter { newItem in
                    !oldValue.contains(where: { $0 == newItem })
                }

                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            store.send(.imageSelected(image))
                        }
                    }
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
