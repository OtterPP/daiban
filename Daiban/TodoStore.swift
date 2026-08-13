import Foundation
import SwiftUI

@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var items: [TodoItem] = []
    @Published private(set) var menuBarTitle = "待办 0"

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    var openItems: [TodoItem] {
        items.filter { !$0.isDone }.sorted { $0.createdAt > $1.createdAt }
    }

    /// Newest completed first; keep the section short.
    var recentCompletedItems: [TodoItem] {
        Array(
            items.filter(\.isDone)
                .sorted { ($0.doneAt ?? $0.createdAt) > ($1.doneAt ?? $1.createdAt) }
                .prefix(8)
        )
    }

    var openCount: Int {
        items.reduce(0) { $0 + ($1.isDone ? 0 : 1) }
    }

    init(fileURL: URL? = nil) {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let fileURL {
            self.fileURL = fileURL
        } else {
            self.fileURL = Self.defaultFileURL()
        }
        load()
    }

    func add(_ rawTitle: String) {
        let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        items.insert(TodoItem(title: title), at: 0)
        persist()
    }

    func toggle(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isDone.toggle()
        items[index].doneAt = items[index].isDone ? Date() : nil
        persist()
    }

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    func rename(_ id: UUID, to rawTitle: String) {
        let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].title = title
        persist()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            items = try decoder.decode(TodoFile.self, from: data).items
            refreshMenuBarTitle()
        } catch {
            NSLog("Daiban: failed to load todos: \(error.localizedDescription)")
        }
    }

    private func persist() {
        refreshMenuBarTitle()
        save()
    }

    private func refreshMenuBarTitle() {
        menuBarTitle = "待办 \(openCount)"
    }

    private func save() {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try encoder.encode(TodoFile(items: items))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("Daiban: failed to save todos: \(error.localizedDescription)")
        }
    }

    private static func defaultFileURL() -> URL {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return root
            .appendingPathComponent("Daiban", isDirectory: true)
            .appendingPathComponent("todos.json")
    }
}
