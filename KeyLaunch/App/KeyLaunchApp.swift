import AppKit
import KeyboardShortcuts
import ServiceManagement
import SwiftUI


extension KeyboardShortcuts.Name {
    static let row1 = Self("launch-row-1")
    static let row2 = Self("launch-row-2")
    static let row3 = Self("launch-row-3")
    static let row4 = Self("launch-row-4")
    static let row5 = Self("launch-row-5")
    static let row6 = Self("launch-row-6")
    static let row7 = Self("launch-row-7")
    static let row8 = Self("launch-row-8")
    static let row9 = Self("launch-row-9")
    static let row10 = Self("launch-row-10")
}

private let shortcutNames: [KeyboardShortcuts.Name] = [
    .row1, .row2, .row3, .row4, .row5, .row6, .row7, .row8, .row9, .row10
]

private enum SettingsLayout {
    static let shortcutColumnWidth: CGFloat = 168
    static let shortcutRecorderWidth: CGFloat = 132
    static let actionColumnWidth: CGFloat = 48
    static let rowHorizontalSpacing: CGFloat = 18
    static let cardCornerRadius: CGFloat = 16
}

final class KeyLaunchAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        AppLifecyclePolicy.shouldTerminateAfterLastWindowClosed
    }
}

@main
struct KeyLaunchApp: App {
    @NSApplicationDelegateAdaptor(KeyLaunchAppDelegate.self) private var appDelegate
    @State private var appModel = KeyLaunchModel()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra("KeyLaunch", image: "MenuBarIcon") {
            Toggle("开机启动", isOn: Binding(
                get: { appModel.isLaunchAtLoginEnabled },
                set: { appModel.setLaunchAtLoginEnabled($0) }
            ))
            Button("配置") {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
        }

        Window("", id: "settings") {
            SettingsView(model: appModel)
                .frame(minWidth: 640, minHeight: 420)
        }
    }
}

@Observable
@MainActor
final class KeyLaunchModel {
    private let store: JSONConfigStore
    private let appDiscoverer: ApplicationDirectoryDiscoverer

    var config: LaunchConfig
    var installedApps: [InstalledApp]
    var isLaunchAtLoginEnabled: Bool
    var errorMessage: String?

    init() {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let configURL = applicationSupport.appending(path: "KeyLaunch/config.json")
        let store = JSONConfigStore(fileURL: configURL)
        let appDiscoverer = ApplicationDirectoryDiscoverer()

        let installedApps = appDiscoverer.installedApps()
        let loadedConfig = try? store.load()
        let sanitizedConfig = LaunchConfigSanitizer().sanitized(loadedConfig ?? LaunchConfig(), using: installedApps)

        self.store = store
        self.appDiscoverer = appDiscoverer
        self.config = sanitizedConfig
        self.installedApps = installedApps
        self.isLaunchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        self.errorMessage = loadedConfig == nil ? "配置文件无法读取，已使用空配置。" : nil

        registerShortcutHandlers()
    }

    func reloadApps() {
        installedApps = appDiscoverer.installedApps()
    }

    func addRow() {
        guard let app = installedApps.first else {
            errorMessage = "没有找到可打开的 App。"
            return
        }
        guard let shortcutName = availableShortcutName() else {
            errorMessage = "最多支持 10 个快捷键配置。"
            return
        }

        do {
            try saveConfig(config.adding(LaunchRow(shortcutName: shortcutName.rawValue, app: app)))
        } catch {
            errorMessage = "新增配置失败。"
        }
    }

    func deleteRow(_ row: LaunchRow) {
        if let shortcutName = KeyboardShortcuts.Name(rawValue: row.shortcutName) {
            KeyboardShortcuts.reset(shortcutName)
        }
        saveConfig(config.deleting(rowID: row.id))
    }

    func selectApp(_ app: InstalledApp, for row: LaunchRow) {
        do {
            try saveConfig(config.updating(LaunchRow(id: row.id, shortcutName: row.shortcutName, app: app)))
        } catch {
            errorMessage = "保存配置失败。"
        }
    }

