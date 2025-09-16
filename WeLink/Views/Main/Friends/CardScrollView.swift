//
//  CardScrollView.swift (제스처 충돌 해결)
//  WeLink
//

import SwiftUI

struct CardScrollView: View {
    let cards: [CardModel]
    @Binding var currentIndex: Int
    @State private var scrollPosition: UUID? = nil
    
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteAlert = false
    @State private var cardToDelete: CardModel? = nil
    
    private var safeCurrentIndex: Int {
        cards.safeIndex(currentIndex)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !cards.isEmpty {
                HStack(spacing: 0) {
                    Text(cards[safeCurrentIndex].name)
                        .font(.custom("Pretendard-Bold", size: 20))
                        .foregroundColor(Color("MainColor"))
                        .animation(AnimationConstants.indexChange, value: safeCurrentIndex)
                    
                    Text(" 님의 카드")
                        .font(.custom("Pretendard-Bold", size: 20))
                        .foregroundColor(.white)
                }
                .padding(.bottom, -30)
            }
            
            GeometryReader { geometry in
                let cardWidth: CGFloat = 280
                let cardHeight: CGFloat = 480
                let spacing: CGFloat = 20
                let totalWidth = geometry.size.width
                let centerPadding = (totalWidth - cardWidth) / 2
                
                ScrollView(.horizontal) {
                    LazyHStack(spacing: spacing) {
                        ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                            CardView(
                                card: card,
                                isSelected: index == safeCurrentIndex,
                                onTap: {
                                    updateIndex(to: index)
                                },
                                onDelete: {
                                    cardToDelete = card
                                    showingDeleteAlert = true
                                }
                            )
                            .frame(width: cardWidth, height: cardHeight)
                        }
                    }
                    .padding(.horizontal, centerPadding)
                    .padding(.vertical, 60)
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrollPosition)
                .clipShape(Rectangle())
                .clipped(antialiased: false)
                .onChange(of: scrollPosition) { _, newPosition in
                    if let newPosition = newPosition,
                       let index = cards.firstIndex(where: { $0.id == newPosition }) {
                        DispatchQueue.main.async {
                            currentIndex = index
                        }
                    }
                }
            }
            .frame(height: 600)
            
            if cards.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<cards.count, id: \.self) { index in
                        Circle()
                            .fill(index == safeCurrentIndex ? Color.white : Color.white.opacity(0.4))
                            .frame(width: 6, height: 6)
                            .scaleEffect(index == safeCurrentIndex ? 1.1 : 1.0)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            .animation(AnimationConstants.cardTransition, value: safeCurrentIndex)
                            .onTapGesture {
                                updateIndex(to: index)
                            }
                    }
                }
                .padding(.top, -50)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            initializeScrollPosition()
        }
        .onChange(of: cards) { _, newCards in
            handleCardsChange(newCards)
        }
        .onChange(of: currentIndex) { _, newIndex in
            handleIndexChange(newIndex)
        }
        .alert("카드 삭제", isPresented: $showingDeleteAlert) {
            Button("취소", role: .cancel) {
                cardToDelete = nil
            }
            Button("삭제", role: .destructive) {
                if let cardToDelete = cardToDelete {
                    deleteCard(cardToDelete)
                }
                self.cardToDelete = nil
            }
        } message: {
            if let cardToDelete = cardToDelete {
                Text("\(cardToDelete.name)님의 카드를 삭제하시겠습니까?")
            }
        }
    }
    
    // MARK: - Private Methods
    private func updateIndex(to newIndex: Int) {
        guard newIndex >= 0 && newIndex < cards.count else { return }
        
        withAnimation(AnimationConstants.cardTransition) {
            currentIndex = newIndex
            scrollPosition = cards[newIndex].id
        }
    }
    
    private func initializeScrollPosition() {
        if !cards.isEmpty {
            if currentIndex >= cards.count {
                DispatchQueue.main.async {
                    currentIndex = 0
                    scrollPosition = cards[0].id
                }
            } else {
                scrollPosition = cards[safeCurrentIndex].id
            }
        }
    }
    
    private func handleCardsChange(_ newCards: [CardModel]) {
        DispatchQueue.main.async {
            if newCards.isEmpty {
                currentIndex = 0
                scrollPosition = nil
            } else {
                let newIndex = min(currentIndex, newCards.count - 1)
                currentIndex = newIndex
                scrollPosition = newCards[newIndex].id
            }
        }
    }
    
    private func handleIndexChange(_ newIndex: Int) {
        if !cards.isEmpty && newIndex >= 0 && newIndex < cards.count {
            withAnimation(AnimationConstants.cardTransition) {
                scrollPosition = cards[newIndex].id
            }
        }
    }
    
    private func deleteCard(_ card: CardModel) {
        withAnimation(AnimationConstants.cardTransition) {
            if let deleteIndex = cards.firstIndex(where: { $0.id == card.id }) {
                modelContext.delete(card)
                
                if deleteIndex <= currentIndex && currentIndex > 0 {
                    currentIndex = currentIndex - 1
                }
                
                if cards.count <= 1 {
                    currentIndex = 0
                }
            }
        }
    }
}

