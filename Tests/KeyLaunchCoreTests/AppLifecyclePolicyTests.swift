import Testing
@testable import KeyLaunchCore

@Test("Menu bar app stays alive when windows close")
func menuBarAppStaysAliveWhenWindowsClose() {
    #expect(AppLifecyclePolicy.shouldTerminateAfterLastWindowClosed == false)
}
