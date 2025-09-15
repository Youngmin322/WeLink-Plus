import SwiftUI
import SwiftData

struct CalendarView: View {
    @Binding var selectedDate: Date?
    var cards: [CardModel]
    var memoDates: Set<Date>
    
    @State private var currentMonth: Date = Date()
    private let calendar = Calendar.current
    
    private var weekdays: [String] {
        return ["월", "화", "수", "목", "금", "토", "일"]
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let adjustedFirstWeekday = (firstWeekday + 5) % 7
        
        var days: [Date] = []
        
        // 이전 달 날짜들
        if adjustedFirstWeekday > 0 {
            for dayOffset in (1...adjustedFirstWeekday).reversed() {
                if let previousDate = calendar.date(byAdding: .day, value: -dayOffset, to: firstOfMonth) {
                    days.append(previousDate)
                }
            }
        }
        
        // 현재 달 날짜들
        let numberOfDays = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        // 다음 달 날짜들
        let remainingCells = 7 - (days.count % 7)
        if remainingCells < 7 {
            let lastDayOfMonth = calendar.date(byAdding: .day, value: numberOfDays - 1, to: firstOfMonth) ?? firstOfMonth
            for dayOffset in 1...remainingCells {
                if let nextDate = calendar.date(byAdding: .day, value: dayOffset, to: lastDayOfMonth) {
                    days.append(nextDate)
                }
            }
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 20) {
            monthHeader
            weekdayHeader
            calendarGrid
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }
    
    private var monthHeader: some View {
        HStack {
            Button {
                changeMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text(monthYearFormatter.string(from: currentMonth))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                changeMonth(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
    
    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var calendarGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(daysInMonth, id: \.self) { date in
                dayCell(date: date)
            }
        }
    }
    
    private func dayCell(date: Date) -> some View {
        let day = calendar.component(.day, from: date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate ?? Date.distantPast)
        let isToday = calendar.isDateInToday(date)
        let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
        let hasBirthdayOnDate = hasBirthday(on: date)
        let hasMemoOnDate = memoDates.contains { calendar.isDate($0, inSameDayAs: date) }
        
        return Button {
            selectedDate = date
        } label: {
            ZStack {
                // 배경 원
                Circle()
                    .fill(cellBackgroundColor(
                        isSelected: isSelected,
                        isToday: isToday,
                        hasBirthday: hasBirthdayOnDate,
                        hasMemo: hasMemoOnDate
                    ))
                    .frame(width: 40, height: 40)
                
                // 테두리 (선택된 경우)
                if isSelected {
                    Circle()
                        .stroke(Color("MainColor"), lineWidth: 2)
                        .frame(width: 40, height: 40)
                }
                
                VStack(spacing: 2) {
                    Text("\(day)")
                        .font(.system(size: 16, weight: isToday ? .bold : .medium))
                        .foregroundColor(cellTextColor(
                            isSelected: isSelected,
                            isToday: isToday,
                            isCurrentMonth: isCurrentMonth,
                            hasBirthday: hasBirthdayOnDate,
                            hasMemo: hasMemoOnDate
                        ))
                    
                    // 표시 점들
                    HStack(spacing: 2) {
                        if hasBirthdayOnDate {
                            Circle()
                                .fill(Color("MainColor"))
                                .frame(width: 4, height: 4)
                        }
                        if hasMemoOnDate {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .frame(width: 44, height: 44)
        }
        .disabled(!isCurrentMonth)
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월"
        return formatter
    }
    
    private func changeMonth(_ value: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
                currentMonth = newMonth
            }
        }
    }
    
    private func hasBirthday(on date: Date) -> Bool {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return cards.contains {
            guard let bd = $0.birthDateAsDate else { return false }
            return calendar.component(.month, from: bd) == month &&
                   calendar.component(.day, from: bd) == day
        }
    }
    
    private func cellTextColor(
        isSelected: Bool,
        isToday: Bool,
        isCurrentMonth: Bool,
        hasBirthday: Bool,
        hasMemo: Bool
    ) -> Color {
        if !isCurrentMonth {
            return .clear
        }
        
        if isSelected {
            return .white
        }
        
        if isToday {
            return Color("MainColor")
        }
        
        if hasBirthday || hasMemo {
            return .white
        }
        
        return .white.opacity(0.8)
    }
    
    private func cellBackgroundColor(
        isSelected: Bool,
        isToday: Bool,
        hasBirthday: Bool,
        hasMemo: Bool
    ) -> Color {
        if isSelected {
            return Color("MainColor").opacity(0.8)
        }
        
        if isToday {
            return Color.white.opacity(0.2)
        }
        
        if hasBirthday {
            return Color("MainColor").opacity(0.3)
        }
        
        if hasMemo {
            return Color.blue.opacity(0.3)
        }
        
        return Color.clear
    }
}

// MARK: - MemoSheetView (개선된 버전)
struct MemoSheetView: View {
    @Binding var isPresented: Bool
    @Binding var selectedDate: Date
    @Binding var memoText: String
    @Binding var selectedWriter: String
    
    let writers = ["Karina", "Ning ning", "Winter", "Giselle"]
    
    @State private var month: Int = Calendar.current.component(.month, from: Date())
    @State private var day: Int = Calendar.current.component(.day, from: Date())
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 핸들 바
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 40, height: 6)
                    .padding(.top, 12)
                
                VStack(spacing: 20) {
                    // 제목
                    Text("메모 작성")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // 날짜 선택
                    VStack(spacing: 12) {
                        Text("날짜 선택")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 40) {
                            VStack(spacing: 8) {
                                Text("월")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Picker("월", selection: $month) {
                                    ForEach(1...12, id: \.self) { m in
                                        Text("\(m)").tag(m)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 80, height: 100)
                                .clipped()
                            }
                            
                            VStack(spacing: 8) {
                                Text("일")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Picker("일", selection: $day) {
                                    ForEach(1...31, id: \.self) { d in
                                        Text("\(d)").tag(d)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 80, height: 100)
                                .clipped()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 작성자 선택
                    VStack(spacing: 12) {
                        Text("작성자")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Menu {
                            ForEach(writers, id: \.self) { writer in
                                Button(writer) {
                                    selectedWriter = writer
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedWriter)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // 메모 입력
                    VStack(spacing: 12) {
                        Text("메모 내용")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextEditor(text: $memoText)
                            .padding(12)
                            .frame(height: 120)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Spacer()
                    
                    // 저장 버튼
                    Button {
                        isPresented = false
                    } label: {
                        Text("저장하기")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color("MainColor"))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
            .onAppear {
                let comps = Calendar.current.dateComponents([.month, .day], from: selectedDate)
                month = comps.month ?? month
                day = comps.day ?? day
            }
            .onChange(of: month) { _, _ in updateSelectedDate() }
            .onChange(of: day) { _, _ in updateSelectedDate() }
        }
        .presentationDetents([.fraction(0.75)])
        .presentationDragIndicator(.hidden)
    }
    
    private func updateSelectedDate() {
        var comps = Calendar.current.dateComponents([.year], from: selectedDate)
        comps.month = month
        comps.day = day
        if let newDate = Calendar.current.date(from: comps) {
            selectedDate = newDate
        }
    }
}

// MARK: - MenuTabView (개선된 버전)
struct MenuTabView: View {
    @State private var selectedDate: Date? = Date()
    @State private var memoText: String = ""
    @State private var isMemoSheetPresented: Bool = false
    @State private var selectedWriter: String = "Karina"
    
    @Query private var cards: [CardModel]
    @StateObject private var memoStore = MemoStore()

    var memoDates: Set<Date> {
        Set(memoStore.memos.keys)
    }
    
    var birthdayCardsForSelectedDate: [CardModel] {
        guard let selectedDate = selectedDate else { return [] }
        let selMonth = Calendar.current.component(.month, from: selectedDate)
        let selDay = Calendar.current.component(.day, from: selectedDate)
        
        return cards.filter {
            guard let bd = $0.birthDateAsDate else { return false }
            let bMonth = Calendar.current.component(.month, from: bd)
            let bDay = Calendar.current.component(.day, from: bd)
            return bMonth == selMonth && bDay == selDay
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor")
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // 헤더
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("공유 캘린더")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            if let date = selectedDate {
                                Text(DateFormatter.selectedDateFormatter.string(from: date))
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            if selectedDate == nil {
                                selectedDate = Date()
                            }
                            memoText = ""
                            selectedWriter = "Karina"
                            isMemoSheetPresented = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color("MainColor").opacity(0.8))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // 캘린더
                    VStack {
                        CalendarView(
                            selectedDate: $selectedDate,
                            cards: cards,
                            memoDates: memoDates
                        )
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    
                    // 하단 정보
                    ScrollView {
                        VStack(spacing: 20) {
                            if let date = selectedDate {
                                if !birthdayCardsForSelectedDate.isEmpty || !(memoStore.memos[date]?.isEmpty ?? true) {
                                    // 생일 정보
                                    if !birthdayCardsForSelectedDate.isEmpty {
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                Image(systemName: "gift.fill")
                                                    .foregroundColor(Color("MainColor"))
                                                Text("오늘 생일인 친구")
                                                    .font(.headline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            }
                                            
                                            ForEach(birthdayCardsForSelectedDate, id: \.id) { card in
                                                HStack {
                                                    Circle()
                                                        .fill(Color("MainColor"))
                                                        .frame(width: 8, height: 8)
                                                    
                                                    Text(card.name)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.white)
                                                    
                                                    Spacer()
                                                    
                                                    Text(card.birthDate)
                                                        .font(.caption)
                                                        .foregroundColor(.white.opacity(0.7))
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .background(Color.white.opacity(0.1))
                                                .cornerRadius(12)
                                            }
                                        }
                                    }
                                    
                                    // 메모 정보
                                    if let memoList = memoStore.memos[date], !memoList.isEmpty {
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                Image(systemName: "note.text")
                                                    .foregroundColor(.blue)
                                                Text("공유 메모")
                                                    .font(.headline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            }
                                            
                                            ForEach(Array(memoList.enumerated()), id: \.offset) { _, memo in
                                                VStack(alignment: .leading, spacing: 8) {
                                                    Text(memo.text)
                                                        .foregroundColor(.white)
                                                        .lineLimit(nil)
                                                    
                                                    Text("- \(memo.writer)")
                                                        .font(.caption)
                                                        .foregroundColor(.blue.opacity(0.8))
                                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                                }
                                                .padding(16)
                                                .background(Color.white.opacity(0.1))
                                                .cornerRadius(12)
                                            }
                                        }
                                    }
                                } else {
                                    // 빈 상태
                                    VStack(spacing: 16) {
                                        Image(systemName: "calendar.badge.plus")
                                            .font(.system(size: 48))
                                            .foregroundColor(.white.opacity(0.6))
                                        
                                        Text("선택한 날짜에\n일정이 없습니다")
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(.white.opacity(0.8))
                                            .font(.headline)
                                        
                                        Button {
                                            memoText = ""
                                            selectedWriter = "Karina"
                                            isMemoSheetPresented = true
                                        } label: {
                                            Text("메모 추가하기")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(Color("MainColor"))
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 10)
                                                .background(Color.white.opacity(0.1))
                                                .cornerRadius(20)
                                        }
                                    }
                                    .padding(.top, 20)
                                }
                            } else {
                                VStack(spacing: 16) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 48))
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    Text("날짜를 선택해주세요")
                                        .foregroundColor(.white.opacity(0.8))
                                        .font(.headline)
                                }
                                .padding(.top, 20)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxHeight: 280)
                }
                .sheet(isPresented: $isMemoSheetPresented) {
                    if let date = selectedDate {
                        MemoSheetView(
                            isPresented: $isMemoSheetPresented,
                            selectedDate: Binding(
                                get: { date },
                                set: { newDate in selectedDate = newDate }
                            ),
                            memoText: $memoText,
                            selectedWriter: $selectedWriter
                        )
                        .onDisappear {
                            let trimmedText = memoText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmedText.isEmpty else { return }
                            
                            var memoList = memoStore.memos[date] ?? []
                            memoList.append((text: trimmedText, writer: selectedWriter))
                            memoStore.memos[date] = memoList
                        }
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Extensions
extension DateFormatter {
    static let selectedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 EEEE"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
}
