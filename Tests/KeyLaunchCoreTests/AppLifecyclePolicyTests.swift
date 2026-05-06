import Testing
@testable import KeyLaunchApp

@Test("Menu bar app stays alive when windows close")
func menuBarAppStaysAliveWhenWindowsClose() {
    #expect(AppLifecyclePolicy.shouldTerminateAfterLastWindowClosed == false)
}
