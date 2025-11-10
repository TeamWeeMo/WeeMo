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

                    MeetingAgeSection()

                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
        }
        .background(Color("wmBg"))
        .navigationBarHidden(true)
    }
}

struct CustomNavigationBar: View {
    let onCancel: () -> Void
    let onComplete: () -> Void

    var body: some View {
        HStack {
            Button("취소") {
                onCancel()
            }
            .foregroundColor(.blue)
            .font(.app(.content1))

            Spacer()

            Button("완료") {
                onComplete()
            }
            .foregroundColor(.blue)
            .font(.app(.content1))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color("wmBg"))
    }
}

struct ReservedSpaceSection: View {
    @State private var selectedSpace: SpaceInfo? = nil
    @State private var showingSpaceSelection = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("예약한 공간")
                .font(.app(.subHeadline2))
                .foregroundColor(Color("textMain"))

            Button(action: {
                showingSpaceSelection = true
            }) {
                HStack {
                    if let space = selectedSpace {
                        // 선택된 공간이 있을 때
                        Image("테스트 이미지")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipped()
                            .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(space.name)
                                .font(.app(.content1))
                                .foregroundColor(Color("textMain"))

                            Text(space.address)
                                .font(.app(.content2))
                                .foregroundColor(Color("textSub"))
                        }

                        Spacer()

                        Text("변경")
                            .font(.app(.content2))
                            .foregroundColor(.blue)
                    } else {
                        // 선택된 공간이 없을 때
                        VStack(spacing: 12) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 32))
                                .foregroundColor(Color.gray.opacity(0.6))

                            Text("공간 선택하기")
                                .font(.app(.content2))
                                .foregroundColor(Color("textSub"))
                        }
                        .frame(maxWidth: .infinity, minHeight: 80)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingSpaceSelection) {
            SpaceSelectionView(selectedSpace: $selectedSpace)
        }
    }
}

struct SpaceInfo: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let imageName: String
}

struct SpaceSelectionView: View {
    @Binding var selectedSpace: SpaceInfo?
    @Environment(\.presentationMode) var presentationMode

    private let mockSpaces = [
        SpaceInfo(name: "모던 카페 라운지", address: "서울시 강남구 테헤란로 123", imageName: "테스트 이미지"),
        SpaceInfo(name: "코워킹 스페이스 허브", address: "서울시 마포구 홍대입구로 456", imageName: "테스트 이미지"),
        SpaceInfo(name: "북카페 리딩룸", address: "서울시 종로구 인사동길 789", imageName: "테스트 이미지"),
        SpaceInfo(name: "스터디룸 플레이스", address: "서울시 서초구 강남대로 321", imageName: "테스트 이미지")
    ]

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button("취소") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                    .font(.app(.content1))

                    Spacer()

                    Text("공간 선택")
                        .font(.app(.subHeadline2))
                        .foregroundColor(Color("textMain"))

                    Spacer()

                    Button("완료") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                    .font(.app(.content1))
                    .opacity(selectedSpace != nil ? 1.0 : 0.5)
                    .disabled(selectedSpace == nil)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(mockSpaces) { space in
                            SpaceRowView(
                                space: space,
                                isSelected: selectedSpace?.id == space.id,
                                onTap: {
                                    selectedSpace = space
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .background(Color("wmBg"))
            .navigationBarHidden(true)
        }
    }
}

struct SpaceRowView: View {
    let space: SpaceInfo
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(space.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(space.name)
                        .font(.app(.content1))
                        .foregroundColor(Color("textMain"))

                    Text(space.address)
                        .font(.app(.content2))
                        .foregroundColor(Color("textSub"))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 24))
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MeetingPhotoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("모임 사진")
                .font(.app(.subHeadline2))
                .foregroundColor(Color("textMain"))

