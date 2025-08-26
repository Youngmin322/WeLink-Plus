//
//  CategoryView.swift
//  WeLink
//
//  Created by Youngmin Cho on 8/6/25.
//

import SwiftUI
import SwiftData

struct CategoryView: View {
    let progress: CGFloat
    let cardModel: CardModel
    let isEdit: Bool
    let keepGoing: Binding<Bool>?
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = CategoryViewModel()
    
    init(progress: CGFloat, cardModel: CardModel, isEdit: Bool, keepGoing: Binding<Bool>? = nil) {
        self.progress = progress
        self.cardModel = cardModel
        self.isEdit = isEdit
        self.keepGoing = keepGoing
    }
    
    var body: some View {
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            VStack {
                progressBarView
                backButtonView
                headerView
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(viewModel.categories.mainTopicsList, id: \.self) { title in
                            if let topic = viewModel.categories.mainTopics[title] {
                                CategoryButton(
                                    topic: topic,
                                    viewModel: viewModel
                                )
                            }
                        }
                    }
                    .frame(width: 360)
                    .padding(.bottom)
                }
                
                if viewModel.isReady {
                    nextButtonView
                }
            }
            .padding(.bottom, isEdit ? 55 : 0)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - View Components
extension CategoryView {
    
    private var progressBarView: some View {
        ZStack(alignment: .leading) {
            let barWidth: CGFloat = 324
            let barHeight: CGFloat = 2
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.4))
                .frame(width: barWidth, height: barHeight)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color("MainColor"))
                .frame(width: barWidth * progress, height: barHeight)
        }
        .padding(.bottom, 20)
    }
    
    private var backButtonView: some View {
        let backButtonWidth: CGFloat = 20
        return HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 28))
                    .frame(width: backButtonWidth, alignment: .leading)
                    .foregroundColor(Color("MainColor"))
            }
            Spacer()
        }
        .padding(.bottom, 20)
        .frame(width: 330)
    }
    
    private var headerView: some View {
        VStack {
            let textWidth: CGFloat = 324
            
            Text("요즘 어떤 것에 관심이 있으신가요?\n카테고리를 선택해주세요.")
                .frame(width: textWidth, alignment: .leading)
                .foregroundColor(.white)
                .font(.system(size: 22, weight: .bold))
                .padding(.bottom, 2)
            
            Text("최대 3개까지 선택해주세요.")
                .frame(width: textWidth, alignment: .leading)
                .foregroundColor(Color("MainColor"))
                .font(.system(size: 16, weight: .semibold))
        }
        .padding(.bottom)
    }
    
    private var nextButtonView: some View {
        let nextButtonWidth: CGFloat = 310
        let nextButtonHeight: CGFloat = 25
        
        return NavigationLink {
            if isEdit {
                CategoryDetailedView(
                    progress: 3.0 / 4.0,
                    isEdit: isEdit,
                    selectedTopics: viewModel.selectedTopics,
                    categories: viewModel.categories,
                    cardModel: .constant(cardModel),
                    keepGoing: keepGoing
                )
            } else {
                CategoryDetailedView(
                    progress: 3.0 / 4.0,
                    isEdit: isEdit,
                    selectedTopics: viewModel.selectedTopics,
                    categories: viewModel.categories,
                    cardModel: .constant(cardModel)
                )
            }
        } label: {
            Text("다음")
                .font(.headline)
                .foregroundColor(.black)
                .frame(width: nextButtonWidth, height: nextButtonHeight)
                .padding()
                .background(viewModel.isReady ? Color("MainColor") : Color.gray)
                .clipShape(Capsule())
        }
        .disabled(viewModel.selectedTopics.count == 0)
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    @ObservedObject var topic: mainTopic
    @ObservedObject var viewModel: CategoryViewModel
    
    let boxSize: CGFloat = 155
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectTopic(topic)
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(topic.isSelected ? Color("MainColor") : Color("CategoryColor"))
                    .frame(width: boxSize, height: boxSize)
                
                VStack(spacing: 8) {
                    Text(topic.emoji)
                    Text(topic.title)
                        .font(.headline)
                        .foregroundColor(topic.isSelected ? .black : .white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    let testCardModel = CardModel(
        id: UUID(),
        name: "테스트 사용자",
        age: 25,
        description: "테스트 설명",
        birthDate: "1999-01-01",
        mbti: "ENFP",
        tag: "일반",
        dDay: 100,
        imageData: Data()
    )
    
    CategoryView(
        progress: 3.0 / 5.0,
        cardModel: testCardModel,
        isEdit: false
    )
}
