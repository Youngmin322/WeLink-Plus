//
//  CategoryDetailedView.swift
//  WeLink
//
//  Created by 럭스(양광모) on 8/6/25.
//

import SwiftUI

struct CategoryDetailedView: View {
    var progress: CGFloat
    var isEdit: Bool
    @State var selectedTopics: [mainTopic]
    @ObservedObject var categories: Category
    @Binding var cardModel: CardModel
    var keepGoing: Binding<Bool>? = nil
    
    @StateObject private var viewModel: CategoryDetailedViewModel
    @Environment(\.dismiss) var dismiss
    
    init(progress: CGFloat, isEdit: Bool, selectedTopics: [mainTopic], categories: Category, cardModel: Binding<CardModel>, keepGoing: Binding<Bool>? = nil) {
        self.progress = progress
        self.isEdit = isEdit
        self.selectedTopics = selectedTopics
        self.categories = categories
        self._cardModel = cardModel
        self.keepGoing = keepGoing
        self._viewModel = StateObject(wrappedValue: CategoryDetailedViewModel(selectedTopics: selectedTopics))
    }
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            VStack {
                progressBarView
                backButtonView
                headerView
                topicButtonsView
                
                ScrollView {
                    subTopicsView
                }
                
                if viewModel.isDetailedSelectionReady {
                    nextButtonView
                }
            }
            .padding(.bottom, isEdit ? 55 : 0)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - View Components
extension CategoryDetailedView {
    
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
                viewModel.resetSelections()
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 28))
                    .frame(width: backButtonWidth, alignment: .leading)
                    .foregroundColor(Color("MainColor"))
            }
            Spacer()
        }
        .frame(width: 330)
        .padding(.bottom, 20)
    }
    
    private var headerView: some View {
        VStack {
            let textWidth: CGFloat = 324
            
            Text("조금 더 구체적으로 알려주세요!")
                .frame(width: textWidth, alignment: .leading)
                .foregroundColor(.white)
                .font(.custom("Pretendard-Bold", size: 22))
                .padding(.bottom, 1)
            
            Text("최소 1개에서 최대 10개까지 선택해주세요.")
                .frame(width: textWidth, alignment: .leading)
                .foregroundColor(Color("MainColor"))
                .font(.custom("Pretendard-Bold", size: 14))
        }
        .padding(.bottom)
    }
    
    private var topicButtonsView: some View {
        HStack(spacing: 10) {
            ForEach(Array(selectedTopics.enumerated()), id: \.element.id) { index, topic in
                CategoryDetailButton(
                    topic: topic,
                    selectedTopics: selectedTopics,
                    viewModel: viewModel,
                    index: index
                )
            }
        }
        .padding(.bottom, 20)
    }
    
    private var subTopicsView: some View {
        ZStack {
            let subTopicDict: [String: subTopic] = selectedTopics[viewModel.currentIndex].children
            let sectionWidth: CGFloat = 375.0
            
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CategoryColor"))
                .frame(width: sectionWidth, height: viewModel.sectionTotalHeights[viewModel.currentIndex])
            
            VStack(spacing: 0) {
                ForEach(Array(subTopicDict.values.sorted{ $0.title < $1.title }.enumerated()), id: \.1.title) { index, subTopic in
                    SectionView(
                        subTopic: subTopic,
                        width: sectionWidth,
                        viewModel: viewModel,
                        sectionIndex: viewModel.currentIndex
                    )
                    if index < subTopicDict.count - 1 {
                        Divider().background(Color.gray)
                            .padding(.vertical, 0)
                    }
                }
            }
            .frame(width: sectionWidth, alignment: .topLeading)
        }
    }
    
    private var nextButtonView: some View {
        let nextButtonWidth: CGFloat = 310
        let nextButtonHeight: CGFloat = 25
        
        let nextView = isEdit ? AnyView(MyProfileTabDetailView(myProfile: cardModel)) : AnyView(SettingCompleteView(
            progress: 5.0 / 5.0,
            cardModel: cardModel
        ))
        
        return NavigationLink(destination: nextView) {
            let text = isEdit ? "완료" : "다음"
            Text(text)
                .font(.headline)
                .foregroundColor(.black)
                .frame(width: nextButtonWidth, height: nextButtonHeight)
                .padding()
                .background(Color("MainColor"))
                .clipShape(Capsule())
        }
        .simultaneousGesture(TapGesture().onEnded {
            viewModel.updateCardWithTopics(cardModel)
            if isEdit {
                keepGoing?.wrappedValue = false
            }
        })
    }
}

// MARK: - Supporting Views
struct CategoryDetailButton: View {
    let topic: mainTopic
    let selectedTopics: [mainTopic]
    @ObservedObject var viewModel: CategoryDetailedViewModel
    let index: Int
    
    let boxSize: CGFloat = 115
    
    var body: some View {
        Button(action: {
            viewModel.switchCurrentIndex(to: index)
        }) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(topic.isSelected ? Color("MainColor") : Color("CategoryColor"))
                    .frame(width: boxSize, height: boxSize)
                
                VStack(spacing: 8) {
                    Text(topic.emoji)
                    Text(topic.title)
                        .font(.custom("Pretendard-Medium", size: 16))
                        .foregroundColor(topic.isSelected ? .black : .white)
                }
                .frame(maxWidth: boxSize, maxHeight: boxSize)
            }
        }
    }
}

