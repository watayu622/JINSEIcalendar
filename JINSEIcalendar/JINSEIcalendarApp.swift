import SwiftUI
import SwiftData

@main
struct JINSEIcalendarApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [LifeGoal.self, PlaceToVisit.self])
    }
}
