//
//  FriendsTabView.swift
//  WeLink
//
//  Created by 조영민 on 8/26/25.
//

import SwiftUI
import SwiftData

struct FriendsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allCards: [CardModel]
    @Query private var myID: [MyUUID]
    
    @StateObject private var viewModel = FriendsViewModel(cardViewModel: nil)
    @FocusState private var isTextFieldFocused: Bool
    
    private var cards: [CardModel] {
        // Fallback to original logic if viewModel is not ready
        if let cardViewModel = viewModel.cardViewModel {
            return cardViewModel.filterCards(from: allCards, myIDs: myID, searchText: viewModel.searchText)
        } else {
            // Original filtering logic
            guard let myUUID = myID.last?.id else {
                if viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return allCards
                } else {
                    return allCards.filter { card in
                        card.name.localizedCaseInsensitiveContains(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
            }
            
            let filteredCards = allCards.filter { $0.id != myUUID }
            
            if viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return filteredCards
            } else {
                return filteredCards.filter { card in
                    card.name.localizedCaseInsensitiveContains(viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
    }
    
    private var safeCurrentIndex: Int {
        cards.safeIndex(viewModel.currentIndex)
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    BackgroundImageView(
                        cards: cards,
                        currentIndex: safeCurrentIndex,
                        preloadedImages: viewModel.preloadedImages
                    )
                    .ignoresSafeArea(.all)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom,
                        alignment: .center
                    )
                    
                    VStack(spacing: 0) {
                        FriendsHeaderView(
                            searchText: $viewModel.searchText,
                            isSearching: $viewModel.isSearching,
                            isTextFieldFocused: $isTextFieldFocused,
                            onToggleSearch: {
                                withAnimation(AnimationConstants.cardTransition) {
                                    viewModel.toggleSearchMode()
                                }
                                
                                if viewModel.isSearching {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        isTextFieldFocused = true
                                    }
                                } else {
                                    isTextFieldFocused = false
                                }
                            }
                        )
                        .padding(.top, geometry.safeAreaInsets.top - 40)
                        .padding(.horizontal, 24)
                        
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 0)
                        
                        if cards.isEmpty {
                            FriendsEmptyStateView(searchText: viewModel.searchText)
                                .frame(maxHeight: .infinity)
                        } else {
                            ScrollView {
                                CardScrollView(cards: cards, currentIndex: $viewModel.currentIndex)
                                    .padding(.top, 20)
                            }
                            .scrollDisabled(true)
                        }
                        
                        Spacer(minLength: 60)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    floatingButton(geometry: geometry)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                handleViewAppear()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                viewModel.handleKeyboardShow(keyboardFrame.height)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            viewModel.handleKeyboardHide()
        }
        .onChange(of: allCards) { oldValue, newValue in
            if newValue.count < oldValue.count && viewModel.currentIndex >= cards.count && cards.count > 0 {
                DispatchQueue.main.async {
                    viewModel.currentIndex = max(0, cards.count - 1)
                }
            }
            
            if !cards.isEmpty {
                viewModel.preloadImages(for: cards) // ViewModel로 위임
            }
        }
        .onChange(of: allCards.count) { oldCount, newCount in
            if newCount > oldCount {
                print("새 카드가 추가되었습니다. 이 \(newCount)개")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if !self.cards.isEmpty {
                        self.viewModel.currentIndex = min(self.viewModel.currentIndex, self.cards.count - 1)
                        self.viewModel.preloadImages(for: self.cards) // ViewModel로 위임
                    }
                }
            }
        }
        .onChange(of: cards) { oldValue, newValue in
            DispatchQueue.main.async {
                if newValue.isEmpty {
                    self.viewModel.currentIndex = 0
                } else {
                    if newValue.count < oldValue.count {
                        self.viewModel.currentIndex = min(self.viewModel.currentIndex, max(0, newValue.count - 1))
                    } else {
                        self.viewModel.currentIndex = min(self.viewModel.currentIndex, newValue.count - 1)
                    }
                }
                self.viewModel.preloadImages(for: newValue) // ViewModel로 위임
            }
        }
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.resetCurrentIndex()
        }
        .sheet(isPresented: $viewModel.showingShareSheet) {
            shareSheetView
        }
    }
}

// MARK: - View Components
extension FriendsTabView {
    
    private func floatingButton(geometry: GeometryProxy) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    viewModel.toggleShareSheet()
                }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(Color("MainColor"))
                    }
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 24)
                .padding(.bottom, viewModel.keyboardHeight > 0 ? 140 : geometry.safeAreaInsets.bottom + 133)
            }
        }
    }
    
    private var shareSheetView: some View {
        NavigationView {
            if let myCard = viewModel.findMyCard(from: allCards, myIDs: myID) {
                ShareCardSheetView(myCard: myCard)
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                VStack {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("내 카드를 찾을 수 없습니다")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .padding()
                    
                    Text("먼저 내 카드를 생성해주세요")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Private Methods
extension FriendsTabView {
    
    private func setupViewModel() {
        // Initialize cardViewModel when view appears
        if viewModel.cardViewModel == nil {
            viewModel.cardViewModel = CardViewModel(context: modelContext)
        }
    }
    
    private func printAllCards(cards: [CardModel]) {
        for card in cards {
            print(card.name)
        }
    }
    
    private func handleViewAppear() {
        setupViewModel()
        printAllCards(cards: allCards)
        
        // Use original dummy card insertion logic
        if allCards.isEmpty {
            CardDataService.insertDummyCards(into: modelContext)
        } else {
            // 현재 화면에 보이는 cards 배열로 preload
            viewModel.preloadImages(for: cards) // ViewModel로 위임
        }
    }
}

#Preview {
    FriendsTabView()
        .modelContainer(for: CardModel.self, inMemory: true)
}