    func setLaunchAtLoginEnabled(_ isEnabled: Bool) {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            isLaunchAtLoginEnabled = isEnabled
        } catch {
            errorMessage = "开机启动设置失败。"
        }
    }

    func launchApp(for shortcutName: KeyboardShortcuts.Name) {
        guard let row = config.rows.first(where: { $0.shortcutName == shortcutName.rawValue }) else {
            return
        }
        guard installedApps.contains(where: { $0.bundleID == row.app.bundleID && $0.path == row.app.path }) else {
            errorMessage = "无法打开 App：配置已失效，请刷新 App 列表。"
            return
        }

        let url = URL(fileURLWithPath: row.app.path).resolvingSymlinksInPath()
        guard url.path.hasSuffix(".app"), FileManager.default.fileExists(atPath: url.path) else {
            errorMessage = "无法打开 App：应用不存在。"
            return
        }

        NSWorkspace.shared.openApplication(
            at: url,
            configuration: NSWorkspace.OpenConfiguration(),
            completionHandler: Self.appLaunchCompletionHandler(appDisplayName: row.app.displayName, model: self)
        )
    }

    private func saveConfig(_ newConfig: LaunchConfig) {
        do {
            try store.save(newConfig)
            config = newConfig
            errorMessage = nil
        } catch {
            errorMessage = "保存配置失败。"
        }
    }

    private func availableShortcutName() -> KeyboardShortcuts.Name? {
        let usedNames = Set(config.rows.map(\.shortcutName))
        return shortcutNames.first { !usedNames.contains($0.rawValue) }
    }

    nonisolated private static func appLaunchCompletionHandler(
        appDisplayName: String,
        model: KeyLaunchModel
    ) -> @Sendable (NSRunningApplication?, Error?) -> Void {
        { [weak model] _, error in
            let update = AppLaunchCompletion.update(for: error, appDisplayName: appDisplayName)
            Task { @MainActor in
                if case .mainActorErrorMessage(let message) = update {
                    model?.errorMessage = message
                }
            }
        }
    }

    private func registerShortcutHandlers() {
        for name in shortcutNames {
            KeyboardShortcuts.onKeyUp(for: name) { [weak self] in
                Task { @MainActor in
                    self?.launchApp(for: name)
                }
            }
        }
    }
}

struct SettingsView: View {
    @Bindable var model: KeyLaunchModel

    var body: some View {
        VStack(spacing: 0) {
            header
            content
                .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("快捷启动")
                    .font(.title2.weight(.semibold))
                Text("设置快捷键，一键打开常用 App")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                model.reloadApps()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("刷新 App 列表")
            .accessibilityLabel("刷新 App 列表")

            Button {
                model.addRow()
            } label: {
                Image(systemName: "plus")
            }
            .help("新增快捷键配置")
            .accessibilityLabel("新增快捷键配置")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 12) {
            if model.config.rows.isEmpty {
                ContentUnavailableView(
                    "暂无快捷键配置",
                    systemImage: "keyboard",
                    description: Text("点击右上角加号添加一条快捷键启动规则。")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: SettingsLayout.cardCornerRadius))
            } else {
                VStack(spacing: 0) {
                    tableHeader
                    Divider()
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(model.config.rows) { row in
                                ShortcutRowView(row: row, apps: model.installedApps, model: model)
                                Divider()
                            }
                        }
                    }
                }
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: SettingsLayout.cardCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: SettingsLayout.cardCornerRadius)
                        .stroke(.separator.opacity(0.45))
                )
            }

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var tableHeader: some View {
        Grid(horizontalSpacing: SettingsLayout.rowHorizontalSpacing, verticalSpacing: 0) {
            GridRow {
                Text("快捷键")
                    .frame(width: SettingsLayout.shortcutColumnWidth, alignment: .leading)
                    .padding(.leading, 15)
                Text("打开的 App")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                Text("操作")
                    .frame(width: SettingsLayout.actionColumnWidth, alignment: .center)
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct ShortcutRowView: View {
    let row: LaunchRow
    let apps: [InstalledApp]
    @Bindable var model: KeyLaunchModel

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
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .help("删除")
        .accessibilityLabel("删除")
    }
}