// MARK: - CardView (Long Press + Drag 방식)
struct CardView: View {
    let card: CardModel
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var showDeleteButton = false
    @State private var isInDeleteMode = false
    @State private var longPressActivated = false
    
    private let showDeleteThreshold: CGFloat = -60
    private let maxDragUp: CGFloat = -300
    private let maxDragDown: CGFloat = 50
    
    var body: some View {
        ZStack {
            if showDeleteButton {
                deleteButtonView
            }
            
            cardContent
        }
        .onTapGesture {
            if !isInDeleteMode {
                onTap()
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            // 롱 프레스 시 삭제 모드 활성화
            activateDeleteMode()
        }
        .gesture(
            // 삭제 모드일 때만 드래그 제스처 활성화
            isInDeleteMode ?
            DragGesture(coordinateSpace: .local)
                .onChanged(handleDragChanged)
                .onEnded(handleDragEnded)
            : nil
        )
    }
    
    private var deleteButtonView: some View {
        VStack(spacing: 15) {
            Button(action: onDelete) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.9)
                        .environment(\.colorScheme, .dark)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.red.opacity(0.5), lineWidth: 2)
                        )
                    
                    Image(systemName: "trash")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.red)
                }
            }
            
            Button("취소") {
                exitDeleteMode()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .environment(\.colorScheme, .dark)
        }
        .offset(y: 120)
        .scaleEffect(showDeleteButton ? 1.0 : 0.0)
        .opacity(showDeleteButton ? 1.0 : 0.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showDeleteButton)
    }
    
    private var cardContent: some View {
        MyProfileCardOnlyView(card: card)
            .scaleEffect(isSelected ? 1.0 : 0.85)
            .opacity(isSelected ? 1.0 : 0.7)
            .shadow(
                color: .black.opacity(0.3),
                radius: isSelected ? 15 : 8,
                x: 0,
                y: isSelected ? 8 : 4
            )
            .offset(y: dragOffset)
            .scaleEffect(isInDeleteMode ? 0.95 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.red.opacity(0.6), lineWidth: isInDeleteMode ? 2 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isInDeleteMode)
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isInDeleteMode)
    }
    
    // MARK: - 삭제 모드 관리
    private func activateDeleteMode() {
        guard !isInDeleteMode else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isInDeleteMode = true
            longPressActivated = true
            // 진동 피드백
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
        
        // 3초 후 자동으로 삭제 모드 해제
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if isInDeleteMode && !showDeleteButton {
                exitDeleteMode()
            }
        }
    }
    
    private func exitDeleteMode() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isInDeleteMode = false
            showDeleteButton = false
            dragOffset = 0
            longPressActivated = false
        }
    }
    
    // MARK: - 드래그 제스처 (삭제 모드에서만 활성화)
    private func handleDragChanged(_ value: DragGesture.Value) {
        guard isInDeleteMode else { return }
        
        let translation = value.translation.height
        let newOffset = min(max(translation, maxDragUp), maxDragDown)
        dragOffset = newOffset
        
        let shouldShowDelete = translation < showDeleteThreshold
        if shouldShowDelete != showDeleteButton {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                showDeleteButton = shouldShowDelete
            }
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        guard isInDeleteMode else { return }
        
        let finalTranslation = value.translation.height
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if showDeleteButton {
                if finalTranslation > -30 {
                    // 아래로 많이 당기면 삭제 모드 해제
                    exitDeleteMode()
                } else {
                    // 삭제 대기 위치에 고정
                    dragOffset = -180
                }
            } else {
                // 삭제 버튼이 안 보이면 원래 위치로
                dragOffset = 0
            }
        }
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var currentIndex = 0
        
        var body: some View {
            CardScrollView(
                cards: sampleCards,
                currentIndex: $currentIndex
            )
            .background(Color.black)
            .modelContainer(for: CardModel.self, inMemory: true)
        }
        
        private var sampleCards: [CardModel] {
            [
                CardModel(
                    id: UUID(),
                    name: "민지",
                    age: 25,
                    description: "안녕하세요! 함께 즐거운 시간 보내요 😊",
                    birthDate: "2000-03-15",
                    mbti: "ENFP",
                    tag: "여행러버",
                    dDay: 150,
                    imageData: Data()
                ),
                CardModel(
                    id: UUID(),
                    name: "준호",
                    age: 28,
                    description: "개발자입니다. 커피와 코딩을 좋아해요",
                    birthDate: "1996-08-22",
                    mbti: "INTJ",
                    tag: "개발자",
                    dDay: 75,
                    imageData: Data()
                ),
                CardModel(
                    id: UUID(),
                    name: "유나",
                    age: 23,
                    description: "예술과 음악을 사랑하는 사람입니다",
                    birthDate: "2001-12-05",
                    mbti: "ISFP",
                    tag: "아티스트",
                    dDay: 200,
                    imageData: Data()
                )
            ]
        }
    }
    
    return PreviewWrapper()
}
