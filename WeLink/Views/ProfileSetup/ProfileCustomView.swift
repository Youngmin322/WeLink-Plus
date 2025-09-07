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
    @State private var name: String = ""
    @State private var birthDate = Date() // Date() -> Date로 수정
    @State private var nickname: String = ""
    @State private var introduction: String = ""
    @State private var mbti: String = ""
    @State private var job: String = ""
    @State private var showPicker = false
    @State private var selectedImage: UIImage?
    @State private var showDatePicker = false // 추가된 State 변수
    @FocusState private var focusedField: FocusField?

    @State private var cardModel: CardModel?
    @State private var goNext:Bool = false
    
    @Environment(\.modelContext) private var context
    
    @Query private var IDs: [MyUUID]
    @Query private var cards: [CardModel]
    
    private var myID: MyUUID = MyUUID(id: UUID())
    
    var isEdit: Bool
    
    init(progress: CGFloat, cardModel: CardModel? = nil, isEdit: Bool){
        self.progress = progress
        self.cardModel = cardModel
        self.isEdit = isEdit
        if let cardModel = cardModel {
            self.myID = isEdit ? MyUUID(id: cardModel.id) : self.myID
            // 기존 cardModel의 birthDate String을 Date로 변환
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            self._birthDate = State(initialValue: formatter.date(from: cardModel.birthDate) ?? Date())
        }
    }
    
    enum FocusField: Hashable {
        case name, nickname, introduction, mbti, job // birthDate 제거
    }
    
    // Date를 직접 받는 함수로 수정
    private func calculateAgeByYear(from birthDate: Date) -> Int {
        let calendar = Calendar.current
        let birthYear = calendar.component(.year, from: birthDate)
        let currentYear = calendar.component(.year, from: Date())
        return currentYear - birthYear + 1
    }

    // Date를 직접 받는 함수로 수정
    private func calculateDaysUntilBirthday(from birthDate: Date) -> Int {
        let calendar = Calendar.current
        let now = Date()
        var nextBirthdayComponents = calendar.dateComponents([.month, .day], from: birthDate)
        nextBirthdayComponents.year = calendar.component(.year, from: now)
        var nextBirthday = calendar.date(from: nextBirthdayComponents)!
        if nextBirthday < now {
            nextBirthdayComponents.year! += 1
            nextBirthday = calendar.date(from: nextBirthdayComponents)!
        }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: nextBirthday)).day ?? 0
        return days
    }
    
    // Date를 String으로 변환하는 함수 추가
    private func formatDateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
