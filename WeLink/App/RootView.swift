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
            if (myID.count > 0 && cards.contains { $0.id == myID.last!.id }) {
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
