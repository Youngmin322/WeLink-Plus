//
//  CardViewModel.swift
//  WeLink
//
//  Created by Youngmin Cho on 8/26/25.
//

import Foundation
import SwiftData
import UIKit

@MainActor
class CardViewModel: ObservableObject {
    @Published var cards: [CardModel] = []
    @Published var myCards: [MyUUID] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let cardDataService: CardDataService
    
    init(context: ModelContext) {
        self.cardDataService = CardDataService(context: context)
    }
    
    // MARK: - Card Operations
    func addCard(_ card: CardModel) {
        cardDataService.insertCard(card)
    }
    
    func deleteCard(_ card: CardModel) {
        cardDataService.deleteCard(card)
    }
    
    func updateCard(_ card: CardModel) {
        cardDataService.saveContext()
    }
    
    // MARK: - My Card Management
    func findMyCard(from allCards: [CardModel], myIDs: [MyUUID]) -> CardModel? {
        guard let myUUID = myIDs.last?.id else { return nil }
        return allCards.first { $0.id == myUUID }
    }
    
    // MARK: - Card Filtering
    func filterCards(from allCards: [CardModel], myIDs: [MyUUID], searchText: String = "") -> [CardModel] {
        guard let myUUID = myIDs.last?.id else {
            return filterBySearchText(cards: allCards, searchText: searchText)
        }
        
        let filteredCards = allCards.filter { $0.id != myUUID }
        return filterBySearchText(cards: filteredCards, searchText: searchText)
    }
    
    private func filterBySearchText(cards: [CardModel], searchText: String) -> [CardModel] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return cards
        } else {
            return cards.filter { card in
                card.name.localizedCaseInsensitiveContains(searchText.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
    }
    
    // MARK: - Date and Age Calculations
    func calculateAge(from birthDateString: String) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let birthDate = formatter.date(from: birthDateString) else {
            return nil
        }
        
        let calendar = Calendar.current
        let birthYear = calendar.component(.year, from: birthDate)
        let currentYear = calendar.component(.year, from: Date())
        
        return currentYear - birthYear + 1
    }
    
    func calculateDaysUntilBirthday(from birthDateString: String) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let birthDate = formatter.date(from: birthDateString) else {
            return nil
        }
        
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
    
    // MARK: - Birthday Helpers
    func getBirthdayCards(from cards: [CardModel], for date: Date) -> [CardModel] {
        let calendar = Calendar.current
        let selMonth = calendar.component(.month, from: date)
        let selDay = calendar.component(.day, from: date)
        
        return cards.filter {
            guard let bd = $0.birthDateAsDate else { return false }
            let bMonth = calendar.component(.month, from: bd)
            let bDay = calendar.component(.day, from: bd)
            return bMonth == selMonth && bDay == selDay
        }
    }
    
    func hasBirthday(cards: [CardModel], on date: Date) -> Bool {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        return cards.contains {
            guard let bd = $0.birthDateAsDate else { return false }
            return calendar.component(.month, from: bd) == month &&
                   calendar.component(.day, from: bd) == day
        }
    }
    
    // MARK: - Dummy Data
    func insertDummyCardsIfNeeded(allCards: [CardModel]) {
        if allCards.isEmpty {
            cardDataService.insertDummyCards()
        }
    }
}
