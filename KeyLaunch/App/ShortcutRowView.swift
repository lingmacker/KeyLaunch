import KeyboardShortcuts
import SwiftUI

struct ShortcutRowView: View {
    let row: LaunchRow
    let apps: [InstalledApp]
    @Bindable var model: KeyLaunchModel
    @State private var isDeleteHovered = false

    var body: some View {
        Grid(horizontalSpacing: SettingsLayout.rowHorizontalSpacing, verticalSpacing: 0) {
            GridRow {
                shortcutRecorder
                    .frame(width: SettingsLayout.shortcutColumnWidth, alignment: .leading)

                appPicker
                    .frame(maxWidth: .infinity)

                deleteButton
                    .frame(width: SettingsLayout.actionColumnWidth)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var shortcutRecorder: some View {
        if let shortcutName = KeyboardShortcuts.Name(rawValue: row.shortcutName) {
            KeyboardShortcuts.Recorder("", name: shortcutName)
                .frame(width: SettingsLayout.shortcutRecorderWidth, alignment: .leading)
        } else {
            Text("快捷键不可用")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: SettingsLayout.shortcutRecorderWidth, alignment: .leading)
        }
    }

    private var appPicker: some View {
        Picker("", selection: Binding(
            get: { row.app.bundleID },
            set: { bundleID in
                guard let app = apps.first(where: { $0.bundleID == bundleID }) else {
                    return
                }
                model.selectApp(app, for: row)
            }
        )) {
            ForEach(apps) { app in
                Text(app.displayName).tag(app.bundleID)
            }
        }
        .labelsHidden()
        .accessibilityLabel("打开的 App")
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            model.deleteRow(row)
        } label: {
            Image(systemName: "trash")
                .foregroundStyle(isDeleteHovered ? .red : .secondary)
        }
        .buttonStyle(.borderless)
        .onHover { isHovered in
            isDeleteHovered = isHovered
        }
        .help("删除")
        .accessibilityLabel("删除")
    }
}
