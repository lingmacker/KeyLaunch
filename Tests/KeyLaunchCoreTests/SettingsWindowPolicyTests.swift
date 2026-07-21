import AppKit
import Testing
@testable import KeyLaunchApp

@MainActor
@Test("Settings window disables minimize and maximize controls")
func settingsWindowDisablesMinimizeAndMaximize() {
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 720, height: 500),
        styleMask: [.titled, .closable, .miniaturizable, .resizable],
        backing: .buffered,
        defer: false
    )

    SettingsWindowPolicy.configure(window)

    #expect(!window.styleMask.contains(.miniaturizable))
    #expect(window.standardWindowButton(.miniaturizeButton)?.isEnabled == false)
    #expect(window.standardWindowButton(.zoomButton)?.isEnabled == false)
    #expect(window.isVisible)
}
