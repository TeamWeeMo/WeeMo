//
//  ProfileEdit.swift
//  WeeMo
//
//  Created by Lee on 11/10/25.
//

import SwiftUI
import PhotosUI
import Kingfisher

struct ProfileEditView: View {
    let isNewProfile: Bool  // true: 프로필 작성, false: 프로필 편집
    let initialImage: UIImage?  // 기존 프로필 이미지

    @Environment(\.dismiss) private var dismiss

    @State var nickname: String = ""
    @State var nicknameError: String = ""
    @State var date = Date()
    @State var selectedGender: String? = nil  // "남성", "여성", "미공개"

    // 이미지 선택
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showPhotoPicker = false

    // 로딩 상태
    @State private var isLoading: Bool = false

    init(isNewProfile: Bool, initialImage: UIImage? = nil) {
        self.isNewProfile = isNewProfile
        self.initialImage = initialImage
    }

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

                // 프로필 이미지
                ZStack {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(.white)
                            .frame(width: 80, height: 80)

                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundStyle(.gray)
                    }
                }
                .padding(5)
                .overlay(
                    Circle()
                        .stroke(.wmMain, lineWidth: 1)
                )
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(.wmMain)
                        .clipShape(Circle())
                        .offset(x: -5, y: -5)
                }
                .buttonWrapper {
                    showPhotoPicker = true
                }
                .padding(.bottom, 10)

                VStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("닉네임")
                            .font(.app(.content2))
                        TextField("닉네임을 입력하세요", text: $nickname)
                            .asMintCornerView()
                            .onChange(of: nickname) { _, newValue in
                                nicknameError = AuthValidator.checkNickname(newValue)
                            }

                        if !nicknameError.isEmpty {
                            Text(nicknameError)
                                .font(.app(.subContent2))
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal, 20)

                    // 생년월일과 성별은 최초 프로필 작성 시에만 표시
                    if isNewProfile {
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
                        }
                        .padding(.horizontal, 20)
                    }

                    Button {
                        handleConfirm()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .frame(maxWidth: .infinity, minHeight: 46)
                        } else {
                            Text("확인")
                                .font(.app(.subHeadline2))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity,
                                       minHeight: 46,
                                       alignment: .center)
                        }
                    }
                    .background(.wmMain)
                    .cornerRadius(8)
                    .disabled(isLoading || !nicknameError.isEmpty)
                    .opacity((isLoading || !nicknameError.isEmpty) ? 0.6 : 1.0)
                    .padding(.top, 20)
                    .padding(.horizontal, 20)

                    if isNewProfile {
                        HStack {
                            Spacer()
                            Button {
                                print("다음에 설정하기")
                            } label: {
                                Text("다음에 설정하기")
                                    .font(.app(.subHeadline2))
                                    .foregroundStyle(.blue)
                            }
                            Spacer()
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                    print("[ProfileEditView] 이미지 선택 완료")
                }
            }
        }
        .onAppear {
            if !isNewProfile {
                // 기존 닉네임 로드
                if let savedNickname = UserManager.shared.nickname {
                    nickname = savedNickname
                    print("[ProfileEditView] 기존 닉네임 로드: \(savedNickname)")
                }

                // 전달받은 프로필 이미지 설정
                if let initialImage = initialImage {
                    selectedImage = initialImage
                    print("[ProfileEditView] 기존 프로필 이미지 로드 완료")
                }
            }
        }
    }

    // MARK: - Methods

    private func handleConfirm() {
        // 닉네임 검증
        nicknameError = AuthValidator.checkNickname(nickname)
        guard nicknameError.isEmpty else {
            print("[ProfileEditView] 닉네임 검증 실패: \(nicknameError)")
            return
        }

        print("[ProfileEditView] 확인 버튼 클릭")
        print("닉네임: \(nickname)")

        if isNewProfile {
            print("생년월일: \(date)")
            print("성별: \(selectedGender ?? "미선택")")
            // TODO: 최초 프로필 작성 API 구현
        } else {
            // 프로필 편집
            updateProfile()
        }
    }

    private func updateProfile() {
        isLoading = true

        Task {
            do {
                // 1. 이미지가 있으면 먼저 업로드
                var imageData: Data? = nil
                if let selectedImage = selectedImage {
                    imageData = selectedImage.jpegData(compressionQuality: 0.8)
                }

                // 2. 프로필 업데이트 API 호출
                let response = try await NetworkService().request(
                    UserRouter.updateMyProfile(
                        nickname: nickname,
                        profileImage: imageData
                    ),
                    responseType: UserDTO.self
                )

                print("[ProfileEditView] 프로필 업데이트 성공")

                // 3. UserManager 업데이트
                await UserManager.shared.saveNickname(nickname)
                await UserManager.shared.saveProfileImageURL(response.profileImage)

                // 4. 이전 화면으로 돌아가기
                isLoading = false
                dismiss()

            } catch let error as NetworkError {
                print("[ProfileEditView] 프로필 업데이트 실패: \(error)")
                isLoading = false
                // TODO: 에러 메시지 표시
            } catch {
                print("[ProfileEditView] 프로필 업데이트 실패: \(error)")
                isLoading = false
            }
        }
    }
}

#Preview {
    ProfileEditView(isNewProfile: true, initialImage: nil)
}
