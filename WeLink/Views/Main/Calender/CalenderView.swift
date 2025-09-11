import SwiftUI
import SwiftData

// MARK: - CustomCalendarView
struct CustomCalendarView: View {
    @Binding var selectedDate: Date?
    var cards: [CardModel]
    var memoDates: Set<Date>
    
    @State private var currentMonth: Date = Date()
    private let calendar = Calendar.current
    
    // 한국식 요일 (월요일 시작)
    private var weekdays: [String] {
        return ["월", "화", "수", "목", "금", "토", "일"]
    }
    
    // 월별 날짜 배열 (월요일 시작으로 조정)
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        
        // 월요일 시작으로 조정 (일요일=1, 월요일=2 -> 월요일=0, 일요일=6)
        let adjustedFirstWeekday = (firstWeekday + 5) % 7
        
        var days: [Date] = []
        
        // 이전 달 날짜들로 첫 주 채우기
        if adjustedFirstWeekday > 0 {
            for dayOffset in (1...adjustedFirstWeekday).reversed() {
                if let previousDate = calendar.date(byAdding: .day, value: -dayOffset, to: firstOfMonth) {
                    days.append(previousDate)
                }
            }
        }
        
        // 해당 월의 모든 날짜 추가
        let numberOfDays = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        // 다음 달 날짜들로 마지막 주 채우기 (7의 배수로 맞추기)
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
        VStack(spacing: 24) {
            monthHeader
            weekdayHeader
            calendarGrid
        }
        .padding(.vertical, 24)
    }
    
    private var monthHeader: some View {
        HStack(spacing: 0) {
            Button {
                changeMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color(hex: "#919191"))
                    .font(.system(size: 16, weight: .medium))
            }
            
            Spacer()
            
            Text(monthYearFormatter.string(from: currentMonth))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                changeMonth(1)
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(hex: "#919191"))
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .frame(width: 160, height: 25)
    }
    
    private var weekdayHeader: some View {
        HStack(alignment: .center, spacing: -35) {
            ForEach(weekdays, id: \.self) { weekday in
                Spacer()
                Text(weekday)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(hex: "#919191"))
                Spacer()
            }
        }
    }
    
    private var calendarGrid: some View {
        let rowCount = Int(ceil(Double(daysInMonth.count) / 7.0))
        
        return VStack(alignment: .center, spacing: 20) {
            ForEach(0..<rowCount, id: \.self) { week in
                HStack(alignment: .center, spacing: -35) {
                    ForEach(0..<7, id: \.self) { day in
                        Spacer()
                        let index = week * 7 + day
                        if index < daysInMonth.count {
                            dayCell(date: daysInMonth[index])
                        }
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 36, maxHeight: 36, alignment: .center)
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
            VStack(spacing: 0) {
                ZStack {
                    // 선택 배경 원
                    Ellipse()
                        .fill(cellBackgroundColor(isSelected: isSelected, isToday: isToday))
                        .frame(width: 28, height: 27)
                    
                    Text("\(day)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(cellTextColor(
                            for: date,
                            isSelected: isSelected,
                            isToday: isToday,
                            isCurrentMonth: isCurrentMonth,
                            hasBirthday: hasBirthdayOnDate,
                            hasMemo: hasMemoOnDate
                        ))
                }
                
                // 오늘 날짜 표시 (선택되지 않았을 때만)
                if isToday && isCurrentMonth && !isSelected {
                    Text("오늘")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color("MainColor"))
                } else {
                    // 빈 공간 유지
                    Text("")
                        .font(.system(size: 9, weight: .medium))
                        .frame(height: 10)
                }
            }
            .frame(width: 35, height: 36)
        }
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월"
        return formatter
    }
    
    private func changeMonth(_ value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
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
    
    // 날짜 셀의 텍스트 색상 결정
    private func cellTextColor(
        for date: Date,
        isSelected: Bool,
        isToday: Bool,
        isCurrentMonth: Bool,
        hasBirthday: Bool,
        hasMemo: Bool
    ) -> Color {
        // 선택된 날짜는 흰색
        if isSelected {
            return .white
        }
        
        // 현재 월이 아닌 날짜는 회색 투명
        if !isCurrentMonth {
            return Color(hex: "#919191").opacity(0.3)
        }
        
        // 오늘 날짜는 메인 컬러
        if isToday {
            return Color("MainColor")
        }
        
        // 생일이나 메모가 있는 날짜는 흰색
        if hasBirthday || hasMemo {
            return .white
        }
        
        // 기본 색상은 회색
        return Color(hex: "#919191")
    }
    
    // 날짜 셀의 배경 색상 결정
    private func cellBackgroundColor(isSelected: Bool, isToday: Bool) -> Color {
        if isSelected {
            return .black.opacity(0.6)
        }
        
        return .clear
    }
}

