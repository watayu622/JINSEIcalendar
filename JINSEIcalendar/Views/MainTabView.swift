import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            LifeGoalListView()
                .tabItem {
                    Label("やりたいこと", systemImage: "checklist")
                }

            PlaceListView()
                .tabItem {
                    Label("行きたい場所", systemImage: "map")
                }

            CalendarView()
                .tabItem {
                    Label("カレンダー", systemImage: "calendar")
                }
        }
        .tint(.orange)
    }
}
