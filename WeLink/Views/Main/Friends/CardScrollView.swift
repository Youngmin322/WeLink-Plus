//
//  CardScrollView.swift
//  WeLink
//

import SwiftUI

struct CardScrollView: View {
    let cards: [CardModel]
    @Binding var currentIndex: Int
    @StateObject private var viewModel = CardScrollViewModel()
    
    @Environment(\.modelContext) private var modelContext
    
    private var safeCurrentIndex: Int {
        cards.safeIndex(viewModel.currentIndex)
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
                                    viewModel.requestDelete(card)
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
                .scrollPosition(id: $viewModel.scrollPosition)
                .clipShape(Rectangle())
                .clipped(antialiased: false)
                .onChange(of: viewModel.scrollPosition) { _, newPosition in
                    viewModel.handleScrollPositionChange(newPosition, cards: cards)
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
            viewModel.currentIndex = currentIndex
            viewModel.initialize(with: cards)
        }
        .onChange(of: cards) { _, newCards in
            viewModel.handleCardsChange(newCards)
        }
        .onChange(of: currentIndex) { _, newIndex in
            viewModel.handleIndexChange(newIndex, cards: cards)
        }
        .onChange(of: viewModel.currentIndex) { _, newValue in
            currentIndex = newValue
        }
        .alert("카드 삭제", isPresented: $viewModel.showingDeleteAlert) {
            Button("취소", role: .cancel) {
                viewModel.cancelDelete()
            }
            Button("삭제", role: .destructive) {
                viewModel.confirmDelete(using: modelContext)
            }
        } message: {
            if let cardToDelete = viewModel.cardToDelete {
                Text("\(cardToDelete.name)님의 카드를 삭제하시겠습니까?")
            }
        }
    }
    
    // MARK: - Private Methods
    private func updateIndex(to newIndex: Int) {
        viewModel.updateIndex(to: newIndex, cards: cards)
    }
    
    private func deleteCard(_ card: CardModel) {
        viewModel.confirmDelete(using: modelContext)
    }
}

// MARK: - CardView
struct CardView: View {
    let card: CardModel
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @StateObject private var vm = CardItemViewModel()
    
    var body: some View {
        ZStack {
            if vm.showDeleteButton {
                deleteButtonView
            }
            
            cardContent
        }
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    vm.activateDeleteMode()
                }
        )
        .simultaneousGesture(
            vm.isInDeleteMode ?
            DragGesture(coordinateSpace: .local)
                .onChanged(vm.handleDragChanged)
                .onEnded(vm.handleDragEnded)
            : nil
        )
        .onTapGesture {
            if !vm.isInDeleteMode {
                onTap()
            } else {
                // 삭제 모드에서의 탭은 모드 해제
                vm.exitDeleteMode()
            }
        }
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
                vm.exitDeleteMode()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .environment(\.colorScheme, .dark)
        }
        .offset(y: 120)
        .scaleEffect(vm.showDeleteButton ? 1.0 : 0.0)
        .opacity(vm.showDeleteButton ? 1.0 : 0.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: vm.showDeleteButton)
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
            .offset(y: vm.dragOffset)
            .scaleEffect(vm.isInDeleteMode ? 0.95 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.red.opacity(0.6), lineWidth: vm.isInDeleteMode ? 2 : 0)
                    .animation(.easeInOut(duration: 0.2), value: vm.isInDeleteMode)
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: vm.isInDeleteMode)
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
