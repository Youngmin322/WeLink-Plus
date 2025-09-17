//
//  FriendsUIComponents.swift
//  WeLink
//
//  Created by 조영민 on 8/13/25.
//

import SwiftUI

// MARK: - Header View
struct FriendsHeaderView: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @FocusState.Binding var isTextFieldFocused: Bool
    let onToggleSearch: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                titleView
                    .opacity(isSearching ? 0 : 1)
                    .animation(.easeInOut(duration: 0.25), value: isSearching)
                    .opacity(isSearching ? 1 : 0)
                    .animation(.easeInOut(duration: 0.25), value: isSearching)
            }
        }
    }
    
    private var titleView: some View {
        HStack {
            Text("친구")
                .font(.custom("Pretendard-Bold", size: 35))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

// MARK: - Empty State View
struct FriendsEmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: searchText.isEmpty ? "person.3" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.8))
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            
            Text(searchText.isEmpty ? "아직 친구가 없어요" : "검색 결과가 없어요")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            
            Text(searchText.isEmpty ? "+ 버튼을 눌러 첫 번째 친구를 추가해보세요!" : "다른 이름으로 검색해보세요")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Background Image View
struct BackgroundImageView: View {
    let cards: [CardModel]
    let currentIndex: Int
    let preloadedImages: [Int: UIImage]
    
    @State private var isScrolling = false
    @State private var scrollTimer: Timer?
    
    var body: some View {
        Color.black
            .overlay(
                Group {
                    if !cards.isEmpty &&
                        currentIndex >= 0 &&
                        currentIndex < cards.count,
                       let currentImage = preloadedImages[currentIndex] {
                        Image(uiImage: currentImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .scaleEffect(1.1)
                            .blur(radius: 4)
                            .overlay(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.5),
                                        Color.black.opacity(0.3),
                                        Color.black.opacity(0.7)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .animation(
                                isScrolling ? .none : .easeInOut(duration: 0.4),
                                value: currentIndex
                            )
                    }
                }
            )
            .clipped()
            .onChange(of: currentIndex) { _, _ in
                handleIndexChange()
            }
            .allowsHitTesting(false)
    }
    
    private func handleIndexChange() {
        isScrolling = true
        
        scrollTimer?.invalidate()
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                isScrolling = false
            }
        }
    }
}

