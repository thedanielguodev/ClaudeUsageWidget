import WidgetKit

struct ClaudeUsageEntry: TimelineEntry {
    let date: Date
    let usage: ClaudeUsageResponse?
    let errorMessage: String?
}

struct ClaudeUsageTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClaudeUsageEntry {
        ClaudeUsageEntry(date: .now, usage: .placeholder, errorMessage: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (ClaudeUsageEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        Task {
            completion(await currentEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClaudeUsageEntry>) -> Void) {
        Task {
            let entry = await currentEntry()
            // Widget refresh budgets are system-controlled; ask for another
            // pass in 15 minutes and let WidgetKit schedule around that.
            let nextRefresh = Date().addingTimeInterval(15 * 60)
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }

    private func currentEntry() async -> ClaudeUsageEntry {
        guard let sessionKey = SharedDefaults.shared.sessionKey, !sessionKey.isEmpty else {
            return ClaudeUsageEntry(
                date: .now,
                usage: SharedDefaults.shared.cachedUsage(),
                errorMessage: "Open the app to connect your account"
            )
        }

        do {
            let usage = try await ClaudeUsageService.shared.fetchCurrentUsage(sessionKey: sessionKey)
            SharedDefaults.shared.cache(usage)
            return ClaudeUsageEntry(date: .now, usage: usage, errorMessage: nil)
        } catch {
            return ClaudeUsageEntry(
                date: .now,
                usage: SharedDefaults.shared.cachedUsage(),
                errorMessage: error.localizedDescription
            )
        }
    }
}
