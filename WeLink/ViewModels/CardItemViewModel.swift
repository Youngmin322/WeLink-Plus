import SwiftUI

@MainActor
final class CardItemViewModel: ObservableObject {
    @Published var dragOffset: CGFloat = 0
    @Published var showDeleteButton: Bool = false
    @Published var isInDeleteMode: Bool = false
    
    let showDeleteThreshold: CGFloat = -60
    let maxDragUp: CGFloat = -300
    let maxDragDown: CGFloat = 50
    
    func activateDeleteMode() {
        guard !isInDeleteMode else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isInDeleteMode = true
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            if self.isInDeleteMode && !self.showDeleteButton {
                self.exitDeleteMode()
            }
        }
    }
    
    func exitDeleteMode() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isInDeleteMode = false
            showDeleteButton = false
            dragOffset = 0
        }
    }
    
    func handleDragChanged(_ value: DragGesture.Value) {
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
    
    func handleDragEnded(_ value: DragGesture.Value) {
        guard isInDeleteMode else { return }
        let finalTranslation = value.translation.height
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if showDeleteButton {
                if finalTranslation > -80 {
                    exitDeleteMode()
                } else {
                    dragOffset = -180
                }
            } else {
                dragOffset = 0
            }
        }
    }
}
