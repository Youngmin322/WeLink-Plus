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

            // 검색 전용 탭
            Tab(role: .search) {
                NavigationStack {
                    Text("aaa")
                        .navigationTitle("검색")
                }
                // ✅ 검색 탭에만 searchable 적용
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
