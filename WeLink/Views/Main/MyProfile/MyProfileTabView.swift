//
//  MyProfileTabView.swift
//  Wishing
//
//  Created by 조영민 on 8/4/25.
//

import SwiftUI
import SwiftData

struct MyProfileTabView: View {
    @Query private var myID: [MyUUID]
    @Query private var cards: [CardModel]
    @StateObject private var viewModel = MyProfileTabViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundImageView
                
                VStack {
                    headerView
                    
                    if let myProfile = viewModel.myProfile {
                        FlippingCardView(
                            isFlipped: $viewModel.isFlipped,
                            myProfile: myProfile
                        )
                    }
                }
                .padding(.bottom, 100)
                
                MenuOverlay(
                    showMenu: $viewModel.showMenu,
                    myProfile: $viewModel.myProfile
                )
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadProfile(from: myID, cards: cards)
        }
    }
}

// MARK: - View Components
extension MyProfileTabView {
    
    private var backgroundImageView: some View {
        Group {
            if let myProfile = viewModel.myProfile {
                Image(uiImage: UIImage(data: myProfile.imageData)!)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 3)
                    .frame(width: 500, height: 900)
                    .ignoresSafeArea()
            }
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 160) {
            Text("나의 카드")
                .foregroundColor(.white)
                .font(.system(size: 35))
                .bold()
            
            Button(action: {
                withAnimation(.easeInOut) {
                    viewModel.toggleMenu()
                }
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(Color("MainColor"))
                    .font(.system(size: 24))
                    .rotationEffect(Angle(degrees: 90))
                    .bold()
                    .padding()
            }
        }
        .padding(.bottom, 30)
    }
}

// MARK: - MenuOverlay
private struct MenuOverlay: View {
    @Binding var showMenu: Bool
    @Binding var myProfile: CardModel?
    @State private var goToProfileCustomView = false
    @State private var goToCategoryView = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if showMenu {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showMenu = false
                            }
                        }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Button {
                            goToProfileCustomView = true
                            showMenu = false
                        } label: {
                            Text("프로필 수정")
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.darkGray))
                                .foregroundColor(.white)
                        }
                        
                        Divider().background(Color.white)
                        
                        Button {
                            goToCategoryView = true
                            showMenu = false
                        } label: {
                            Text("취향 카테고리 수정")
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.darkGray))
                                .foregroundColor(.white)
                        }
                    }
                    .background(Color(.darkGray))
                    .cornerRadius(12)
                    .frame(width: 160)
                    .shadow(radius: 5)
                    .offset(x: 60, y: -270)
                }
            }
            .navigationDestination(isPresented: $goToProfileCustomView) {
                ProfileCustomView(
                    progress: 1.0 / 4.0,
                    cardModel: myProfile,
                    isEdit: true
                )
                .onDisappear { goToProfileCustomView = false }
                .navigationBarHidden(true)
            }
            .navigationDestination(isPresented: $goToCategoryView) {
                if let profile = myProfile {
                    CategoryView(progress: 2.0 / 4.0,
                                 cardModel: profile,
                                 isEdit: true,
                                 keepGoing: $goToCategoryView
                    )
                    .navigationBarHidden(true)
                }
            }
        }
    }
}

// MARK: - FlippingCardView
private struct FlippingCardView: View {
    @Binding var isFlipped: Bool
    let myProfile: CardModel
    
    var body: some View {
        ZStack {
            FrontCardView(myProfile: myProfile)
                .opacity(isFlipped ? 0 : 1)
            BackCardView(myProfile: myProfile)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .onTapGesture {
            withAnimation(.spring()) {
                isFlipped.toggle()
            }
        }
    }
}

// MARK: - FrontCardView
private struct FrontCardView: View {
    let myProfile: CardModel
    
    var body: some View {
        ZStack {
            Image(uiImage: UIImage(data: myProfile.imageData)!)
                .resizable()
                .scaledToFill()
                .frame(width: 302, height: 500)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color("CategoryColor"), lineWidth: 2)
                )
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, Color.black.opacity(0.4)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .blur(radius: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                )
            
