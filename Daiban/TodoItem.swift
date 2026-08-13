import Foundation

struct TodoItem: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var isDone: Bool
    var createdAt: Date
    var doneAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        isDone: Bool = false,
        createdAt: Date = Date(),
        doneAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.createdAt = createdAt
        self.doneAt = doneAt
    }
}

struct TodoFile: Codable {
    var items: [TodoItem]
}
