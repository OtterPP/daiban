import AppKit
import SwiftUI

struct PopoverView: View {
    @EnvironmentObject private var store: TodoStore
    @Environment(\.openSettings) private var openSettings

    @State private var draft = ""
    @State private var isPolishing = false
    @State private var banner: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            captureRow
            if let banner {
                Text(banner)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            if store.openItems.isEmpty && store.recentCompletedItems.isEmpty {
                Text("还没有待办。输入后按回车。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if !store.openItems.isEmpty {
                            section(title: "未完成") {
                                ForEach(store.openItems) { item in
                                    TodoRowView(
                                        item: item,
                                        onToggle: { store.toggle(item.id) },
                                        onDelete: { store.delete(item.id) },
                                        onPolish: { await polishItem(item) }
                                    )
                                }
                            }
                        }

                        if !store.recentCompletedItems.isEmpty {
                            section(title: "已完成") {
                                ForEach(store.recentCompletedItems) { item in
                                    TodoRowView(
                                        item: item,
                                        onToggle: { store.toggle(item.id) },
                                        onDelete: { store.delete(item.id) },
                                        onPolish: { await polishItem(item) }
                                    )
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 320)
            }

            Divider()

            HStack {
                Button("设置…") {
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button("退出") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(12)
        .frame(width: 340)
        .onAppear {
            banner = nil
        }
    }

    private var captureRow: some View {
        HStack(spacing: 8) {
            CaptureTextField(text: $draft, placeholder: "记一件事") {
                addDraft()
            }
            .frame(minWidth: 160, maxWidth: .infinity)
            .frame(height: 24)

            Button {
                Task { await polishDraft() }
            } label: {
                if isPolishing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("润色")
                }
            }
            .buttonStyle(.borderless)
            .disabled(isPolishing || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .help("润色成一条可勾选的短待办")
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func addDraft() {
        store.add(draft)
        draft = ""
        banner = nil
    }

    private func polishDraft() async {
        let source = draft
        await runPolish(source) { polished in
            draft = polished
        }
    }

    private func polishItem(_ item: TodoItem) async {
        await runPolish(item.title) { polished in
            store.rename(item.id, to: polished)
        }
    }

    private func runPolish(_ source: String, apply: (String) -> Void) async {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isPolishing = true
        banner = nil
        defer { isPolishing = false }
        do {
            let polished = try await PolishService.polish(trimmed)
            apply(polished)
        } catch {
            banner = error.localizedDescription
        }
    }
}