            VStack {
                Text("D-\(myProfile.dDay)")
                    .foregroundColor(.white)
                    .opacity(0.9)
                    .font(.system(size: 32))
                    .bold()
                    .padding([.top, .trailing], 16)
                    .offset(x: 90, y: -160)
                
                HStack {
                    Text(myProfile.name)
                        .foregroundColor(.white)
                        .font(.custom("Pretendard-Bold", size: 42))
                        .offset(x: -58, y: 119)
                    
                    Text("(\(myProfile.age))")
                        .foregroundColor(.white)
                        .font(.custom("Pretendard-SemiBold", size: 14))
                        .offset(x: -56, y: 127)
                }
                
                Text(myProfile.cardDescription)
                    .font(.custom("Pretendard-Medium", size: 12.5))
                    .lineSpacing(3)
                    .foregroundColor(.white)
                    .opacity(0.7)
                    .offset(x: -65, y: 140)
                
                HStack(spacing: 19) {
                    ForEach([formattedBirthDate(from: myProfile.birthDate), (myProfile.mbti), myProfile.tag], id: \.self) { label in
                        ZStack {
                            RoundedRectangle(cornerRadius: 45)
                                .foregroundColor(Color.white)
                                .frame(width: 76, height: 29)
                                .opacity(0.25)
                            
                            Text(label)
                                .foregroundColor(.white)
                                .font(.system(size: 13))
                        }
                    }
                }
                .offset(x: 0, y: 160)
                
                Text("카드를 클릭하면 뒷면이 보입니다.")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: 0x6F6F6F))
                    .offset(y: 200)
            }
        }
    }
}

// MARK: - BackCardView
private struct BackCardView: View {
    let myProfile: CardModel
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(.white)
                    .opacity(0.7)
                    .frame(width: 302, height: 500)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 1.5)
                    )
                
                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.white)
                            .opacity(0.6)
                            .frame(width: 135, height: 194)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                        
                        VStack(spacing: 10) {
                            ZStack{
                                Rectangle()
                                    .foregroundColor(Color("MainColor"))
                                    .frame(width: 54, height: 20)
                                    .offset(x: -22)
                                
                                Text("김민정 님의 음악")
                                    .font(.custom("Pretendard-Medium", size: 14))
                                    .foregroundColor(.black)
                            }
                            Image("MyProfileTabView_Music")
                                .resizable()
                                .frame(width: 100, height: 100)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 7)
                                    .foregroundColor(.gray)
                                    .opacity(0.1)
                                    .frame(width: 121, height: 25)
                                
                                Text("백예린 - Antifreeze")
                                    .font(.custom("Pretendard", size: 12))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
                .offset(x: -70, y: -130)
                
                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.white)
                            .opacity(0.6)
                            .frame(width: 133, height: 107)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                        
                        VStack {
                            Text("요즘 빠진 취미")
                                .font(.custom("Pretendard-Medium", size: 14))
                                .foregroundColor(.black)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 7)
                                    .foregroundColor(.gray)
                                    .opacity(0.1)
                                    .frame(width: 121, height: 25)
                                
                                Text("# 다이어리 쓰기")
                                    .font(.custom("Pretendard", size: 11))
                                    .foregroundColor(.black)
                            }
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 7)
                                    .foregroundColor(.gray)
                                    .opacity(0.1)
                                    .frame(width: 121, height: 25)
                                
                                Text("# 키링, 인형 모으기")
                                    .font(.custom("Pretendard", size: 11))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
                .offset(x: 70, y: -174)
                
                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.white)
                            .opacity(0.6)
                            .frame(width: 133, height: 79)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                        
                        VStack {
                            Text("자주 가는 장소")
                                .font(.custom("Pretendard-Medium", size: 14))
                                .foregroundColor(.black)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .foregroundColor(.gray)
                                    .opacity(0.1)
                                    .frame(width: 121, height: 25)
                                
                                Text("포스텍 C5 6층 마루랩")
                                    .font(.custom("Pretendard", size: 11))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
                .offset(x: 70, y: -73)
                
                Image("MyProfileTabView_balance")
                    .resizable()
                    .frame(width: 274, height: 182)
                    .offset(y: 70)
                
                NavigationLink(destination: MyProfileTabDetailView(myProfile: myProfile)) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 35)
                            .fill(Color("MainColor"))
                            .frame(width: 221, height: 47)
                        
                        Text("취향 더 보러가기")
                            .font(.custom("Pretendard-SemiBold", size: 14))
                            .foregroundColor(.black)
                    }
                }
                .offset(y: 200)
            }
            
            Text("카드를 클릭하면 앞면이 보입니다.")
                .font(.custom("Pretendard", size: 16))
                .foregroundColor(Color(hex: 0x6F6F6F))
                .offset(y: 20)
        }
    }
}

// MARK: - MyProfileTabViewModel
@MainActor
class MyProfileTabViewModel: ObservableObject {
    @Published var showMenu = false
    @Published var isFlipped = false
    @Published var myProfile: CardModel? = nil
    
    func toggleMenu() {
        showMenu.toggle()
    }
    
    func toggleFlip() {
        isFlipped.toggle()
    }
    
    func loadProfile(from myIDs: [MyUUID], cards: [CardModel]) {
        guard let lastID = myIDs.last?.id else { return }
        myProfile = findMyProfile(cards: cards, id: lastID)
    }
    
    private func findMyProfile(cards: [CardModel], id: UUID) -> CardModel? {
        return cards.first { $0.id == id }
    }
}

// MARK: - Helper Functions
private func formattedBirthDate(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM.dd"
    return formatter.string(from: date)
}
