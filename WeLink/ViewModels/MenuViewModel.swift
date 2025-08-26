//
//  MenuViewModel.swift
//  WeLink
//
//  Created by Youngmin Cho on 8/26/25.
//

import Foundation
import SwiftUI

@MainActor
class MenuViewModel: ObservableObject {
    @Published var selectedDate: Date? = Date()
    @Published var memoText: String = ""
    @Published var isMemoSheetPresented: Bool = false
    @Published var selectedWriter: String = "Karina"
    @Published var currentMonth: Date = Date()
    @Published var memoStore = MemoStore()
    
    private let cardViewModel: CardViewModel
    
    let writers = ["Karina", "Ning ning", "Winter", "Giselle"]
    
    init(cardViewModel: CardViewModel) {
        self.cardViewModel = cardViewModel
    }
    
    // MARK: - Date Management
    func changeMonth(_ value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
    }
    
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: currentMonth)
    }
    
    // MARK: - Calendar Data
    var days: [Date] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        
        let startDate = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: startDate) - 1
        
        var days: [Date] = []
        for _ in 0..<firstWeekday {
            days.append(Date.distantPast)
        }
        
        var day = startDate
        while day < monthInterval.end {
            days.append(day)
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
        
        return days
    }
    
    var memoDates: Set<Date> {
        Set(memoStore.memos.keys)
    }
    
    // MARK: - Birthday Management
    func getBirthdayCards(cards: [CardModel]) -> [CardModel] {
        guard let selectedDate = selectedDate else { return [] }
        return cardViewModel.getBirthdayCards(from: cards, for: selectedDate)
    }
    
    func hasBirthday(cards: [CardModel], on date: Date) -> Bool {
        return cardViewModel.hasBirthday(cards: cards, on: date)
    }
    
    // MARK: - Memo Management
    func showMemoSheet() {
        if selectedDate == nil {
            selectedDate = Date()
        }
        memoText = ""
        selectedWriter = "Karina"
        isMemoSheetPresented = true
    }
    
    func saveMemo() {
        guard let date = selectedDate else { return }
        
        let trimmedText = memoText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        var memoList = memoStore.memos[date] ?? []
        memoList.append((text: trimmedText, writer: selectedWriter))
        memoStore.memos[date] = memoList
        
        isMemoSheetPresented = false
    }
    
    func getMemos(for date: Date) -> [(text: String, writer: String)]? {
        return memoStore.memos[date]
    }
    
    // MARK: - Date Picker Management
    func updateSelectedDateFromPicker(month: Int, day: Int) {
        guard let currentDate = selectedDate else { return }
        
        var components = Calendar.current.dateComponents([.year], from: currentDate)
        components.month = month
        components.day = day
        
        if let newDate = Calendar.current.date(from: components) {
            selectedDate = newDate
        }
    }
    
    // MARK: - Helper Methods
    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    func isSelected(_ date: Date) -> Bool {
        guard let selectedDate = selectedDate else { return false }
        return Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    func hasMemo(on date: Date) -> Bool {
        return memoDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
    }
}

// MARK: - MemoStore
class MemoStore: ObservableObject {
    @Published var memos: [Date: [(text: String, writer: String)]] = [:]
}