// MARK: - DayCell (기존 코드와 호환성을 위해 유지하지만 사용하지 않음)
struct DayCell: View {
    var date: Date
    var isSelected: Bool
    var isToday: Bool
    var hasBirthday: Bool
    var hasMemo: Bool
    
    @State private var animateScale: Bool = false
    
    var body: some View {
        ZStack {
            if hasMemo {
                Circle()
                    .fill(Color("MainColor").opacity(0.2))
                    .frame(width: 42, height: 42)
            }
            
            if isSelected {
                Circle()
                    .stroke(Color("MainColor"), lineWidth: 2)
                    .frame(width: 42, height: 42)
                    .scaleEffect(animateScale ? 1.1 : 1.0)
                    .onAppear {
                        animateScale = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            animateScale = false
                        }
                    }
            }
            
            VStack(spacing: 0) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .foregroundColor(hasBirthday ? Color("MainColor") : .white)
                    .fontWeight(isToday ? .bold : .regular)
                    .frame(height: 20)
                
                if isToday {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 5, height: 5)
                        .padding(.top, 4)
                } else {
                    Spacer().frame(height: 9)
                }
            }
            .frame(height: 42)
        }
        .frame(height: 42)
    }
}

// MARK: - Color Extension
//extension Color {
//    init(hex: String) {
//        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//        var int: UInt64 = 0
//        Scanner(string: hex).scanHexInt64(&int)
//        let a, r, g, b: UInt64
//        switch hex.count {
//        case 3: // RGB (12-bit)
//            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
//        case 6: // RGB (24-bit)
//            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
//        case 8: // ARGB (32-bit)
//            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
//        default:
//            (a, r, g, b) = (1, 1, 1, 0)
//        }
//
//        self.init(
//            .sRGB,
//            red: Double(r) / 255,
//            green: Double(g) / 255,
//            blue:  Double(b) / 255,
//            opacity: Double(a) / 255
//        )
//    }
//}

// MARK: - MemoSheetView (기존 코드 유지)
struct MemoSheetView: View {
    @Binding var isPresented: Bool
    @Binding var selectedDate: Date
    @Binding var memoText: String
    @Binding var selectedWriter: String
    
    let writers = ["Karina", "Ning ning", "Winter", "Giselle"]
    
    @State private var month: Int = Calendar.current.component(.month, from: Date())
    @State private var day: Int = Calendar.current.component(.day, from: Date())
    
    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(Color.gray.opacity(0.5))
                .padding(.top, 12)
            
            Text("메모 작성")
                .font(.headline)
                .foregroundColor(Color("MainColor"))
                .padding(.bottom, 4)
            
