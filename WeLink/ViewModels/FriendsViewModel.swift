//
//  FriendsViewModel.swift
//  WeLink
//
//  Created by Youngmin Cho on 8/26/25.
//

//
//  FriendsViewModel.swift
//  WeLink
//
//  Created by Youngmin Cho on 8/26/25.
//

import Foundation
import SwiftData
import UIKit

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var currentIndex = 0
    @Published var preloadedImages: [Int: UIImage] = [:]
    @Published var searchText = ""
    @Published var isSearching = false
    @Published var keyboardHeight: CGFloat = 0
    @Published var showingShareSheet = false
    
    private let cardViewModel: CardViewModel
    
    init(cardViewModel: CardViewModel) {
        self.cardViewModel = cardViewModel
    }
    
    // MARK: - Search Management
    func toggleSearchMode() {
        if isSearching {
            exitSearchMode()
        } else {
            enterSearchMode()
        }
    }
    
    func enterSearchMode() {
        isSearching = true
    }
    
    func exitSearchMode() {
        searchText = ""
        resetCurrentIndex()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isSearching = false
        }
    }
    
    func resetCurrentIndex() {
        DispatchQueue.main.async {
            self.currentIndex = 0
        }
    }
    
    // MARK: - Index Management
    func updateCurrentIndex(to newIndex: Int, cardCount: Int) {
        guard newIndex >= 0 && newIndex < cardCount else { return }
        currentIndex = newIndex
    }
    
    func handleCardsChange(oldCards: [CardModel], newCards: [CardModel]) {
        if newCards.count < oldCards.count && currentIndex >= newCards.count && newCards.count > 0 {
            DispatchQueue.main.async {
                self.currentIndex = max(0, newCards.count - 1)
            }
        }
        
        if !newCards.isEmpty {
            preloadImages(for: newCards)
        }
    }
    
    func handleCardsCountChange(oldCount: Int, newCount: Int, cards: [CardModel]) {
        if newCount > oldCount {
            print("새 카드가 추가되었습니다. 총 \(newCount)개")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if !cards.isEmpty {
                    self.currentIndex = min(self.currentIndex, cards.count - 1)
                    self.preloadImages(for: cards)
                }
            }
        }
    }
    
    func handleFilteredCardsChange(oldCards: [CardModel], newCards: [CardModel]) {
        DispatchQueue.main.async {
            if newCards.isEmpty {
                self.currentIndex = 0
            } else {
                if newCards.count < oldCards.count {
                    self.currentIndex = min(self.currentIndex, max(0, newCards.count - 1))
                } else {
                    self.currentIndex = min(self.currentIndex, newCards.count - 1)
                }
            }
            self.preloadImages(for: newCards)
        }
    }
    
    // MARK: - Image Preloading
    func preloadImages(for cards: [CardModel]) {
        DispatchQueue.global(qos: .userInitiated).async {
            var newPreloadedImages: [Int: UIImage] = [:]
            for (index, card) in cards.enumerated() {
                if !card.imageData.isEmpty, let uiImage = UIImage(data: card.imageData) {
                    let resizedImage = self.resizeImageForBackground(uiImage)
                    newPreloadedImages[index] = resizedImage
                }
            }
            DispatchQueue.main.async {
                self.preloadedImages = newPreloadedImages
            }
        }
    }
    
    private func resizeImageForBackground(_ image: UIImage) -> UIImage {
        let screenSize = UIScreen.main.bounds.size
        let maxDimension = max(screenSize.width, screenSize.height) * 1.5
        
        let imageSize = image.size
        let scale = maxDimension / max(imageSize.width, imageSize.height)
        
        let targetSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    // MARK: - Keyboard Management
    func handleKeyboardShow(_ keyboardHeight: CGFloat) {
        self.keyboardHeight = keyboardHeight
    }
    
    func handleKeyboardHide() {
        keyboardHeight = 0
    }
    
    // MARK: - Share Sheet
    func toggleShareSheet() {
        showingShareSheet.toggle()
    }
    
    // MARK: - Card Operations
    func findMyCard(from allCards: [CardModel], myIDs: [MyUUID]) -> CardModel? {
        return cardViewModel.findMyCard(from: allCards, myIDs: myIDs)
    }
    
    func getFilteredCards(from allCards: [CardModel], myIDs: [MyUUID]) -> [CardModel] {
        return cardViewModel.filterCards(from: allCards, myIDs: myIDs, searchText: searchText)
    }
    
    // MARK: - View Lifecycle
    func handleViewAppear(allCards: [CardModel]) {
        if allCards.isEmpty {
            cardViewModel.insertDummyCardsIfNeeded(allCards: allCards)
        } else {
            preloadImages(for: allCards)
        }
    }
}