struct SectionView: View {
    let subTopic: subTopic
    let width: CGFloat
    @ObservedObject var viewModel: CategoryDetailedViewModel
    let sectionIndex: Int
    
    let buttonWidth: CGFloat = 110
    let buttonHeight: CGFloat = 48
    
    var body: some View {
        let numRows: Int = ((subTopic.children.count-1) / 3) + 1
        let height: CGFloat = (buttonHeight + 15.0) * CGFloat(numRows) + 50.0
        
        let detailedTopics: [detailedTopic] = subTopic.children.values.sorted { $0.title < $1.title }
        
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CategoryColor"))
                .frame(width: width, height: height)
            VStack {
                HStack(spacing: 0) {
                    Text("#")
                        .foregroundColor(Color("MainColor"))
                        .bold()
                        .font(.system(size: 25, weight: .bold))
                    Text(subTopic.title)
                        .foregroundColor(Color(.white))
                        .bold()
                        .font(.system(size: 20, weight: .bold))
                }
                .padding(.top, 20)
                
                let columns = [
                    GridItem(.fixed(buttonWidth), alignment: .center),
                    GridItem(.fixed(buttonWidth), alignment: .center),
                    GridItem(.fixed(buttonWidth), alignment: .center)
                ]
                
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(detailedTopics, id: \.title) { detailedTopic in
                        detailedTopicButton(
                            topic: detailedTopic,
                            width: buttonWidth,
                            height: buttonHeight,
                            viewModel: viewModel,
                            sectionIndex: sectionIndex
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .onAppear {
            viewModel.updateSectionHeight(height, for: sectionIndex)
        }
    }
}

struct detailedTopicButton: View {
    @ObservedObject var topic: detailedTopic
    let width: CGFloat
    let height: CGFloat
    @ObservedObject var viewModel: CategoryDetailedViewModel
    let sectionIndex: Int
    
    var body: some View {
        Button(action: {
            viewModel.selectDetailedTopic(topic, in: sectionIndex)
        }) {
            ZStack {
                Capsule()
                    .fill(topic.isSelected ? Color("DetailedCategoryColor") : Color("BackgroundColor"))
                    .stroke(topic.isSelected ? Color("MainColor") : Color.clear, lineWidth: 2)
                    .frame(width: width, height: height)
                
                Text(topic.title)
                    .font(.custom("Pretendard-Medium", size: 15))
                    .foregroundColor(topic.isSelected ? Color("MainColor") : Color("CategoryKeyword"))
            }
        }
        .frame(width: width, height: height)
    }
}

// MARK: - CategoryDetailedViewModel
@MainActor
class CategoryDetailedViewModel: ObservableObject {
    @Published var currentIndex: Int = 0
    @Published var selectedDetailedTopicsList: [[detailedTopic]] = [[], [], []]
    @Published var sectionTotalHeights: [CGFloat] = [0, 0, 0]
    
    private let selectedTopics: [mainTopic]
    
    init(selectedTopics: [mainTopic]) {
        self.selectedTopics = selectedTopics
        // 첫 번째 토픽을 선택된 상태로 설정
        if !selectedTopics.isEmpty {
            selectedTopics[0].isSelected = true
        }
    }
    
    var isDetailedSelectionReady: Bool {
        selectedDetailedTopicsList.prefix(selectedTopics.count).allSatisfy { !$0.isEmpty }
    }
    
    func selectDetailedTopic(_ topic: detailedTopic, in sectionIndex: Int) {
        if !(selectedDetailedTopicsList[sectionIndex].count == 10 && !topic.isSelected) {
            topic.isSelected.toggle()
            updateSelectedDetailedTopicList(in: sectionIndex, tgt: topic)
        }
    }
    
    func switchCurrentIndex(to newIndex: Int) {
        if currentIndex != newIndex {
            sectionTotalHeights[currentIndex] = 0
        }
        
        selectedTopics[currentIndex].isSelected = false
        selectedTopics[newIndex].isSelected = true
        currentIndex = newIndex
    }
    
    func updateSectionHeight(_ height: CGFloat, for index: Int) {
        if index < sectionTotalHeights.count {
            sectionTotalHeights[index] += height
        }
    }
    
    func updateCardWithTopics(_ card: CardModel) {
        sectionTotalHeights = [0, 0, 0]
        card.topics = []
        for topic in selectedTopics {
            card.topics.append(topic)
        }
    }
    
    func resetSelections() {
        for item in selectedDetailedTopicsList {
            for detailedTopic in item {
                detailedTopic.isSelected.toggle()
            }
        }
        sectionTotalHeights = [0, 0, 0]
    }
    
    private func updateSelectedDetailedTopicList(in sectionIndex: Int, tgt: detailedTopic) {
        if tgt.isSelected {
            selectedDetailedTopicsList[sectionIndex].append(tgt)
        } else {
            selectedDetailedTopicsList[sectionIndex].removeAll { $0.title == tgt.title }
        }
    }
}
