//
//  ContentView.swift
//  Wishing
//
//  Created by 조영민 on 8/4/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 1
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MenuTabView()
                .tabItem {
                    Image(systemName: "line.3.horizontal")
                    Text("메뉴")
                }
                .tag(0)
            
            FriendsTabView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("메인")
                }
                .tag(1)
            
            MyProfileTabView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("마이페이지")
                }
                .tag(2)
        }
        .accentColor(Color("MainColor")) // 선택된 탭의 색상
    }
}

#Preview {
    ContentView()
        .modelContainer(for: CardModel.self, inMemory: true)
}