var body: some View {
    NavigationStack {
        ZStack{
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            VStack{
                ZStack(alignment: .leading) {
                    let barWidth: CGFloat = 324
                    let barHeight: CGFloat = 2
                    
                    // 회색 배경 바
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: barWidth, height: barHeight)
                    
                    // 연두색 프로그레스 바
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("MainColor"))
                        .frame(width: barWidth * 0.2, height: barHeight)
                }
                .padding(.bottom, 20)
                
                ScrollView(.vertical) {
                    VStack {
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

                        Spacer(minLength: 34)

                        profileImageInputView
                        userInfoFieldsView
                        
                        // 수정된 나이, 디데이 계산
                        let age = calculateAgeByYear(from: birthDate)
                        let dDay = calculateDaysUntilBirthday(from: birthDate)
                        
                        let isReady = (!name.isEmpty &&
                        !nickname.isEmpty &&
                        !introduction.isEmpty &&
                        !mbti.isEmpty &&
                        !job.isEmpty &&
                        selectedImage != nil) // birthDate.isEmpty 제거
                        
                        VStack {
                                Button(action: {
                                    if isEdit {
                                        cardModel?.name = name
                                        cardModel?.age = age
                                        cardModel?.cardDescription = introduction
                                        cardModel?.birthDate = formatDateToString(birthDate) // String으로 변환
                                        cardModel?.mbti = mbti
                                        cardModel?.tag = job
                                        cardModel?.dDay = dDay
                                        cardModel?.imageData = selectedImage!.pngData()!
                                    }
                                    else {
                                        cardModel = CardModel(id: myID.id,
                                                              name: name,
                                                              age: age,
                                                              description: introduction,
                                                              birthDate: formatDateToString(birthDate), // String으로 변환
                                                              mbti: mbti,
                                                              tag: job,
                                                              dDay: dDay,
                                                              imageData: selectedImage!.pngData()!
                                        )
                                        
                                        context.insert(myID)
                                        try? context.save()
                                    }
                                    
                                    goNext = true
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 45)
                                            .foregroundColor(isReady ? Color("MainColor") : Color(.gray))
                                            .frame(width: 324, height: 58)
                                        Text("확인")
                                            .bold()
                                            .foregroundColor(.black)
                                            .font(.system(size: 17))
                                    }
                                    .padding(.bottom, isEdit ? 55 : 0)
                                }

                                .navigationDestination(isPresented: $goNext) {
                                    if isEdit {
                                        MyProfileTabView()
                                    }
                                    else{
                                        if let cardModel = cardModel {
                                            CategoryView(progress: 2.0/4.0, cardModel: cardModel, isEdit: false)
                                        }
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
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
                        showPicker = true
                    }

                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 196.3, height: 312)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            Button(action: {
                                showPicker = true
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
                selectedImage: $selectedImage,
                showPicker: $showPicker
            )
        )
        .navigationBarHidden(true)
    }

    private var userInfoFieldsView: some View {
        VStack(spacing: 40) {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("이름")
                        .foregroundColor(Color(hex:0xCACACA))
                        .bold()
                        .font(.system(size: 16))
                    TextField("", text: $name)
                        .padding()
                        .background(Color("TextFieldBackground"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    focusedField == .name ? Color("MainColor") : Color("CategoryColor"),
                                    lineWidth: 1.5
                                )
                        )
                        .foregroundColor(.white)
                        .focused($focusedField, equals: .name)

                    Text("생년월일")
                        .foregroundColor(Color(hex:0xCACACA))
                        .bold()
                        .font(.system(size: 16))
                    
                    Button(action: {
                        showDatePicker.toggle()
                    }) {
                        HStack {
                            Text(showDatePicker ? "생년월일을 선택하세요" : formatDateToString(birthDate))
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
                    .sheet(isPresented: $showDatePicker) {
                        DatePickerSheet(selectedDate: $birthDate, showDatePicker: $showDatePicker)
                    }

                    Text("닉네임")
                        .foregroundColor(Color(hex:0xCACACA))
                        .bold()
                        .font(.system(size: 16))
                    TextField("", text: $nickname)
                        .padding()
                        .background(Color("TextFieldBackground"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    focusedField == .nickname ? Color("MainColor") : Color("CategoryColor"),
                                    lineWidth: 1.5
                                )
                        )
                        .foregroundColor(.white)
                        .focused($focusedField, equals: .nickname)
                    
                    Text("한줄소개")
                        .foregroundColor(Color(hex:0xCACACA))
                        .bold()
                        .font(.system(size: 16))
                    TextField("", text: $introduction)
                        .padding()
                        .background(Color("TextFieldBackground"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    focusedField == .introduction ? Color("MainColor") : Color("CategoryColor"),
                                    lineWidth: 1.5
                                )
                        )
                        .foregroundColor(.white)
                        .focused($focusedField, equals: .introduction)
                    
                    Text("MBTI")
                        .foregroundColor(Color(hex:0xCACACA))
                        .bold()
                        .font(.system(size: 16))
                    TextField("", text: $mbti)
                        .padding()
                        .background(Color("TextFieldBackground"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    focusedField == .mbti ? Color("MainColor") : Color("CategoryColor"),
                                    lineWidth: 1.5
                                )
                        )
                        .foregroundColor(.white)
                        .focused($focusedField, equals: .mbti)
                    
                    Text("직업")
                        .foregroundColor(Color(hex:0xCACACA))
                        .bold()
                        .font(.system(size: 16))
                    TextField("", text: $job)
                        .padding()
                        .background(Color("TextFieldBackground"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    focusedField == .job ? Color("MainColor") : Color("CategoryColor"),
                                    lineWidth: 1.5
                                )
                        )
                        .foregroundColor(.white)
                        .focused($focusedField, equals: .job)
                }
            }
            .padding(.horizontal, 30)
            .foregroundColor(Color("BackgroundColor"))

            Spacer()
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
