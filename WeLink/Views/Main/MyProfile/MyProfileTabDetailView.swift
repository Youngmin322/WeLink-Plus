//
//  MyProfileTabViewDetail.swift
//  WeLink
//
//  Created by 남만두 on 8/5/25.
//

import SwiftUI

struct MyProfileTabDetailView: View {
    var myProfile: CardModel
    @StateObject private var viewModel: MyProfileDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(myProfile: CardModel) {
        self.myProfile = myProfile
        self._viewModel = StateObject(wrappedValue: MyProfileDetailViewModel(myProfile: myProfile))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: 0x000000)
                .ignoresSafeArea()
            ScrollView {
                VStack {
                    ZStack {
                        backgroundImage(image: viewModel.profileImage)
                        
                        VStack {
                            Spacer()
                            DetailedInfo(myProfile: myProfile)
                        }
                    }
                    
                    CustomTabView(
                        topics: myProfile.topics,
                        currentTopic: $viewModel.currentTopic
                    )
                    
                    entireSubTopicView(currentTopic: $viewModel.currentTopic)
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea()
            .onAppear {
                viewModel.initializeTopics()
            }
            
            upperButtons(
                dismiss: { dismiss() },
                myProfile: myProfile
            )
            .padding(.top, -30)
        }
    }
}

// MARK: - View Components
extension MyProfileTabDetailView {
    
}

// MARK: - Supporting Views
struct backgroundImage: View {
    let image: UIImage?
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
                    .overlay( VStack {
                        Spacer()
                        
                        // 어둡게 그라데이션
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: 0x000000),
                                Color.clear
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: 200)
                    })
            } else {
                Rectangle()
                    .fill(Color.black)
                    .overlay( VStack {
                        Spacer()
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: 0x000000),
                                Color.clear
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: 200)
                    })
            }
        }
    }
}

struct upperButtons: View {
    let dismiss: () -> Void
    let myProfile: CardModel
    
    var body: some View {
        HStack {
            // 뒤로가기 버튼
            Button(action: {
                dismiss()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.clear)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "chevron.backward")
                        .resizable()
                        .frame(width: 15, height: 25)
                        .foregroundColor(Color("MainColor"))
                }
            }
            .contentShape(Rectangle())
            
            Spacer()
            
            Menu {
                NavigationLink("프로필 수정") {
                    ProfileCustomView(progress: 1.0 / 4.0, cardModel: myProfile, isEdit: true)
                        .navigationBarHidden(true)
                }
                NavigationLink("취향 카테고리 수정") {
                    CategoryView(progress: 2.0/4.0, cardModel: myProfile, isEdit: true)
                        .navigationBarHidden(true)
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.clear)
                        .frame(width: 44, height: 44)
                    Image(systemName: "ellipsis.vertical")
                        .foregroundColor(Color("MainColor"))
                        .font(.system(size: 24, weight: .bold))
                }
            }
            .contentShape(Rectangle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }
}

struct DetailedInfo: View {
    var myProfile: CardModel
    
    var body: some View {
        VStack(spacing: 30) {
            // 상단 이름 & 한줄소개
            VStack(spacing: 10) {
                Text(myProfile.name)
                    .font(.system(size: 50))
                    .bold()
                    .foregroundColor(.white)
                
                VStack(spacing: 10) {
                    Text(myProfile.cardDescription)
                        .font(.system(size: 14))
                        .bold()
                        .foregroundColor(.white)
                }
            }
            
            // 생일, MBTI, 직업
            HStack(spacing: 19) {
                ForEach([formattedBirthDate(from: myProfile.birthDate), myProfile.mbti, myProfile.tag], id: \.self) { label in
                    ZStack {
                        RoundedRectangle(cornerRadius: 45)
                            .stroke(Color("StrokeMyDetail"), lineWidth: 1)
                            .frame(width: 76, height: 29)
                        Text(label)
                            .foregroundColor(.white)
                            .font(.system(size: 13))
                    }
                }
            }
            .padding(.bottom, 15)
        }
    }
}

struct CustomTabView: View {
    let topics: [mainTopic]
    @Binding var currentTopic: mainTopic?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(topics, id: \.title) { topic in
                    newMainTopicButton(
                        topic: topic,
                        currentTopic: $currentTopic
                    )
                }
            }
            .padding(.vertical, 8)
            .background(Color(hex: 0x000000))
        }
    }
}

struct newMainTopicButton: View {
    let topic: mainTopic
    @Binding var currentTopic: mainTopic?
    
