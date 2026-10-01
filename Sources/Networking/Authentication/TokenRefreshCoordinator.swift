import Foundation

/// Concurrency-safe coordinator for refreshing authentication tokens.
/// Ensures that when multiple concurrent requests encounter HTTP 401, only ONE actual refresh request is executed.
public actor TokenRefreshCoordinator {
    private let refreshHandler: @Sendable () async throws -> String
    private var activeRefreshTask: Task<String, any Error>?

    public init(refreshHandler: @Sendable @escaping () async throws -> String) {
        self.refreshHandler = refreshHandler
    }

    /// Requests a token refresh. If a refresh is already in progress, waits for the result of the ongoing refresh.
    public func refreshToken() async throws -> String {
        if let existingTask = activeRefreshTask {
            return try await existingTask.value
        }

        let task = Task<String, any Error> {
            try await refreshHandler()
        }

        self.activeRefreshTask = task

        defer {
            self.activeRefreshTask = nil
        }

        return try await task.value
    }
}
