//
//  CategoryViewModel.swift
//  WeLink
//
//  Created by Youngmin Cho on 8/26/25.
//

import Foundation
import SwiftUI

@MainActor
class CategoryViewModel: ObservableObject {
    @Published var categories = Category()
    @Published var selectedTopics: [mainTopic] = []
    @Published var selectedDetailedTopicsList: [[detailedTopic]] = [[], [], []]
    @Published var sectionTotalHeights: [CGFloat] = [0, 0, 0]
    @Published var currentIndex: Int = 0
    @Published var isReady: Bool = false
    
    // MARK: - Topic Selection
    func selectTopic(_ topic: mainTopic) {
        if !(selectedTopics.count == 3 && !topic.isSelected) {
            topic.isSelected.toggle()
            updateSelectedTopicList(tgt: topic)
        }
        isReady = (selectedTopics.count > 0 && selectedTopics.count < 4)
    }
    
    func selectDetailedTopic(_ topic: detailedTopic, in sectionIndex: Int) {
        if !(selectedDetailedTopicsList[sectionIndex].count == 10 && !topic.isSelected) {
            topic.isSelected.toggle()
            updateSelectedDetailedTopicList(in: sectionIndex, tgt: topic)
        }
    }
    
    // MARK: - Helper Methods
    private func updateSelectedTopicList(tgt: mainTopic) {
        if tgt.isSelected {
            let newTopic = mainTopic(title: tgt.title, emoji: tgt.emoji, children: tgt.children, isSelected: false)
            selectedTopics.append(newTopic)
        } else {
            selectedTopics.removeAll { $0.title == tgt.title }
        }
        
        if !selectedTopics.isEmpty {
            selectedTopics[0].isSelected = true
        }
    }
    
    private func updateSelectedDetailedTopicList(in sectionIndex: Int, tgt: detailedTopic) {
        if tgt.isSelected {
            selectedDetailedTopicsList[sectionIndex].append(tgt)
        } else {
            selectedDetailedTopicsList[sectionIndex].removeAll { $0.title == tgt.title }
        }
    }
    
    // MARK: - Section Management
    func updateSectionHeight(_ height: CGFloat, for index: Int) {
        if index < sectionTotalHeights.count {
            sectionTotalHeights[index] += height
        }
    }
    
    func resetSectionHeights() {
        sectionTotalHeights = [0, 0, 0]
    }
    
    func switchCurrentIndex(to newIndex: Int) {
        if currentIndex != newIndex {
            sectionTotalHeights[currentIndex] = 0
        }
        
        selectedTopics[currentIndex].isSelected = false
        selectedTopics[newIndex].isSelected = true
        currentIndex = newIndex
    }
    
    // MARK: - Validation
    func isDetailedSelectionReady() -> Bool {
        return selectedDetailedTopicsList.prefix(selectedTopics.count).allSatisfy { !$0.isEmpty }
    }
    
    // MARK: - Card Update
    func updateCardWithTopics(_ card: CardModel) {
        card.topics = []
        for topic in selectedTopics {
            card.topics.append(topic)
        }
    }
    
    // MARK: - Reset
    func resetSelections() {
        for item in selectedDetailedTopicsList {
            for detailedTopic in item {
                detailedTopic.isSelected.toggle()
            }
        }
        resetSectionHeights()
    }
}
