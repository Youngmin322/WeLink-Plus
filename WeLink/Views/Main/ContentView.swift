//
//  ContentView.swift
//  Wishing
//
//  Created by 조영민 on 8/4/25.
//

import SwiftUI

struct ContentView: View {
    @State private var searchText = ""

    var body: some View {
        TabView {
            Tab("메인", systemImage: "person.3.fill") {
                NavigationStack {
                    FriendsTabView()
                }
            }

            Tab("캘린더", systemImage: "calendar") {
                NavigationStack {
                    MenuTabView()
                }
            }

            Tab("마이페이지", systemImage: "person.crop.circle") {
                NavigationStack {
                    MyProfileTabView()
                }
            }

            Tab(role: .search) {
                NavigationStack {
                    Text("aaa")
                        .navigationTitle("검색")
                }
                .searchable(text: $searchText)
            }
        }
        .tint(Color("MainColor"))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: CardModel.self, inMemory: true)
}
