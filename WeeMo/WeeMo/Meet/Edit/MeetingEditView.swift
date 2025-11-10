//
//  MeetingEditView.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI

struct MeetingEditView: View {
    @State private var meetingTitle = ""
    @State private var meetingDescription = ""
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

                    MeetingPhotoSection()

                    MeetingTitleSection(title: $meetingTitle)

                    MeetingDescriptionSection(description: $meetingDescription)

                    MeetingSchedule()

                    MeetingCapacitySection()

                    MeetingGenderSection()

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
    MeetingEditView()
}