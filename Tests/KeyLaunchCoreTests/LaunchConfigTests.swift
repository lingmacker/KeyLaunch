import Testing
@testable import KeyLaunchCore

@Test("Adding a row returns a new config and keeps the original unchanged")
func addRowIsImmutable() throws {
    let original = LaunchConfig(rows: [])
    let app = InstalledApp(displayName: "Safari", bundleID: "com.apple.Safari", path: "/Applications/Safari.app")
    let row = LaunchRow(shortcutName: "shortcut-1", app: app)

    let updated = try original.adding(row)

    #expect(original.rows.isEmpty)
    #expect(updated.rows == [row])
}

@Test("Deleting a row returns a config without the matching row")
func deleteRowRemovesMatchingID() throws {
    let safari = InstalledApp(displayName: "Safari", bundleID: "com.apple.Safari", path: "/Applications/Safari.app")
    let notes = InstalledApp(displayName: "Notes", bundleID: "com.apple.Notes", path: "/Applications/Notes.app")
    let firstRow = LaunchRow(shortcutName: "shortcut-1", app: safari)
    let secondRow = LaunchRow(shortcutName: "shortcut-2", app: notes)
    let config = LaunchConfig(rows: [firstRow, secondRow])

    let updated = config.deleting(rowID: firstRow.id)

    #expect(updated.rows == [secondRow])
    #expect(config.rows == [firstRow, secondRow])
}

@Test("Adding a duplicate shortcut throws an explicit validation error")
func addDuplicateShortcutThrows() throws {
    let safari = InstalledApp(displayName: "Safari", bundleID: "com.apple.Safari", path: "/Applications/Safari.app")
    let notes = InstalledApp(displayName: "Notes", bundleID: "com.apple.Notes", path: "/Applications/Notes.app")
    let config = LaunchConfig(rows: [LaunchRow(shortcutName: "shortcut-1", app: safari)])
    let duplicate = LaunchRow(shortcutName: "shortcut-1", app: notes)

    #expect(throws: LaunchConfigError.duplicateShortcut("shortcut-1")) {
        try config.adding(duplicate)
    }
}

@Test("Updating a row replaces only the matching row")
func updateRowReplacesMatchingID() throws {
    let safari = InstalledApp(displayName: "Safari", bundleID: "com.apple.Safari", path: "/Applications/Safari.app")
    let notes = InstalledApp(displayName: "Notes", bundleID: "com.apple.Notes", path: "/Applications/Notes.app")
    let originalRow = LaunchRow(shortcutName: "shortcut-1", app: safari)
    let unchangedRow = LaunchRow(shortcutName: "shortcut-2", app: notes)
    let replacement = LaunchRow(id: originalRow.id, shortcutName: "shortcut-3", app: notes)
    let config = LaunchConfig(rows: [originalRow, unchangedRow])

    let updated = try config.updating(replacement)

    #expect(updated.rows == [replacement, unchangedRow])
    #expect(config.rows == [originalRow, unchangedRow])
}

@Test("Installed apps are sorted by localized display name")
func installedAppsAreSortedByDisplayName() {
    let apps = [
        InstalledApp(displayName: "Notes", bundleID: "com.apple.Notes", path: "/Applications/Notes.app"),
        InstalledApp(displayName: "Finder", bundleID: "com.apple.finder", path: "/System/Library/CoreServices/Finder.app")
    ]

    #expect(apps.sortedByDisplayName().map(\.displayName) == ["Finder", "Notes"])
}
