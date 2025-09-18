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
    var searchText: String
    
    private var cards: [CardModel] {
        guard let myUUID = myID.last?.id else {
            return filteredCards
        }
        return filteredCards.filter { $0.id != myUUID }
    }
    
    private var filteredCards: [CardModel] {
        if searchText.isEmpty {
            return allCards
        } else {
            return allCards.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
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
                        // 헤더
                        HStack {
                            Text("친구")
                                .font(.custom("Pretendard-Bold", size: 35))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.top, geometry.safeAreaInsets.top - 40)
                        .padding(.horizontal, 24)
                        
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 0)
                        
                        if cards.isEmpty {
                            FriendsEmptyStateView(searchText: "")
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
        .onChange(of: allCards) { oldValue, newValue in
            if newValue.count < oldValue.count && viewModel.currentIndex >= cards.count && cards.count > 0 {
                DispatchQueue.main.async {
                    viewModel.currentIndex = max(0, cards.count - 1)
                }
            }
            
            if !cards.isEmpty {
                viewModel.preloadImages(for: cards)
            }
        }
        .onChange(of: allCards.count) { oldCount, newCount in
            if newCount > oldCount {
                print("새 카드가 추가되었습니다. 총 \(newCount)개")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if !self.cards.isEmpty {
                        self.viewModel.currentIndex = min(self.viewModel.currentIndex, self.cards.count - 1)
                        self.viewModel.preloadImages(for: self.cards)
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
                self.viewModel.preloadImages(for: newValue)
            }
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
                .padding(.bottom, geometry.safeAreaInsets.bottom + 133)
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
        
        if allCards.isEmpty {
            CardDataService.insertDummyCards(into: modelContext)
        } else {
            viewModel.preloadImages(for: cards)
        }
    }
}

//#Preview {
//    FriendsTabView()
//        .modelContainer(for: CardModel.self, inMemory: true)
//}
