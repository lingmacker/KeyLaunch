import Foundation

public enum ConfigStoreError: Error, Equatable, Sendable {
    case decodeFailed
    case encodeFailed
    case writeFailed
}

public protocol ConfigStoring: Sendable {
    func load() throws(ConfigStoreError) -> LaunchConfig
    func save(_ config: LaunchConfig) throws(ConfigStoreError)
}

public struct JSONConfigStore: ConfigStoring, @unchecked Sendable {
    private let fileURL: URL
    private let fileManager: FileManager

    public init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    public func load() throws(ConfigStoreError) -> LaunchConfig {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return LaunchConfig()
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            throw .decodeFailed
        }

        do {
            return try JSONDecoder().decode(LaunchConfig.self, from: data)
        } catch {
            throw .decodeFailed
        }
    }

    public func save(_ config: LaunchConfig) throws(ConfigStoreError) {
        guard let data = try? JSONEncoder().encode(config) else {
            throw .encodeFailed
        }

        do {
            try fileManager.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw .writeFailed
        }
    }
}
