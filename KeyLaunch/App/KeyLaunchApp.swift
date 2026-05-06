import AppKit
import SwiftUI

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
                .frame(width: 640, height: 420)
                .background(SettingsWindowConfigurator())
        }
        .windowResizability(.contentSize)
    }
}

private struct SettingsWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        SettingsWindowConfigurationView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class SettingsWindowConfigurationView: NSView {
    private var hasConfiguredWindow = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        guard !hasConfiguredWindow, let window else {
            return
        }

        hasConfiguredWindow = true
        window.styleMask.remove(.miniaturizable)
        // window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isEnabled = false
    }
}

