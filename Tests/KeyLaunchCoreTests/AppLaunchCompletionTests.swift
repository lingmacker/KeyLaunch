import Foundation
import Testing
@testable import KeyLaunchCore

@Test("Launch completion defers state update to main actor")
func launchCompletionDefersStateUpdateToMainActor() {
    let successUpdate = AppLaunchCompletion.update(for: nil, appDisplayName: "Safari")
    let failureUpdate = AppLaunchCompletion.update(for: NSError(domain: "test", code: 1), appDisplayName: "Safari")

    #expect(successUpdate == .mainActorErrorMessage(nil))
    #expect(failureUpdate == .mainActorErrorMessage("无法打开 App：Safari。"))
}
