import AppKit
import KeyboardShortcuts
import SwiftUI

struct ShortcutRowView: View {
    let row: LaunchRow
    let apps: [InstalledApp]
    @Bindable var model: KeyLaunchModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRowHovered = false
    @State private var isDeleteHovered = false

    private var isSelectedAppAvailable: Bool {
        apps.contains { $0.bundleID == row.app.bundleID }
    }

    var body: some View {
        Grid(horizontalSpacing: SettingsLayout.rowHorizontalSpacing, verticalSpacing: 0) {
            GridRow {
                shortcutRecorder
                    .frame(width: SettingsLayout.shortcutColumnWidth, alignment: .leading)

                appPicker
                    .frame(maxWidth: .infinity, alignment: .leading)

                deleteButton
                    .frame(width: SettingsLayout.actionColumnWidth)
            }
        }
        .frame(minHeight: SettingsLayout.rowMinHeight)
        .padding(.horizontal, 14)
        .background(isRowHovered ? Color.primary.opacity(0.035) : .clear)
        .contentShape(Rectangle())
        .onHover { isHovered in
            isRowHovered = isHovered
        }
        .animation(
            reduceMotion ? nil : .easeOut(duration: 0.16),
            value: isRowHovered
        )
    }

    @ViewBuilder
    private var shortcutRecorder: some View {
        if let shortcutName = KeyboardShortcuts.Name(rawValue: row.shortcutName) {
            KeyboardShortcuts.Recorder("", name: shortcutName)
                .frame(width: SettingsLayout.shortcutRecorderWidth, alignment: .leading)
                .accessibilityLabel("\(row.app.displayName) 的快捷键")
        } else {
            Label("快捷键不可用", systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .frame(width: SettingsLayout.shortcutRecorderWidth, alignment: .leading)
        }
    }

    private var appPicker: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: row.app.path))
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)

            Picker("打开的 App", selection: Binding(
                get: { row.app.bundleID },
                set: { bundleID in
                    guard let app = apps.first(where: { $0.bundleID == bundleID }) else {
                        return
                    }
                    model.selectApp(app, for: row)
                }
            )) {
                if !isSelectedAppAvailable {
                    Text("\(row.app.displayName)（不可用）")
                        .tag(row.app.bundleID)
                }

                ForEach(apps) { app in
                    Text(app.displayName)
                        .tag(app.bundleID)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("打开的 App")

            if !isSelectedAppAvailable {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .help("这个 App 当前不可用")
                    .accessibilityLabel("这个 App 当前不可用")
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            model.deleteRow(row)
        } label: {
            Image(systemName: "trash")
                .foregroundStyle(isDeleteHovered ? .red : .secondary)
                .frame(width: 28, height: 28)
                .background(
                    isDeleteHovered ? Color.red.opacity(0.1) : .clear,
                    in: RoundedRectangle(cornerRadius: 7)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered in
            isDeleteHovered = isHovered
        }
        .animation(
            reduceMotion ? nil : .easeOut(duration: 0.16),
            value: isDeleteHovered
        )
        .help("删除 \(row.app.displayName) 的快捷键")
        .accessibilityLabel("删除 \(row.app.displayName) 的快捷键")
    }
}
