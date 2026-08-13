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
                Text(item.title)
                    .font(.body)
                    .strikethrough(item.isDone)
                    .foregroundStyle(item.isDone ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
}
