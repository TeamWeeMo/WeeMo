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

    // 커스텀 미디어 피커 표시 여부
    @State private var showMediaPicker = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.base) {
                // 미디어 선택 (이미지 + 동영상)
                SimpleMediaPickerSection(
                    title: "공간 미디어 (최대 5개)",
                    maxCount: SpaceCreateState.maxMediaCount,
                    selectedMediaItems: store.state.selectedMediaItems,
                    onAddTapped: {
                        showMediaPicker = true
                    },
                    onRemoveItem: { index in
                        store.send(.mediaItemRemoved(at: index))
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
                    onAddressSelected: { address, roadAddress, latitude, longitude in
                        store.send(.addressSelected(
                            address: address,
                            roadAddress: roadAddress,
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
                        .foregroundColor(.textMain)
                }
            }
        }
        .sheet(isPresented: $showMediaPicker) {
            CustomMediaPickerView(
                maxSelectionCount: SpaceCreateState.maxMediaCount - store.state.selectedMediaItems.count,
                onImageSelected: { images in
                    showMediaPicker = false

                    // 이미지를 MediaItem으로 변환 (압축 포함)
                    Task {
                        var mediaItems: [MediaItem] = []

                        for image in images {
                            if let mediaItem = MediaItem.fromImage(image) {
                                mediaItems.append(mediaItem)
                            }
                        }

                        await MainActor.run {
                            store.send(.mediaItemsSelected(mediaItems))
                        }
                    }
                },
                onVideoSelected: { videoURL in
                    showMediaPicker = false

                    // 동영상을 MediaItem으로 변환 (압축 + 썸네일 추출 포함)
                    Task {
                        if let mediaItem = await MediaItem.fromVideo(videoURL) {
                            await MainActor.run {
                                store.send(.mediaItemsSelected([mediaItem]))
                            }
                        }
                    }
                },
                onDismiss: {
                    showMediaPicker = false
                }
            )
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
