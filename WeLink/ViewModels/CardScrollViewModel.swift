import SwiftUI
import SwiftData

@MainActor
final class CardScrollViewModel: ObservableObject {
    @Published var currentIndex: Int
    @Published var scrollPosition: UUID?
    @Published var showingDeleteAlert: Bool = false
    @Published var cardToDelete: CardModel? = nil

    @Published private(set) var isProgrammaticScroll: Bool = false

    private let animation = AnimationConstants.cardTransition

    init(currentIndex: Int = 0) {
        self.currentIndex = currentIndex
        self.scrollPosition = nil
    }

    func initialize(with cards: [CardModel]) {
        guard !cards.isEmpty else {
            scrollPosition = nil
            return
        }
        let clamped = clamp(currentIndex, in: cards)
        if clamped != currentIndex { currentIndex = clamped }
        setProgrammaticScroll(true)
        scrollPosition = cards[clamped].id
        endProgrammaticScrollSoon()
    }

    func handleCardsChange(_ newCards: [CardModel]) {
        if newCards.isEmpty {
            currentIndex = 0
            scrollPosition = nil
            return
        }
        let newIndex = clamp(currentIndex, in: newCards)
        if newIndex != currentIndex { currentIndex = newIndex }
        setProgrammaticScroll(true)
        scrollPosition = newCards[newIndex].id
        endProgrammaticScrollSoon()
    }

    func handleIndexChange(_ newIndex: Int, cards: [CardModel]) {
        guard !cards.isEmpty, newIndex >= 0, newIndex < cards.count else { return }
        guard scrollPosition != cards[newIndex].id else { return }
        setProgrammaticScroll(true)
        withAnimation(animation) {
            scrollPosition = cards[newIndex].id
        }
        endProgrammaticScrollSoon()
    }

    func handleScrollPositionChange(_ newPosition: UUID?, cards: [CardModel]) {
        if isProgrammaticScroll { return }
        guard let newPosition = newPosition,
              let index = cards.firstIndex(where: { $0.id == newPosition }) else { return }
        if index != currentIndex {
            currentIndex = index
        }
    }

    func updateIndex(to newIndex: Int, cards: [CardModel]) {
        guard newIndex >= 0 && newIndex < cards.count else { return }
        guard newIndex != currentIndex else { return }
        setProgrammaticScroll(true)
        withAnimation(animation) {
            currentIndex = newIndex
            scrollPosition = cards[newIndex].id
        }
        endProgrammaticScrollSoon()
    }

    func requestDelete(_ card: CardModel) {
        cardToDelete = card
        showingDeleteAlert = true
    }

    func confirmDelete(using context: ModelContext) {
        if let card = cardToDelete {
            withAnimation(animation) {
                context.delete(card)
            }
        }
        cardToDelete = nil
        showingDeleteAlert = false
    }

    func cancelDelete() {
        cardToDelete = nil
        showingDeleteAlert = false
    }

    // MARK: - Helpers
    private func clamp(_ index: Int, in cards: [CardModel]) -> Int {
        return min(max(0, index), max(0, cards.count - 1))
    }

    private func setProgrammaticScroll(_ value: Bool) {
        isProgrammaticScroll = value
    }

    private func endProgrammaticScrollSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            self?.isProgrammaticScroll = false
        }
    }
}
