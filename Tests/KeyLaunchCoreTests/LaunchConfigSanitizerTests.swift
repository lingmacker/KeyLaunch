import Foundation
import Testing
@testable import KeyLaunchCore

@Test("Sanitizer keeps trusted apps and replaces persisted app metadata")
func sanitizerKeepsTrustedApps() throws {
    let trustedSafari = InstalledApp(displayName: "Safari", bundleID: "com.apple.Safari", path: "/Applications/Safari.app")
    let tamperedSafari = InstalledApp(displayName: "Fake Safari", bundleID: "com.apple.Safari", path: "/tmp/Fake.app")
    let row = LaunchRow(shortcutName: "shortcut-1", app: tamperedSafari)
    let config = LaunchConfig(rows: [row])

    let sanitized = LaunchConfigSanitizer().sanitized(config, using: [trustedSafari])

    #expect(sanitized.rows == [LaunchRow(id: row.id, shortcutName: row.shortcutName, app: trustedSafari)])
}

@Test("Sanitizer drops rows for apps that are not currently installed")
func sanitizerDropsUnknownApps() {
    let unknownApp = InstalledApp(displayName: "Unknown", bundleID: "example.unknown", path: "/tmp/Unknown.app")
    let config = LaunchConfig(rows: [LaunchRow(shortcutName: "shortcut-1", app: unknownApp)])

    let sanitized = LaunchConfigSanitizer().sanitized(config, using: [])

    #expect(sanitized.rows.isEmpty)
}

@Test("Sanitizer drops duplicate shortcuts")
func sanitizerDropsDuplicateShortcuts() {
    let safari = InstalledApp(displayName: "Safari", bundleID: "com.apple.Safari", path: "/Applications/Safari.app")
    let notes = InstalledApp(displayName: "Notes", bundleID: "com.apple.Notes", path: "/Applications/Notes.app")
    let firstRow = LaunchRow(shortcutName: "shortcut-1", app: safari)
    let secondRow = LaunchRow(shortcutName: "shortcut-1", app: notes)
    let config = LaunchConfig(rows: [firstRow, secondRow])

    let sanitized = LaunchConfigSanitizer().sanitized(config, using: [safari, notes])

    #expect(sanitized.rows == [firstRow])
}

@Test("Sanitizer keeps first installed app when bundle IDs are duplicated")
func sanitizerKeepsFirstDuplicateBundleID() {
    let firstSafari = InstalledApp(displayName: "Safari", bundleID: "com.apple.Safari", path: "/Applications/Safari.app")
    let secondSafari = InstalledApp(displayName: "Safari Copy", bundleID: "com.apple.Safari", path: "/Users/example/Applications/Safari.app")
    let tamperedSafari = InstalledApp(displayName: "Fake Safari", bundleID: "com.apple.Safari", path: "/tmp/Fake.app")
    let row = LaunchRow(shortcutName: "shortcut-1", app: tamperedSafari)
    let config = LaunchConfig(rows: [row])

    let sanitized = LaunchConfigSanitizer().sanitized(config, using: [firstSafari, secondSafari])

    #expect(sanitized.rows == [LaunchRow(id: row.id, shortcutName: row.shortcutName, app: firstSafari)])
}

@Test("Adding a row rejects unsafe app paths")
func addingRowRejectsUnsafeAppPath() {
    let unsafeApp = InstalledApp(displayName: "Unsafe", bundleID: "example.unsafe", path: "../../Unsafe.app")
    let row = LaunchRow(shortcutName: "shortcut-1", app: unsafeApp)

    #expect(throws: LaunchConfigError.invalidAppPath("../../Unsafe.app")) {
        try LaunchConfig().adding(row)
    }
}
