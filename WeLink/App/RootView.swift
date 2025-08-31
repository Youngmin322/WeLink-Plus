//
//  RootView.swift
//  WeLink
//
//  Created by Youngmin Cho on 8/26/25.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var myID: [MyUUID]
    @Query private var cards: [CardModel]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            // 더 안전한 옵셔널 처리
            if let lastMyID = myID.last,
               cards.contains(where: { $0.id == lastMyID.id }) {
                ContentView()
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            if cards.isEmpty {
                CardDataProvider.insertDummyCards(into: modelContext)
            }
        }
    }
}
