import Foundation

public struct LaunchConfigSanitizer: Sendable {
    public init() {}

    public func sanitized(_ config: LaunchConfig, using installedApps: [InstalledApp]) -> LaunchConfig {
        let appsByBundleID = installedApps.reduce(into: [String: InstalledApp]()) { appsByBundleID, app in
            guard appsByBundleID[app.bundleID] == nil else {
                return
            }
            appsByBundleID[app.bundleID] = app
        }

        return config.rows.reduce(LaunchConfig()) { sanitizedConfig, row in
            guard let trustedApp = appsByBundleID[row.app.bundleID] else {
                return sanitizedConfig
            }
            let trustedRow = LaunchRow(id: row.id, shortcutName: row.shortcutName, app: trustedApp)
            guard let updatedConfig = try? sanitizedConfig.adding(trustedRow) else {
                return sanitizedConfig
            }
            return updatedConfig
        }
    }
}