            VStack(spacing: 12) {
                Image(systemName: "camera")
                    .font(.system(size: 48))
                    .foregroundColor(Color.gray.opacity(0.6))

                Text("사진 추가")
                    .font(.app(.content2))
                    .foregroundColor(Color("textSub"))
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct MeetingTitleSection: View {
    @Binding var title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("모임 이름")
                .font(.app(.subHeadline2))
                .foregroundColor(Color("textMain"))

            TextField("모임 이름을 입력하세요", text: $title)
                .font(.app(.content1))
                .foregroundColor(Color("textMain"))
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct MeetingDescriptionSection: View {
    @Binding var description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("모임 소개")
                .font(.app(.subHeadline2))
                .foregroundColor(Color("textMain"))

            VStack(alignment: .leading) {
                TextField("모임에 대해 자세히 소개해주세요", text: $description, axis: .vertical)
                    .font(.app(.content2))
                    .foregroundColor(Color("textMain"))
                    .lineLimit(5...10)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct MeetingSchedule: View {
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // 1시간 후
    @State private var showingStartDatePicker = false
    @State private var showingEndDatePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("일정")
                .font(.app(.subHeadline2))
                .foregroundColor(Color("textMain"))

            VStack(spacing: 12) {
                // 시작일 선택
                Button(action: {
                    showingStartDatePicker = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("시작일")
                                .font(.app(.content2))
                                .foregroundColor(Color("textSub"))

                            Text(DateFormatter.displayFormatter.string(from: startDate))
                                .font(.app(.content1))
                                .foregroundColor(Color("textMain"))
                        }

                        Spacer()

                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                            .font(.system(size: 20))
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())

                // 종료일 선택
                Button(action: {
                    showingEndDatePicker = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("종료일")
                                .font(.app(.content2))
                                .foregroundColor(Color("textSub"))

                            Text(DateFormatter.displayFormatter.string(from: endDate))
                                .font(.app(.content1))
                                .foregroundColor(Color("textMain"))
                        }

                        Spacer()

                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                            .font(.system(size: 20))
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .sheet(isPresented: $showingStartDatePicker) {
            DatePickerView(
                title: "시작일 선택",
                selectedDate: $startDate,
                minimumDate: Date()
            )
        }
        .sheet(isPresented: $showingEndDatePicker) {
            DatePickerView(
                title: "종료일 선택",
                selectedDate: $endDate,
                minimumDate: startDate
            )
        }
        .onChange(of: startDate) { newStartDate in
            // 시작일이 종료일보다 늦으면 종료일을 시작일 + 1시간으로 설정
            if newStartDate >= endDate {
                endDate = newStartDate.addingTimeInterval(3600)
            }
        }
    }
}

struct DatePickerView: View {
    let title: String
    @Binding var selectedDate: Date
    let minimumDate: Date?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            HStack {
                Button("취소") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.blue)
                .font(.app(.content1))

                Spacer()

                Text(title)
                    .font(.app(.subHeadline2))
                    .foregroundColor(Color("textMain"))

                Spacer()

                Button("완료") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.blue)
                .font(.app(.content1))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            DatePicker(
                "",
                selection: $selectedDate,
                in: (minimumDate ?? Date.distantPast)...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
            .padding(.horizontal, 20)
            .frame(maxHeight: 200)

            Spacer()
        }
        .frame(maxHeight: 320)
        .background(Color("wmBg"))
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .presentationDetents([.height(320)])
    }
}

struct MeetingCapacitySection: View {
    @State private var capacity = "0"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("인원 참가 비용")
                .font(.app(.subHeadline2))
                .foregroundColor(Color("textMain"))

            HStack {
                TextField("0", text: $capacity)
                    .font(.app(.content1))
                    .foregroundColor(Color("textMain"))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)

                Text("원")
                    .font(.app(.content1))
                    .foregroundColor(Color("textSub"))
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

struct MeetingGenderSection: View {
    @State private var selectedGender = "누구나"
    private let genderOptions = ["누구나", "남성만", "여성만"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("성별")
                .font(.app(.subHeadline2))
                .foregroundColor(Color("textMain"))

            HStack(spacing: 12) {
                ForEach(genderOptions, id: \.self) { option in
                    Button(action: {
                        selectedGender = option
                    }) {
                        Text(option)
                            .font(.app(.content1))
                            .foregroundColor(selectedGender == option ? .white : Color("textMain"))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(selectedGender == option ? Color.blue : Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                }
            }
        }
    }
}

struct MeetingAgeSection: View {
    @State private var hasAgeLimit = false
    @State private var minAge: Double = 20
    @State private var maxAge: Double = 40

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("나이 제한")
                .font(.app(.subHeadline2))
                .foregroundColor(Color("textMain"))

            VStack(spacing: 16) {
                // 나이제한 활성화/비활성화 토글
                HStack {
                    Text("나이 제한 설정")
                        .font(.app(.content1))
                        .foregroundColor(Color("textMain"))

                    Spacer()

                    Toggle("", isOn: $hasAgeLimit)
                        .toggleStyle(SwitchToggleStyle())
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                if hasAgeLimit {
                    VStack(spacing: 20) {
                        // 최소 나이 설정
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("최소 나이")
                                    .font(.app(.content2))
                                    .foregroundColor(Color("textSub"))

                                Spacer()

                                Text("\(Int(minAge))세")
                                    .font(.app(.content1))
                                    .foregroundColor(Color("textMain"))
                            }

                            Slider(value: $minAge, in: 10...70, step: 1)
                                .accentColor(.blue)
                        }

                        // 최대 나이 설정
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("최대 나이")
                                    .font(.app(.content2))
                                    .foregroundColor(Color("textSub"))

                                Spacer()

                                Text("\(Int(maxAge))세")
                                    .font(.app(.content1))
                                    .foregroundColor(Color("textMain"))
                            }

                            Slider(value: $maxAge, in: 10...70, step: 1)
                                .accentColor(.blue)
                        }

                        // 범위 표시
                        Text("참가 가능 연령: \(Int(minAge))세 - \(Int(maxAge))세")
                            .font(.app(.content2))
                            .foregroundColor(.blue)
                            .padding(.top, 8)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }
        }
        .onChange(of: minAge) { newMinAge in
            if newMinAge > maxAge {
                maxAge = newMinAge
            }
        }
        .onChange(of: maxAge) { newMaxAge in
            if newMaxAge < minAge {
                minAge = newMaxAge
            }
        }
    }
}

enum AgeRange: Int, CaseIterable, Hashable {
    case teens = 10
    case twenties = 20
    case thirties = 30
    case forties = 40
    case fifties = 50
    case sixties = 60
    case seventies = 70

    var displayName: String {
        switch self {
        case .teens:
            return "10대"
        case .twenties:
            return "20대"
        case .thirties:
            return "30대"
        case .forties:
            return "40대"
        case .fifties:
            return "50대"
        case .sixties:
            return "60대"
        case .seventies:
            return "70대"
        }
    }
}

extension DateFormatter {
    static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd (E) HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
}

#Preview {
    MeetingEditView()
}
