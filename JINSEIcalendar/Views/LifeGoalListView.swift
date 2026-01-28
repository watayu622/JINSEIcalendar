import SwiftUI
import SwiftData

struct LifeGoalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LifeGoal.createdAt, order: .reverse) private var goals: [LifeGoal]
    @State private var showingAddSheet = false
    @State private var filterCompleted = false

    private var filteredGoals: [LifeGoal] {
        if filterCompleted {
            return goals
        }
        return goals.filter { !$0.isCompleted }
    }

    private var categories: [String] {
        Array(Set(filteredGoals.map { $0.category })).sorted()
    }

    var body: some View {
        NavigationStack {
            Group {
                if goals.isEmpty {
                    ContentUnavailableView(
                        "やりたいことを追加しよう",
                        systemImage: "star.fill",
                        description: Text("人生でやりたいことを登録して\n夢を実現しましょう")
                    )
                } else {
                    List {
                        ForEach(categories, id: \.self) { category in
                            Section(category) {
                                ForEach(filteredGoals.filter { $0.category == category }) { goal in
                                    LifeGoalRow(goal: goal)
                                }
                                .onDelete { indexSet in
                                    deleteGoals(category: category, at: indexSet)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("やりたいことリスト")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        filterCompleted.toggle()
                    } label: {
                        Image(systemName: filterCompleted ? "eye" : "eye.slash")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddLifeGoalView()
            }
        }
    }

    private func deleteGoals(category: String, at offsets: IndexSet) {
        let categoryGoals = filteredGoals.filter { $0.category == category }
        for index in offsets {
            modelContext.delete(categoryGoals[index])
        }
    }
}

struct LifeGoalRow: View {
    @Bindable var goal: LifeGoal

    var body: some View {
        HStack {
            Button {
                withAnimation {
                    goal.isCompleted.toggle()
                }
            } label: {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(goal.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .strikethrough(goal.isCompleted)
                    .foregroundStyle(goal.isCompleted ? .secondary : .primary)
                    .font(.body)

                if !goal.detail.isEmpty {
                    Text(goal.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let deadline = goal.deadline {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text(deadline, style: .date)
                    }
                    .font(.caption2)
                    .foregroundStyle(deadline < Date() && !goal.isCompleted ? .red : .secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct AddLifeGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var detail = ""
    @State private var category = "その他"
    @State private var hasDeadline = false
    @State private var deadline = Date()

    private let categories = ["キャリア", "健康", "趣味", "旅行", "学び", "人間関係", "お金", "その他"]

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("やりたいこと", text: $title)
                    TextField("詳細メモ", text: $detail, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("期限") {
                    Toggle("期限を設定", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("期限日", selection: $deadline, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("新しい目標")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        let goal = LifeGoal(
                            title: title,
                            detail: detail,
                            deadline: hasDeadline ? deadline : nil,
                            category: category
                        )
                        modelContext.insert(goal)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
