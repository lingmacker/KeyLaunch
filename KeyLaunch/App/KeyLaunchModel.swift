import AppKit
import Foundation
import KeyboardShortcuts
import Observation
import ServiceManagement

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
            let newConfig = try config.adding(LaunchRow(shortcutName: shortcutName.rawValue, app: app))
            saveConfig(newConfig)
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
            let newConfig = try config.updating(LaunchRow(id: row.id, shortcutName: row.shortcutName, app: app))
            saveConfig(newConfig)
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
