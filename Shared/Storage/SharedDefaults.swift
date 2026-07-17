import Foundation

/// App Group-backed cache so the widget has something to show instantly
/// (and something to fall back to if a network refresh fails).
final class SharedDefaults {
    static let shared = SharedDefaults()

    private let defaults = UserDefaults(suiteName: "group.com.danielg.claudeusage")

    private enum Key {
        static let organizationID = "organizationID"
        static let cachedUsage = "cachedUsage"
        static let lastUpdated = "lastUpdated"
        static let sessionKey = "sessionKey"
    }

    var organizationID: String? {
        get { defaults?.string(forKey: Key.organizationID) }
        set { defaults?.set(newValue, forKey: Key.organizationID) }
    }

    /// The claude.ai `sessionKey` cookie value. Stored in the App Group's
    /// shared container so both the app and the widget extension can read
    /// it without needing a separate Keychain-sharing entitlement.
    var sessionKey: String? {
        get { defaults?.string(forKey: Key.sessionKey) }
        set { defaults?.set(newValue, forKey: Key.sessionKey) }
    }

    var lastUpdated: Date? {
        get { defaults?.object(forKey: Key.lastUpdated) as? Date }
        set { defaults?.set(newValue, forKey: Key.lastUpdated) }
    }

    func cache(_ usage: ClaudeUsageResponse) {
        if let data = try? JSONEncoder().encode(usage) {
            defaults?.set(data, forKey: Key.cachedUsage)
        }
        lastUpdated = .now
    }

    func cachedUsage() -> ClaudeUsageResponse? {
        guard let data = defaults?.data(forKey: Key.cachedUsage) else { return nil }
        return try? JSONDecoder().decode(ClaudeUsageResponse.self, from: data)
    }
}
