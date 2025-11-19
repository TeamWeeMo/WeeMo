//
//  MeetEditView.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI
import PhotosUI

struct MeetEditView: View {
    @State private var meetTitle = ""
    @State private var meetDescription = ""
    @State private var selectedSpace: Space? = nil
    @State private var meetCapacity = 1
    @State private var meetPrice = "0"
    @State private var selectedGender = "누구나"
    @State private var startDate = Date()
    @StateObject private var store = MeetEditViewStroe()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(
                onCancel: { presentationMode.wrappedValue.dismiss() },
                onComplete: {
                    store.handle(.createMeet(
                        title: meetTitle,
                        description: meetDescription,
                        capacity: meetCapacity,
                        price: meetPrice,
                        gender: selectedGender,
                        selectedSpace: selectedSpace,
                        startDate: startDate
                    ))
                }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ReservedSpaceSection(selectedSpace: $selectedSpace)

                    MeetImageSection(store: store)

                    MeetTitleSection(title: $meetTitle)

                    MeetDescriptionSection(description: $meetDescription)

                    MeetSchedule(startDate: $startDate)

                    MeetCapacitySection(capacity: $meetCapacity)

                    MeetPriceSection(price: $meetPrice)

                    MeetGenderSection(selectedGender: $selectedGender)

                    Spacer(minLength: 50)
                }
                .commonPadding()
                .padding(.top, 24)
            }
        }
        .background(Color("wmBg"))
        .navigationBarHidden(true)
        .onChange(of: store.state.isMeetCreated) { isMeetCreated in
            if isMeetCreated {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .onChange(of: store.selectedPhotoItems) { newItems in
            Task {
                var newImages: [UIImage] = []

                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            newImages.append(uiImage)
                        }
                    }
                }

                await MainActor.run {
                    store.selectedImages = newImages
                }
            }
        }
    }

}



#Preview {
    MeetEditView()
}
