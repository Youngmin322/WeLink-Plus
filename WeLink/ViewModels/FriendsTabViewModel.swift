import SwiftUI
import SwiftData

@MainActor
final class FriendsTabViewModel: ObservableObject {
    var cardViewModel: CardViewModel?

    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    @Published var currentIndex: Int = 0
    @Published var keyboardHeight: CGFloat = 0
    @Published var showingShareSheet: Bool = false

    @Published private(set) var visibleCards: [CardModel] = []
    @Published private(set) var preloadedImages: [UUID: UIImage] = [:]

    func toggleSearchMode() {
        isSearching.toggle()
        if !isSearching { searchText = "" }
    }

    func toggleShareSheet() {
        showingShareSheet.toggle()
    }

    func resetCurrentIndex() {
        currentIndex = 0
    }

    func handleAppear(allCards: [CardModel], myIDs: [MyUUID], context: ModelContext) {
        if cardViewModel == nil {
            cardViewModel = CardViewModel(context: context)
        }
        if allCards.isEmpty {
            CardDataService.insertDummyCards(into: context)
        }
        updateVisibleCards(from: allCards, myIDs: myIDs)
        preloadImages(for: visibleCards)
    }

    func handleAllCardsChange(oldValue: [CardModel], newValue: [CardModel], myIDs: [MyUUID]) {
        updateVisibleCards(from: newValue, myIDs: myIDs)
        if visibleCards.isEmpty {
            currentIndex = 0
        } else if currentIndex >= visibleCards.count {
            currentIndex = max(0, visibleCards.count - 1)
        }
        preloadImages(for: visibleCards)
    }

    func handleCardsProjectionChange(oldValue: [CardModel], newValue: [CardModel]) {
        if newValue.isEmpty {
            currentIndex = 0
        } else {
            if newValue.count < oldValue.count {
                currentIndex = min(currentIndex, max(0, newValue.count - 1))
            } else {
                currentIndex = min(currentIndex, newValue.count - 1)
            }
        }
        preloadImages(for: newValue)
    }

    func handleKeyboardShow(_ height: CGFloat) {
        keyboardHeight = height
    }

    func handleKeyboardHide() {
        keyboardHeight = 0
    }

    func findMyCard(from cards: [CardModel], myIDs: [MyUUID]) -> CardModel? {
        guard let myUUID = myIDs.last?.id else { return nil }
        return cards.first { $0.id == myUUID }
    }

    func updateVisibleCards(from allCards: [CardModel], myIDs: [MyUUID]) {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let cvm = cardViewModel {
            visibleCards = cvm.filterCards(from: allCards, myIDs: myIDs, searchText: searchText)
        } else {
            if let myUUID = myIDs.last?.id {
                let filtered = allCards.filter { $0.id != myUUID }
                if trimmed.isEmpty {
                    visibleCards = filtered
                } else {
                    visibleCards = filtered.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
                }
            } else {
                if trimmed.isEmpty {
                    visibleCards = allCards
                } else {
                    visibleCards = allCards.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
                }
            }
        }
    }

    func preloadImages(for cards: [CardModel]) {
        var cache: [UUID: UIImage] = [:]
        for card in cards {
            if let image = UIImage(data: card.imageData) {
                cache[card.id] = image
            }
        }
        preloadedImages = cache
    }
}
