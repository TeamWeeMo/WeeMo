//
//  MeetEditView.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI

struct MeetEditView: View {
    @State private var meetTitle = ""
    @State private var meetDescription = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(
                onCancel: { presentationMode.wrappedValue.dismiss() },
                onComplete: { presentationMode.wrappedValue.dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ReservedSpaceSection()

                    MeetPhotoSection()

                    MeetTitleSection(title: $meetTitle)

                    MeetDescriptionSection(description: $meetDescription)

                    MeetSchedule()

                    MeetCapacitySection()

                    MeetGenderSection()

                    Spacer(minLength: 50)
                }
                .commonPadding()
                .padding(.top, 24)
            }
        }
        .background(Color("wmBg"))
        .navigationBarHidden(true)
    }
}

#Preview {
    MeetEditView()
}
