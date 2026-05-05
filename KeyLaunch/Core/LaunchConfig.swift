import Foundation

public struct InstalledApp: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: String { bundleID }

    public let displayName: String
    public let bundleID: String
    public let path: String

    public init(displayName: String, bundleID: String, path: String) {
        self.displayName = displayName
        self.bundleID = bundleID
        self.path = path
    }
}

public struct LaunchRow: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let shortcutName: String
    public let app: InstalledApp

    public init(id: UUID = UUID(), shortcutName: String, app: InstalledApp) {
        self.id = id
        self.shortcutName = shortcutName
        self.app = app
    }
}

public enum LaunchConfigError: Error, Equatable, Sendable {
    case duplicateShortcut(String)
    case missingAppBundleID
    case invalidAppPath(String)
    case rowNotFound(UUID)
}

public struct LaunchConfig: Codable, Equatable, Sendable {
    public let rows: [LaunchRow]

    public init(rows: [LaunchRow] = []) {
        self.rows = rows
    }

    public func adding(_ row: LaunchRow) throws(LaunchConfigError) -> LaunchConfig {
        try validate(row)
        return LaunchConfig(rows: rows + [row])
    }

    public func deleting(rowID: LaunchRow.ID) -> LaunchConfig {
        LaunchConfig(rows: rows.filter { $0.id != rowID })
    }

    public func updating(_ row: LaunchRow) throws(LaunchConfigError) -> LaunchConfig {
        guard rows.contains(where: { $0.id == row.id }) else {
            throw .rowNotFound(row.id)
        }
        try validate(row, excluding: row.id)
        return LaunchConfig(rows: rows.map { $0.id == row.id ? row : $0 })
    }

    private func validate(_ row: LaunchRow, excluding excludedID: LaunchRow.ID? = nil) throws(LaunchConfigError) {
        guard !row.app.bundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw .missingAppBundleID
        }
        guard row.app.path.hasPrefix("/") && row.app.path.hasSuffix(".app") else {
            throw .invalidAppPath(row.app.path)
        }

        let hasDuplicateShortcut = rows.contains { existingRow in
            existingRow.id != excludedID && existingRow.shortcutName == row.shortcutName
        }
        guard !hasDuplicateShortcut else {
            throw .duplicateShortcut(row.shortcutName)
        }
    }
}

public extension Sequence where Element == InstalledApp {
    func sortedByDisplayName() -> [InstalledApp] {
        sorted { first, second in
            first.displayName.localizedStandardCompare(second.displayName) == .orderedAscending
        }
    }
}
