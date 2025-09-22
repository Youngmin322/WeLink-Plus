//
//  CalendarViewModel.swift
//  WeLink
//
//  Created by Youngmin Cho on 9/11/25.
//

import SwiftUI
import Foundation
import SwiftData

class CalendarSegmentViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedDate = Date()
    @Published var currentMonth = Date()
    
    // MARK: - Private Properties
    private let calendar = Calendar.current
    private let startYear = 2025
    private let endYear = 2034
    private var modelContext: ModelContext
    
    // MARK: - Computed Properties
    
    var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월"
        return formatter
    }
    
    var weekdays: [String] {
        return [
            "월",
            "화",
            "수",
            "목",
            "금",
            "토",
            "일",
        ]
    }
    
    var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(
            of: .month,
            for: currentMonth
        ) else {
            return []
        }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        
        let adjustedFirstWeekday = (firstWeekday + 5) % 7
        
        var days: [Date] = []
        
        if adjustedFirstWeekday > 0 {
            for dayOffset in (1...adjustedFirstWeekday).reversed() {
                if let previousDate = calendar.date(
                    byAdding: .day,
                    value: -dayOffset,
                    to: firstOfMonth
                ) {
                    days.append(previousDate)
                }
            }
        }
        
        let numberOfDays = calendar.range(
            of: .day,
            in: .month,
            for: currentMonth
        )?.count ?? 0
        
        for day in 1...numberOfDays {
            if let date = calendar.date(
                byAdding: .day,
                value: day - 1,
                to: firstOfMonth
            ) {
                days.append(date)
            }
        }
        
        let remainingCells = 7 - (days.count % 7)
        if remainingCells < 7 {
            let lastDayOfMonth = calendar.date(
                byAdding: .day,
                value: numberOfDays - 1,
                to: firstOfMonth
            ) ?? firstOfMonth
            
            for dayOffset in 1...remainingCells {
                if let nextDate = calendar.date(
                    byAdding: .day,
                    value: dayOffset,
                    to: lastDayOfMonth
                ) {
                    days.append(nextDate)
                }
            }
        }
        
        return days
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        calendarDidInitialize()
    }
    
    // MARK: - Public Methods
    func nextMonthWasTapped() {
        guard canNavigateMonth(1) else { return }
        
        if let newMonth = calendar.date(
            byAdding: .month,
            value: 1,
            to: currentMonth
        ) {
            DispatchQueue.main.async {
                self.currentMonth = newMonth
            }
        }
    }
    
    func previousMonthWasTapped() {
        guard canNavigateMonth(-1) else { return }
        
        if let newMonth = calendar.date(
            byAdding: .month,
            value: -1,
            to: currentMonth
        ) {
            DispatchQueue.main.async {
                self.currentMonth = newMonth
            }
        }
    }
    
    /// 날짜 선택
    func dateWasSelected(_ date: Date) {
        DispatchQueue.main.async {
            // 선택된 날짜가 현재 월과 다른 월인지 확인
            let isDateInCurrentMonth = self.calendar.isDate(
                date,
                equalTo: self.currentMonth,
                toGranularity: .month
            )
            
            // 다른 월의 날짜라면 해당 월로 이동
            if !isDateInCurrentMonth {
                let selectedYear = self.calendar.component(.year, from: date)
                let selectedMonth = self.calendar.component(.month, from: date)
                
                // 해당 월로 currentMonth 업데이트
                if let newMonth = self.createDate(year: selectedYear, month: selectedMonth, day: 1) {
                    // 년도 범위 체크
                    if selectedYear >= self.startYear && selectedYear <= self.endYear {
                        self.currentMonth = newMonth
                    }
                }
            }
            
            self.selectedDate = date
        }
    }
    
    func cellTextColor(
        for date: Date,
        isSelected: Bool,
        isToday: Bool,
        isCurrentMonth: Bool
    ) -> Color {
        if isSelected {
            return .white
        }
        
        if !isCurrentMonth {
            return Color(hex: "#919191").opacity(0.3)
        }
        
        return Color(hex: "#919191")
    }
    
    func cellBackgroundColor(
        isSelected: Bool,
        isToday: Bool
    ) -> Color {
        if isSelected {
            return .black.opacity(0.6)
        }
        
        if isToday {
            return .clear
        }
        
        return .clear
    }
    
    /// 월 탐색 가능 여부 확인
    func canNavigateMonth(_ direction: Int) -> Bool {
        guard let targetMonth = calendar.date(
            byAdding: .month,
            value: direction,
            to: currentMonth
        ) else {
            return false
        }
        
        let targetYear = calendar.component(.year, from: targetMonth)
        return targetYear >= startYear && targetYear <= endYear
    }
    
    // MARK: - Private Methods
    
    /// 캘린더를 초기화하는 함수
    private func calendarDidInitialize() {
        let currentYear = calendar.component(.year, from: Date())
        let currentMonthNumber = calendar.component(.month, from: Date())
        
        if currentYear < startYear {
            self.currentMonth = createDate(
                year: startYear,
                month: 1,
                day: 1
            ) ?? Date()
        } else if currentYear > endYear {
            self.currentMonth = createDate(
                year: endYear,
                month: 12,
                day: 1
            ) ?? Date()
        } else {
            // 현재 년도가 범위 내에 있을 때는 현재 월을 사용
            self.currentMonth = createDate(
                year: currentYear,
                month: currentMonthNumber,
                day: 1
            ) ?? Date()
        }
    }
    
    /// 날짜 생성
    private func createDate(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)
    }
}
