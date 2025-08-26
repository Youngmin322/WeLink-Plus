//
//  MyProfileViewModel.swift
//  WeLink
//
//  Created by Youngmin Cho on 8/26/25.
//

import Foundation
import SwiftData
import UIKit

@MainActor
class MyProfileViewModel: ObservableObject {
    @Published var showMenu = false
    @Published var isFlipped = false
    @Published var currentTopic: mainTopic?
    
    @Published var name: String = ""
    @Published var birthDate: String = ""
    @Published var nickname: String = ""
    @Published var introduction: String = ""
    @Published var mbti: String = ""
    @Published var job: String = ""
    @Published var selectedImage: UIImage?
    @Published var birthDateError: Bool = false
    @Published var goNext: Bool = false
    
    enum FocusField: Hashable {
        case name, birthDate, nickname, introduction, mbti, job
    }
    
    private let cardViewModel: CardViewModel
    
    init(cardViewModel: CardViewModel) {
        self.cardViewModel = cardViewModel
    }
    
    // MARK: - Menu Management
    func toggleMenu() {
        showMenu.toggle()
    }
    
    func closeMenu() {
        showMenu = false
    }
    
    // MARK: - Card Flip
    func toggleFlip() {
        isFlipped.toggle()
    }
    
    // MARK: - Topic Management
    func initializeTopic(with card: CardModel) {
        guard !card.topics.isEmpty else { return }
        
        for topic in card.topics {
            topic.isSelected = false
        }
        currentTopic = card.topics[0]
        currentTopic?.isSelected = true
    }
    
    func switchTopic(to newTopic: mainTopic) {
        currentTopic?.isSelected = false
        newTopic.isSelected = true
        currentTopic = newTopic
    }
    
    func findLastSubTopicKey(for currentTopic: mainTopic) -> String {
        let sortedKeys = currentTopic.children.keys.sorted {
            currentTopic.children[$0]!.title < currentTopic.children[$1]!.title
        }
        
        var lastSubTopicToShow = ""
        
        for key in sortedKeys {
            let detailedTopics = Array(currentTopic.children[key]!.children.values)
            
            for topic in detailedTopics {
                if topic.isSelected {
                    lastSubTopicToShow = key
                }
            }
        }
        return lastSubTopicToShow
    }
    
    // MARK: - Profile Form Validation
    func validateBirthDate(_ newValue: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        if formatter.date(from: newValue) != nil {
            birthDateError = false
        } else {
            birthDateError = true
        }
    }
    
    func isFormReady() -> Bool {
        return !name.isEmpty &&
               !birthDate.isEmpty &&
               !nickname.isEmpty &&
               !introduction.isEmpty &&
               !mbti.isEmpty &&
               !job.isEmpty &&
               selectedImage != nil
    }
    
    // MARK: - Card Operations
    func updateExistingCard(_ card: CardModel) {
        guard let age = cardViewModel.calculateAge(from: birthDate),
              let dDay = cardViewModel.calculateDaysUntilBirthday(from: birthDate),
              let imageData = selectedImage?.pngData() else { return }
        
        card.name = name
        card.age = age
        card.cardDescription = introduction
        card.birthDate = birthDate
        card.mbti = mbti
        card.tag = job
        card.dDay = dDay
        card.imageData = imageData
        
        cardViewModel.updateCard(card)
    }
    
    func createNewCard(with myID: MyUUID) -> CardModel? {
        guard let age = cardViewModel.calculateAge(from: birthDate),
              let dDay = cardViewModel.calculateDaysUntilBirthday(from: birthDate),
              let imageData = selectedImage?.pngData() else { return nil }
        
        return CardModel(
            id: myID.id,
            name: name,
            age: age,
            description: introduction,
            birthDate: birthDate,
            mbti: mbti,
            tag: job,
            dDay: dDay,
            imageData: imageData
        )
    }
    
    // MARK: - Helper Methods
    func findMyProfile(cards: [CardModel], id: UUID) -> CardModel? {
        return cards.first { $0.id == id }
    }
    
    func loadProfileData(from card: CardModel) {
        name = card.name
        birthDate = card.birthDate
        nickname = card.name // assuming nickname is same as name
        introduction = card.cardDescription
        mbti = card.mbti
        job = card.tag
        
        if !card.imageData.isEmpty {
            selectedImage = UIImage(data: card.imageData)
        }
    }
    
    func resetForm() {
        name = ""
        birthDate = ""
        nickname = ""
        introduction = ""
        mbti = ""
        job = ""
        selectedImage = nil
        birthDateError = false
        goNext = false
    }
}
