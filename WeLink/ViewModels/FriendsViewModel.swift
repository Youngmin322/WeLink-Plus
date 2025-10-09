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
    
    var cardViewModel: CardViewModel?
    
    init(cardViewModel: CardViewModel?) {
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
    
    // MARK: - Image Preloading (수정됨)
    func preloadImages(for cards: [CardModel]) {
        guard !cards.isEmpty else {
            print("❌ preloadImages: cards가 비어있음")
            return
        }
        
        print("🔄 preloadImages 시작 - 총 \(cards.count)개 카드, 현재 인덱스: \(currentIndex)")
        
        // 모든 카드를 프리로드하도록 수정 (성능 문제가 있다면 나중에 다시 제한)
        let cardsToPreload = cards
        
        let cardData: [(Int, Data)] = cardsToPreload.enumerated().compactMap { index, card in
            guard !card.imageData.isEmpty else {
                print("⚠️ 카드 \(index)(\(card.name))의 imageData가 비어있음")
                return nil
            }
            print("✅ 카드 \(index)(\(card.name)) 프리로드 대상에 추가")
            return (index, card.imageData)
        }
        
        print("📊 프리로드할 카드 데이터: \(cardData.count)개")
        
        Task {
            var newPreloadedImages = preloadedImages
            
            for (index, imageData) in cardData {
                // 이미 있는 이미지는 스킵하되 로그 출력
                if newPreloadedImages[index] != nil {
                    print("⏭️ 카드 \(index) 이미지 이미 존재, 스킵")
                    continue
                }
                
                if let uiImage = UIImage(data: imageData) {
                    print("🖼️ 카드 \(index) 이미지 리사이즈 중...")
                    let resizedImage = await Self.resizeImageForBackground(uiImage)
                    newPreloadedImages[index] = resizedImage
                    print("✅ 카드 \(index) 이미지 프리로드 완료")
                } else {
                    print("❌ 카드 \(index) 이미지 데이터를 UIImage로 변환 실패")
                }
            }
            
            // 메모리 관리를 위한 제거 로직을 더 관대하게 수정
            let maxDistance = 5 // 현재 인덱스에서 5 이상 떨어진 이미지만 제거
            let indicesToKeep = Set(max(0, currentIndex - maxDistance)...min(cards.count - 1, currentIndex + maxDistance))
            let removedCount = newPreloadedImages.count
            newPreloadedImages = newPreloadedImages.filter { indicesToKeep.contains($0.key) }
            
            if removedCount != newPreloadedImages.count {
                print("🗑️ 메모리 정리: \(removedCount - newPreloadedImages.count)개 이미지 제거")
            }
            
            print("📈 최종 프리로드된 이미지 수: \(newPreloadedImages.count)")
            print("🎯 프리로드된 인덱스들: \(newPreloadedImages.keys.sorted())")
            
            self.updatePreloadedImages(newPreloadedImages)
        }
    }
    
    private func updatePreloadedImages(_ images: [Int: UIImage]) {
        let oldCount = self.preloadedImages.count
        self.preloadedImages = images
        print("🔄 preloadedImages 업데이트: \(oldCount) -> \(images.count)")
    }
    
    private static func resizeImageForBackground(_ image: UIImage, maxDimension overrideMaxDimension: CGFloat? = nil) async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let imageSize = image.size
                let maxDimension = overrideMaxDimension ?? 2000
                let scale = min(1.0, maxDimension / max(imageSize.width, imageSize.height))
                let targetSize = CGSize(
                    width: max(1, imageSize.width * scale),
                    height: max(1, imageSize.height * scale)
                )
                
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1.0
                format.opaque = false
                
                let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
                let resizedImage = renderer.image { _ in
                    image.draw(in: CGRect(origin: .zero, size: targetSize))
                }
                
                continuation.resume(returning: resizedImage)
            }
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
        return cardViewModel?.findMyCard(from: allCards, myIDs: myIDs)
    }
    
    func getFilteredCards(from allCards: [CardModel], myIDs: [MyUUID]) -> [CardModel] {
        return cardViewModel?.filterCards(from: allCards, myIDs: myIDs, searchText: searchText) ?? []
    }
    
    // MARK: - View Lifecycle
    func handleViewAppear(allCards: [CardModel]) {
        if allCards.isEmpty {
            cardViewModel?.insertDummyCardsIfNeeded(allCards: allCards)
        } else {
            preloadImages(for: allCards)
        }
    }
}

