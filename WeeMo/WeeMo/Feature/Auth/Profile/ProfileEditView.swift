//
//  ProfileEdit.swift
//  WeeMo
//
//  Created by Lee on 11/10/25.
//

import SwiftUI
import FSCalendar

struct ProfileEditView: View {
    let isNewProfile: Bool  // true: 프로필 작성, false: 프로필 편집

    @State var nickname: String = ""
    @State var date = Date()
    @State var selectedGender: String? = nil  // "남성", "여성", "미공개"

    var body: some View {
        ZStack {
            Color(.wmBg)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                VStack(spacing: 6) {
                    VStack {
                        Text(isNewProfile ? "프로필 작성" : "프로필 편집")
                            .font(.app(.headline3))

                        Rectangle()
                            .frame(width: 20, height: 2)
                            .foregroundStyle(.wmMain)
                    }
                }

                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .padding(5)
                    .asCircleRoundView()
                    .padding(.bottom, 10)

                VStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("닉네임")
                            .font(.app(.content2))
                        TextField("닉네임을 입력하세요", text: $nickname)
                            .asMintCornerView()
                        Text("닉네임 형식이 잘못되었어요")
                            .font(.app(.subContent2))
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("생년월일")
                            .font(.app(.content2))
                        DatePicker(
                            "",
                            selection: $date,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "ko_KR"))
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.app(.content2))
                        Text("생년월일을 선택해주세요")
                            .font(.app(.subContent2))
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("성별")
                            .font(.app(.content2))
                        HStack {
                            Text("남성")
                                .foregroundStyle(selectedGender == "남성" ? .wmBg : .textMain)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(selectedGender == "남성" ? .wmMain : .white, in: RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                                        .stroke(.wmMain, lineWidth: 1)
                                )
                                .onTapGesture {
                                    selectedGender = "남성"
                                }

                            Text("여성")
                                .foregroundStyle(selectedGender == "여성" ? .wmBg : .textMain)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(selectedGender == "여성" ? .wmMain : .white, in: RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                                        .stroke(.wmMain, lineWidth: 1)
                                )
                                .onTapGesture {
                                    selectedGender = "여성"
                                }

                            Text("미공개")
                                .foregroundStyle(selectedGender == "미공개" ? .wmBg : .textMain)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(selectedGender == "미공개" ? .wmMain : .white, in: RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Spacing.radiusMedium, style: .continuous)
                                        .stroke(.wmMain, lineWidth: 1)
                                )
                                .onTapGesture {
                                    selectedGender = "미공개"
                                }
                        }

                        Button {
                            print("버튼 클릭")
                        } label: {
                            Text("확인")
                                .font(.app(.subHeadline2))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity,
                                       minHeight: 46,
                                       alignment: .center)
                                .background(.wmMain)
                                .cornerRadius(8)
                        }
                        .padding(.top, 20)

                        if isNewProfile {
                            HStack {
                                Spacer()
                                Button {
                                    print("버튼 클릭")
                                } label: {
                                    Text("다음에 설정하기")
                                        .font(.app(.subHeadline2))
                                        .foregroundStyle(.blue)
                                }
                                Spacer()
                            }
                            .padding(.top, 20)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

#Preview {
    ProfileEditView(isNewProfile: true)
}
