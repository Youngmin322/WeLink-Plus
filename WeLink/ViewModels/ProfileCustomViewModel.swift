//
//  ProfileCustomViewModel.swift
//  WeLink
//
//  Created by Youngmin Cho on 9/8/25.
//

import Foundation
import SwiftUI
import SwiftData
import PhotosUI

@MainActor
class ProfileCustomViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var birthDate = Date()
    @Published var nickname: String = ""
    @Published var introduction: String = ""
    @Published var mbti: String = ""
    @Published var job: String = ""
    @Published var showPicker = false
    @Published var selectedImage: UIImage?
    @Published var showDatePicker = false
    @Published var cardModel: CardModel?
    @Published var goNext: Bool = false
    
    private let isEdit: Bool
    private let myID: MyUUID
    
    enum FocusField: Hashable {
        case name, nickname, introduction, mbti, job
    }
    
    init(cardModel: CardModel? = nil, isEdit: Bool) {
        self.isEdit = isEdit
        self.cardModel = cardModel
        
        if let cardModel = cardModel {
            self.myID = isEdit ? MyUUID(id: cardModel.id) : MyUUID(id: UUID())
            loadExistingCardData(cardModel)
        } else {
            self.myID = MyUUID(id: UUID())
        }
    }
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        !name.isEmpty &&
        !nickname.isEmpty &&
        !introduction.isEmpty &&
        !mbti.isEmpty &&
        !job.isEmpty &&
        selectedImage != nil
    }
    
    var calculatedAge: Int {
        calculateAgeByYear(from: birthDate)
    }
    
    var calculatedDDay: Int {
        calculateDaysUntilBirthday(from: birthDate)
    }
    
    var formattedBirthDate: String {
        formatDateToString(birthDate)
    }
    
    // MARK: - Private Helper Methods
    private func loadExistingCardData(_ card: CardModel) {
        name = card.name
        nickname = card.name
        introduction = card.cardDescription
        mbti = card.mbti
        job = card.tag
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        birthDate = formatter.date(from: card.birthDate) ?? Date()
        
        if !card.imageData.isEmpty {
            selectedImage = UIImage(data: card.imageData)
        }
    }
    
    private func calculateAgeByYear(from birthDate: Date) -> Int {
        let calendar = Calendar.current
        let birthYear = calendar.component(.year, from: birthDate)
        let currentYear = calendar.component(.year, from: Date())
        return currentYear - birthYear + 1
    }
    
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
    
    private func formatDateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    // MARK: - Public Methods
    func saveProfile(context: ModelContext) {
        guard let imageData = selectedImage?.pngData() else { return }
        
        if isEdit, let existingCard = cardModel {
            updateExistingCard(existingCard, imageData: imageData)
        } else {
            createNewCard(context: context, imageData: imageData)
        }
        
        goNext = true
    }
    
    private func updateExistingCard(_ card: CardModel, imageData: Data) {
        card.name = name
        card.age = calculatedAge
        card.cardDescription = introduction
        card.birthDate = formattedBirthDate
        card.mbti = mbti
        card.tag = job
        card.dDay = calculatedDDay
        card.imageData = imageData
    }
    
    private func createNewCard(context: ModelContext, imageData: Data) {
        cardModel = CardModel(
            id: myID.id,
            name: name,
            age: calculatedAge,
            description: introduction,
            birthDate: formattedBirthDate,
            mbti: mbti,
            tag: job,
            dDay: calculatedDDay,
            imageData: imageData
        )
        
        context.insert(myID)
        try? context.save()
    }
    
    // MARK: - UI Actions
    func toggleShowPicker() {
        showPicker.toggle()
    }
    
    func toggleDatePicker() {
        showDatePicker.toggle()
    }
}
