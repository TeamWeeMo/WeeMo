//
//  MeetEditView.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI
import PhotosUI

struct MeetEditView: View {
    let editingPostId: String? // 수정 모드일 때 postId
    @State private var meetTitle = ""
    @State private var meetDescription = ""
    @State private var selectedSpace: Space? = nil
    @State private var meetCapacity = 1
    @State private var meetPrice = "0"
    @State private var selectedGender = "누구나"
    @State private var startDate = Date()
    @StateObject private var store = MeetEditViewStroe()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteAlert = false

    // 수정 모드인지 확인하는 computed property
    private var isEditMode: Bool {
        return editingPostId != nil
    }

    init(editingPostId: String? = nil) {
        self.editingPostId = editingPostId
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // Custom Navigation Bar with Delete Button
                HStack {
                    Button("취소") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                    .font(.app(.content1))

                    Spacer()

                    // 삭제 버튼 (수정 모드에서만 표시)
                    if isEditMode {
                        Button("삭제") {
                            showingDeleteAlert = true
                        }
                        .foregroundColor(.red)
                        .font(.app(.content1))
                    }

                    Button("완료") {
                        if isEditMode, let postId = editingPostId {
                            store.handle(.updateMeet(
                                postId: postId,
                                title: meetTitle,
                                description: meetDescription,
                                capacity: meetCapacity,
                                price: meetPrice,
                                gender: selectedGender,
                                selectedSpace: selectedSpace,
                                startDate: startDate
                            ))
                        } else {
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
                    }
                    .foregroundColor(.blue)
                    .font(.app(.content1))
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color("wmBg"))

                Divider()
            }

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
                    // 새 이미지를 선택하면 기존 이미지 사용 안 함
                    if !newImages.isEmpty && isEditMode {
                        store.shouldKeepExistingImages = false
                        print("📸 새 이미지 선택: 기존 이미지 교체")
                    }
                }
            }
        }
        .onAppear {
            if let postId = editingPostId {
                print("수정 모드: 기존 데이터 로드 중... postId: \(postId)")
                store.handle(.loadMeetForEdit(postId: postId))
            }
        }
        .onChange(of: store.state.originalMeetData) { meetData in
            if let meetData = meetData, isEditMode {
                // 기존 모임 데이터로 UI 업데이트
                meetTitle = meetData.title
                meetDescription = extractDescriptionFromContent(meetData.content)
                meetCapacity = meetData.capacity
                meetPrice = extractPriceValue(meetData.price)
                selectedGender = meetData.gender

                // 날짜 파싱
                if let parsedDate = parseStartDate(from: meetData.content) {
                    startDate = parsedDate
                }

                // TODO: selectedSpace 설정 (spaceInfo가 있다면)
                if let spaceInfo = meetData.spaceInfo {
                    print("기존 공간 정보: \(spaceInfo.title)")
                }

                print("✅ UI updated with existing data: \(meetData.title)")
            }
        }
        .onChange(of: store.state.isMeetUpdated) { isMeetUpdated in
            if isMeetUpdated {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .onChange(of: store.state.isMeetDeleted) { isMeetDeleted in
            if isMeetDeleted {
                // 삭제 완료시 루트로 돌아가기 위해 NotificationCenter 사용
                NotificationCenter.default.post(name: NSNotification.Name("NavigateToRoot"), object: nil)
            }
        }
        .alert("모임 삭제", isPresented: $showingDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                if let postId = editingPostId {
                    store.handle(.deleteMeet(postId: postId))
                }
            }
        } message: {
            Text("정말 모임을 삭제하겠습니까?\n삭제된 모임은 복구할 수 없습니다.")
        }
    }

    // MARK: - Helper Functions

    private func extractDescriptionFromContent(_ content: String) -> String {
        // "📍 모임 장소:" 앞까지의 내용을 추출
        let components = content.components(separatedBy: "\n\n📍")
        return components.first ?? content
    }

    private func extractPriceValue(_ priceString: String) -> String {
        // "10,000원" -> "10000"으로 변환
        let cleanedPrice = priceString.replacingOccurrences(of: "원", with: "")
            .replacingOccurrences(of: ",", with: "")
        if cleanedPrice == "무료" {
            return "0"
        }
        return cleanedPrice
    }

    private func parseStartDate(from content: String) -> Date? {
        // "⏰ 모임 시작일: 2025.11.20 (수) 14:00" 형식에서 날짜 추출
        let pattern = "⏰ 모임 시작일: (.+)"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
           let range = Range(match.range(at: 1), in: content) {
            let dateString = String(content[range])
            return DateFormatter.displayFormatter.date(from: dateString)
        }
        return nil
    }

}



#Preview {
    MeetEditView()
}
