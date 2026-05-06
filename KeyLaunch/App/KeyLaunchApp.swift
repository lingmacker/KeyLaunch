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
                .frame(minWidth: 640, minHeight: 420)
        }
    }
}