    var body: some View {
        Button(action: {
            currentTopic?.isSelected = false
            topic.isSelected = true
            currentTopic = topic
        }) {
            VStack(spacing: 16) {
                Text(topic.title)
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .bold))
                
                Rectangle()
                    .fill(topic.isSelected ? Color("MainColor") : Color.gray.opacity(0.3))
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct entireSubTopicView: View {
    @Binding var currentTopic: mainTopic?
    private let width: CGFloat = 348
    
    var body: some View {
        VStack {
            if let currentTopic = currentTopic {
                let sortedKeys = currentTopic.children.keys.sorted {
                    currentTopic.children[$0]!.title < currentTopic.children[$1]!.title
                }
                
                let lastSubTopicToShow: String = findLastKey(sortedKeys: sortedKeys, currentTopic: currentTopic)
                
                ForEach(Array(sortedKeys.enumerated()), id: \.offset) { (idx, key) in
                    if let subTopic = currentTopic.children[key] {
                        subTopicWindow(
                            topic: subTopic,
                            width: width,
                            lastKey: lastSubTopicToShow
                        )
                    }
                }
            }
        }
        .background(
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: 0x191919))
                    .frame(width: width, height: geo.size.height + 20, alignment: .center)
                    .offset(x: (geo.size.width - width) / 2)
            }
        )
        .padding(.bottom, 120)
    }
}

struct subTopicWindow: View {
    let topic: subTopic
    private let width: CGFloat
    private let lastKey: String
    
    private let buttonWidth: CGFloat = 100
    private let buttonHeight: CGFloat = 45
    
    init(topic: subTopic, width: CGFloat, lastKey: String) {
        self.topic = topic
        self.width = width
        self.lastKey = lastKey
    }
    
    var body: some View {
        ZStack {
            let selected = topic.children.values.filter { $0.isSelected }.sorted { $0.title < $1.title }
            if !selected.isEmpty {
                VStack(spacing: 22) {
                    HStack(spacing: 1) {
                        Text("#")
                            .foregroundColor(Color("MainColor"))
                            .font(.system(size: 20))
                            .bold()
                        Text(topic.title)
                            .font(.system(size: 20))
                            .bold()
                            .foregroundColor(.white)
                    }
                    .padding(.top, 15)
                    
                    let columns = [
                        GridItem(.fixed(buttonWidth), alignment: .center),
                        GridItem(.fixed(buttonWidth), alignment: .center),
                        GridItem(.fixed(buttonWidth), alignment: .center)
                    ]
                    
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(selected, id: \.id) { detailedTopic in
                            detailedTopicButton(topic: detailedTopic, width: buttonWidth, height: buttonHeight)
                        }
                    }
                    
                    if topic.title != lastKey {
                        Divider()
                            .frame(width: width - 50 , height: 1)
                            .background(Color.gray)
                            .opacity(1)
                            .padding(.top, 15)
                    }
                }
            }
        }
    }
    
    struct detailedTopicButton: View {
        let topic: detailedTopic
        let width: CGFloat
        let height: CGFloat
        
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 100)
                    .stroke(Color("MainColor"), lineWidth: 1)
                    .foregroundColor(Color("DetailedCategoryColor"))
                    .frame(width: width, height: height)
                
                Text(topic.title)
                    .font(.custom("Pretendard-Medium", size: 13))
                    .foregroundColor(Color("MainColor"))
            }
        }
    }
}

// MARK: - Helper Function
func findLastKey(sortedKeys: [String], currentTopic: mainTopic) -> String {
    var lastSubTopicToShow = ""
    
    for key in sortedKeys {
        if let subTopic = currentTopic.children[key] {
            let detailedTopics = Array(subTopic.children.values)
            
            for topic in detailedTopics {
                if topic.isSelected {
                    lastSubTopicToShow = key
                }
            }
        }
    }
    return lastSubTopicToShow
}

// MARK: - MyProfileDetailViewModel
@MainActor
class MyProfileDetailViewModel: ObservableObject {
    @Published var currentTopic: mainTopic?
    let profileImage: UIImage?
    
    private let myProfile: CardModel
    
    init(myProfile: CardModel) {
        self.myProfile = myProfile
        self.currentTopic = myProfile.topics.first
        self.profileImage = UIImage(data: myProfile.imageData)
    }
    
    func initializeTopics() {
        guard !myProfile.topics.isEmpty else { return }
        
        for topic in myProfile.topics {
            topic.isSelected = false
        }
        currentTopic = myProfile.topics[0]
        currentTopic?.isSelected = true
    }
    
    func switchTopic(to newTopic: mainTopic) {
        currentTopic?.isSelected = false
        newTopic.isSelected = true
        currentTopic = newTopic
    }
}

#Preview {
    MyProfileTabDetailView(myProfile: CardModel(id: UUID() , name: "하워드", age: 30, description: "야생의 하워드가 나타났다!", birthDate: "2003-04-24", mbti: "ISTP", tag: "선생님", dDay: 80, imageData: UIImage(named: "Giselle")!.pngData()!))
}
