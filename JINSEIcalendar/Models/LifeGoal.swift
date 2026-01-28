import Foundation
import SwiftData

@Model
final class LifeGoal {
    var id: UUID
    var title: String
    var detail: String
    var deadline: Date?
    var isCompleted: Bool
    var category: String
    var createdAt: Date

    init(
        title: String,
        detail: String = "",
        deadline: Date? = nil,
        isCompleted: Bool = false,
        category: String = "その他"
    ) {
        self.id = UUID()
        self.title = title
        self.detail = detail
        self.deadline = deadline
        self.isCompleted = isCompleted
        self.category = category
        self.createdAt = Date()
    }
}
