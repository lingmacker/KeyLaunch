import Foundation

public enum AppLaunchCompletionUpdate: Equatable {
    case mainActorErrorMessage(String?)
}

public enum AppLaunchCompletion {
    public static func update(for error: Error?, appDisplayName: String) -> AppLaunchCompletionUpdate {
        .mainActorErrorMessage(error == nil ? nil : "无法打开 App：\(appDisplayName)。")
    }
}
