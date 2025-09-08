//
//  ProfileCustom.swift
//  WeLink
//
//  Created by 남만두 on 8/4/25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ProfileCustomView: View {
    var progress: CGFloat
    var isEdit: Bool
    
    @StateObject private var viewModel: ProfileCustomViewModel
    @FocusState private var focusedField: ProfileCustomViewModel.FocusField?
    @Environment(\.modelContext) private var context
    
    init(progress: CGFloat, cardModel: CardModel? = nil, isEdit: Bool) {
        self.progress = progress
        self.isEdit = isEdit
        self._viewModel = StateObject(wrappedValue: ProfileCustomViewModel(cardModel: cardModel, isEdit: isEdit))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                VStack {
                    progressBarView
                    
                    ScrollView(.vertical) {
                        VStack {
                            headerView
                            Spacer(minLength: 34)
                            profileImageInputView
                            userInfoFieldsView
                            confirmButtonView
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - View Components
extension ProfileCustomView {
    
    private var progressBarView: some View {
        ZStack(alignment: .leading) {
            let barWidth: CGFloat = 324
            let barHeight: CGFloat = 2
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.4))
                .frame(width: barWidth, height: barHeight)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color("MainColor"))
                .frame(width: barWidth * 0.2, height: barHeight)
        }
        .padding(.bottom, 20)
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("프로필을 입력해주세요!")
                .foregroundColor(.white)
                .font(.system(size: 21))
                .bold()
            Text("당신만의 취향카드를 만들어드릴게요.")
                .font(.system(size: 15))
                .foregroundColor(Color("MainColor"))
        }
        .padding(.trailing, 100)
    }
    
    private var profileImageInputView: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .frame(width: 196.3, height: 312)
                    .foregroundColor(Color("CategoryColor"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .onTapGesture {
                        viewModel.toggleShowPicker()
                    }

                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 196.3, height: 312)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            Button(action: {
                                viewModel.toggleShowPicker()
                            }) {
                                ZStack {
                                    Circle()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(Color("BackGround"))

                                    Image(systemName: "camera.fill")
                                        .resizable()
                                        .frame(width: 25, height: 20)
                                        .foregroundColor(Color.white)
                                }
                            },
                            alignment: .bottomTrailing
                        )
                } else {
                    VStack {
                        ZStack(alignment: .center) {
                            Image(systemName: "camera.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(Color.white.opacity(0.4))
                        }
                    }
                }
            }
        }
        .background(
            PhotoPickerWithPermission(
                selectedImage: $viewModel.selectedImage,
                showPicker: $viewModel.showPicker
            )
        )
    }

    private var userInfoFieldsView: some View {
        VStack(spacing: 40) {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    LabeledTextField(label: "이름", text: $viewModel.name, focus: $focusedField, focusCase: .name)

                    Text("생년월일")
                        .foregroundColor(Color(hex:0xCACACA))
                        .bold()
                        .font(.system(size: 16))
                    
                    Button(action: {
                        viewModel.toggleDatePicker()
                    }) {
                        HStack {
                            Text(viewModel.showDatePicker ? "생년월일을 선택하세요" : viewModel.formattedBirthDate)
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "calendar")
                                .foregroundColor(Color("MainColor"))
                        }
                        .padding()
                        .background(Color("TextFieldBackground"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color("CategoryColor"), lineWidth: 1.5)
                        )
                    }
                    .sheet(isPresented: $viewModel.showDatePicker) {
                        DatePickerSheet(selectedDate: $viewModel.birthDate, showDatePicker: $viewModel.showDatePicker)
                    }

                    LabeledTextField(label: "닉네임", text: $viewModel.nickname, focus: $focusedField, focusCase: .nickname)
                    LabeledTextField(label: "한줄소개", text: $viewModel.introduction, focus: $focusedField, focusCase: .introduction)
                    LabeledTextField(label: "MBTI", text: $viewModel.mbti, focus: $focusedField, focusCase: .mbti)
                    LabeledTextField(label: "직업", text: $viewModel.job, focus: $focusedField, focusCase: .job)
                }
            }
            .padding(.horizontal, 30)
            .foregroundColor(Color("BackgroundColor"))

            Spacer()
        }
    }
    
    private var confirmButtonView: some View {
        VStack {
            Button(action: {
                viewModel.saveProfile(context: context)
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 45)
                        .foregroundColor(viewModel.isFormValid ? Color("MainColor") : Color(.gray))
                        .frame(width: 324, height: 58)
                    Text("확인")
                        .bold()
                        .foregroundColor(.black)
                        .font(.system(size: 17))
                }
                .padding(.bottom, isEdit ? 55 : 0)
            }
            .disabled(!viewModel.isFormValid)
            .navigationDestination(isPresented: $viewModel.goNext) {
                if isEdit {
                    MyProfileTabView()
                } else {
                    if let cardModel = viewModel.cardModel {
                        CategoryView(progress: 2.0/4.0, cardModel: cardModel, isEdit: false)
                    }
                }
            }
        }
    }
}

struct LabeledTextField: View {
    let label: String
    @Binding var text: String
    var focus: FocusState<ProfileCustomViewModel.FocusField?>.Binding
    var focusCase: ProfileCustomViewModel.FocusField
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .foregroundColor(Color(hex:0xCACACA))
                .bold()
                .font(.system(size: 16))
            TextField("", text: $text)
                .padding()
                .background(Color("TextFieldBackground"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            focus.wrappedValue == focusCase ? Color("MainColor") : Color("CategoryColor"),
                            lineWidth: 1.5
                        )
                )
                .foregroundColor(.white)
                .focused(focus, equals: focusCase)
        }
    }
}

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var showDatePicker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("취소") {
                    showDatePicker = false
                }
                Spacer()
                Text("생년월일")
                    .font(.headline)
                Spacer()
                Button("완료") {
                    showDatePicker = false
                }
                .foregroundColor(Color("MainColor"))
            }
            .padding()
            .background(Color(.systemGray6))
            
            Divider()
            
            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxHeight: 250)
            .background(Color(.systemBackground))
            
            Spacer(minLength: 0)
        }
        .presentationDetents([.fraction(0.35)])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NavigationStack {
        ProfileCustomView(progress: 0.5, isEdit: false)
    }
}
