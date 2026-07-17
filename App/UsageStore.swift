import Foundation
import WidgetKit

/// Single source of truth for the menu bar label and the popover content.
/// The widget extension is a separate process and keeps reading/writing
/// SharedDefaults directly (see ClaudeUsageTimelineProvider) — this store
/// exists only for the in-app menu bar UI.
@MainActor
final class UsageStore: ObservableObject {
    @Published private(set) var usage: ClaudeUsageResponse?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isConnected: Bool
    @Published private(set) var isBusy = false

    private var refreshTask: Task<Void, Never>?

    init() {
        isConnected = (SharedDefaults.shared.sessionKey?.isEmpty == false)
        usage = SharedDefaults.shared.cachedUsage()
        lastUpdated = SharedDefaults.shared.lastUpdated
        startAutoRefresh()
    }

    var fiveHourPercent: Int? {
        usage?.fiveHour.map { Int($0.utilization.rounded()) }
    }

    func connect(sessionKey: String) async {
        let key = sessionKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }

        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            let result = try await ClaudeUsageService.shared.fetchCurrentUsage(sessionKey: key)
            SharedDefaults.shared.sessionKey = key
            SharedDefaults.shared.cache(result)
            usage = result
            lastUpdated = .now
            isConnected = true
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        guard let key = SharedDefaults.shared.sessionKey, !key.isEmpty else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            let result = try await ClaudeUsageService.shared.fetchCurrentUsage(sessionKey: key)
            usage = result
            lastUpdated = .now
            SharedDefaults.shared.cache(result)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func disconnect() {
        SharedDefaults.shared.sessionKey = nil
        isConnected = false
        usage = nil
        errorMessage = nil
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                await self.refresh()
                try? await Task.sleep(for: .seconds(5 * 60))
            }
        }
    }
}