            HStack(spacing: 50) {
                VStack {
                    Text("월")
                        .foregroundColor(.secondary)
                    Picker("월", selection: $month) {
                        ForEach(1...12, id: \.self) { m in
                            Text("\(m)월").tag(m)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 80, height: 120)
                }
                
                VStack {
                    Text("일")
                        .foregroundColor(.secondary)
                    Picker("일", selection: $day) {
                        ForEach(1...31, id: \.self) { d in
                            Text("\(d)일").tag(d)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 80, height: 120)
                }
            }
            .onAppear {
                let comps = Calendar.current.dateComponents([.month, .day], from: selectedDate)
                month = comps.month ?? month
                day = comps.day ?? day
            }
            .onChange(of: month) { oldValue, newValue in
                updateSelectedDate()
            }
            .onChange(of: day) { oldValue, newValue in
                updateSelectedDate()
            }
            
            VStack(alignment: .leading) {
                Text("작성자")
                    .foregroundColor(.secondary)
                Picker("작성자", selection: $selectedWriter) {
                    ForEach(writers, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .accentColor(Color("MainColor"))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            TextEditor(text: $memoText)
                .frame(height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("MainColor"), lineWidth: 1)
                )
            
            Button {
                isPresented = false
            } label: {
                Text("저장")
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("MainColor"))
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .cornerRadius(20)
        .preferredColorScheme(.dark)
        .presentationDetents([.fraction(0.7)])
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

// MARK: - MenuTabView (메인 화면 유지)
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
                
                VStack(spacing: 20) {
                    HStack {
                        Text("공유 캘린더")
                            .font(.system(size: 35, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 16)
                            .padding(.leading, 11)
                        
                        Spacer()
                        
                        Button {
                            if selectedDate == nil {
                                selectedDate = Date()
                            }
                            memoText = ""
                            selectedWriter = "Karina"
                            isMemoSheetPresented = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                                .environment(\.colorScheme, .dark)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                                .frame(width: 40, height: 40)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .padding(.top, 18)
                    }
                    .padding(.horizontal)
                    
                    // 새로운 캘린더 디자인 적용
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                        .overlay(
                            CustomCalendarView(selectedDate: $selectedDate, cards: cards, memoDates: memoDates)
                                .padding()
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .frame(width: UIScreen.main.bounds.width * 0.88, height: 400)

                    if let date = selectedDate {
                        if birthdayCardsForSelectedDate.isEmpty && (memoStore.memos[date]?.isEmpty ?? true) {
                            VStack {
                                Image(systemName: "person.crop.circle.badge.xmark")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color("MainColor").opacity(0.8))
                                Text("생일인 친구가 없습니다.")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white.opacity(0.9))
                                    .font(.headline)
                                    .padding(.top, 5)
                            }
                            .padding(.top, 30)
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 12) {
                                    if !birthdayCardsForSelectedDate.isEmpty {
                                        Text("오늘 생일인 친구")
                                            .font(.headline)
                                            .foregroundColor(Color("MainColor"))
                                        ForEach(birthdayCardsForSelectedDate, id: \.id) { card in
                                            HStack {
                                                Text(card.name)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.white)
                                                Spacer()
                                                Text(card.birthDate)
                                                    .foregroundColor(.white)
                                                    .font(.subheadline)
                                            }
                                            .shadow(radius: 2)
                                        }
                                    }
                                    
                                    if let memoList = memoStore.memos[date], !memoList.isEmpty {
                                        Divider()
                                            .padding(.vertical, 8)
                                        Text("공유 메모")
                                            .font(.headline)
                                            .foregroundColor(Color("MainColor"))
                                        ForEach(Array(memoList.enumerated()), id: \.offset) { _, memo in
                                            VStack(alignment: .leading) {
                                                Text(memo.text)
                                                    .foregroundColor(.black)
                                                    .padding(8)
                                                    .background(Color("MainColor").opacity(0.8))
                                                    .cornerRadius(10)
                                                
                                                Text("작성자: \(memo.writer)")
                                                    .foregroundColor(Color("MainColor").opacity(0.8))
                                                    .font(.footnote)
                                                    .padding(.bottom, 4)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(maxHeight: 200)
                        }
                    } else {
                        VStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 40))
                                .foregroundColor(Color("MainColor").opacity(0.8))
                            Text("날짜를 선택해주세요")
                                .foregroundColor(.white.opacity(0.9))
                                .font(.headline)
                                .padding(.top, 5)
                        }
                        .padding(.top, 30)
                    }
                    
                    Spacer()
                }
                .sheet(isPresented: $isMemoSheetPresented) {
                    if let date = selectedDate {
                        MemoSheetView(
                            isPresented: $isMemoSheetPresented,
                            selectedDate: Binding(
                                get: { date },
                                set: { newDate in
                                    selectedDate = newDate
                                }),
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
    }
}
