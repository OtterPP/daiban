import SwiftUI

struct TodoRowView: View {
    let item: TodoItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onPolish: () async -> Void

    @State private var hovering = false
    @State private var polishing = false

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onToggle) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isDone ? Color.accentColor : Color.secondary)
                    .imageScale(.medium)
            }
            .buttonStyle(.plain)
            .help(item.isDone ? "标为未完成" : "完成")

            Button(action: onToggle) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.body)
                        .strikethrough(item.isDone)
                        .foregroundStyle(item.isDone ? .secondary : .primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    subtitle
                }
            }
            .buttonStyle(.plain)
            .help(item.isDone ? "点一下恢复" : "点一下完成")

            if hovering || polishing {
                Button {
                    Task {
                        polishing = true
                        await onPolish()
                        polishing = false
                    }
                } label: {
                    if polishing {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("润色")
                .disabled(polishing)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("删除")
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .contextMenu {
            Button(item.isDone ? "恢复" : "完成", action: onToggle)
            Button("润色") {
                Task { await onPolish() }
            }
            Divider()
            Button("删除", role: .destructive, action: onDelete)
        }
    }

    /// Recorded time is always shown. 「过期」 is only for incomplete past-due items;
    /// completed rows keep struck-through title styling and never show the red badge.
    /// `TimelineView` refreshes at `dueAt` so an open popover can flip to overdue
    /// without a hover or store mutation.
    private var subtitle: some View {
        TimelineView(.explicit(overdueRefreshDates)) { context in
            HStack(spacing: 6) {
                Text("记下 \(TodoItem.displayDate(item.createdAt))")
                    .foregroundStyle(.secondary)
                if item.isOverdue(at: context.date), let dueAt = item.dueAt {
                    Text("过期 · \(TodoItem.displayDate(dueAt))")
                        .foregroundStyle(Color(.systemRed))
                }
            }
            .font(.caption)
        }
    }

    private var overdueRefreshDates: [Date] {
        guard !item.isDone, let dueAt = item.dueAt, dueAt > Date() else { return [] }
        return [dueAt]
    }
}
