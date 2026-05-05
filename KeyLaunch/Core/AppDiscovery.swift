import Foundation

public protocol AppDiscovering: Sendable {
    func installedApps() -> [InstalledApp]
}

public struct ApplicationDirectoryDiscoverer: AppDiscovering, @unchecked Sendable {
    private let directories: [URL]
    private let fileManager: FileManager

    public init(
        directories: [URL] = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appending(path: "Applications", directoryHint: .isDirectory)
        ],
        fileManager: FileManager = .default
    ) {
        self.directories = directories
        self.fileManager = fileManager
    }

    public func installedApps() -> [InstalledApp] {
        let apps = directories.flatMap { directory in
            appURLs(in: directory).compactMap(installedApp)
        }
        return Array(Set(apps)).sortedByDisplayName()
    }

    private func appURLs(in directory: URL) -> [URL] {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        return enumerator.compactMap { item in
            guard let url = item as? URL, url.pathExtension == "app" else {
                return nil
            }
            return url
        }
    }

    private func installedApp(from url: URL) -> InstalledApp? {
        guard
            let bundle = Bundle(url: url),
            let bundleID = bundle.bundleIdentifier,
            !bundleID.isEmpty
        else {
            return nil
        }

        let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
        let name = displayName ?? bundleName ?? url.deletingPathExtension().lastPathComponent

        return InstalledApp(displayName: name, bundleID: bundleID, path: url.path)
    }
}
