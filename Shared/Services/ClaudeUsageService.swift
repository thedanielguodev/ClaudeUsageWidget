import Foundation

/// Talks to claude.ai's internal (undocumented) web API using the same
/// `sessionKey` cookie your browser uses when you're signed into claude.ai.
///
/// This mirrors the approach used by several open-source Claude usage
/// trackers (e.g. github.com/hamed-elfayome/Claude-Usage-Tracker) since
/// Anthropic does not publish a usage-limits API for claude.ai subscriptions.
/// Anthropic can change or remove this endpoint at any time without notice.
struct ClaudeUsageService {
    static let shared = ClaudeUsageService()

    private let session = URLSession(configuration: .ephemeral)
    private let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    private func request(url: URL, sessionKey: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("sessionKey=\(sessionKey)", forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("https://claude.ai", forHTTPHeaderField: "Referer")
        request.setValue("https://claude.ai", forHTTPHeaderField: "Origin")
        return request
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 || http.statusCode == 403 {
                throw ClaudeUsageError.invalidSessionKey
            }
            throw ClaudeUsageError.http(http.statusCode)
        }
    }

    /// GET /api/organizations -> take the first organization's uuid.
    func fetchPrimaryOrganizationID(sessionKey: String) async throws -> String {
        let url = URL(string: "https://claude.ai/api/organizations")!
        let (data, response) = try await session.data(for: request(url: url, sessionKey: sessionKey))
        try validate(response)

        guard
            let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
            let uuid = array.first?["uuid"] as? String
        else {
            throw ClaudeUsageError.noOrganization
        }
        return uuid
    }

    /// GET /api/organizations/{org_id}/usage
    func fetchUsage(sessionKey: String, organizationID: String) async throws -> ClaudeUsageResponse {
        let url = URL(string: "https://claude.ai/api/organizations/\(organizationID)/usage")!
        let (data, response) = try await session.data(for: request(url: url, sessionKey: sessionKey))
        try validate(response)

        do {
            return try JSONDecoder().decode(ClaudeUsageResponse.self, from: data)
        } catch {
            throw ClaudeUsageError.decoding
        }
    }

    /// Resolves the organization ID (caching it in the shared App Group store)
    /// and fetches the latest usage snapshot in one call.
    func fetchCurrentUsage(sessionKey: String) async throws -> ClaudeUsageResponse {
        let orgID: String
        if let cached = SharedDefaults.shared.organizationID {
            orgID = cached
        } else {
            orgID = try await fetchPrimaryOrganizationID(sessionKey: sessionKey)
            SharedDefaults.shared.organizationID = orgID
        }

        do {
            return try await fetchUsage(sessionKey: sessionKey, organizationID: orgID)
        } catch ClaudeUsageError.http(404) {
            // Cached org id may be stale; re-resolve once.
            let freshOrgID = try await fetchPrimaryOrganizationID(sessionKey: sessionKey)
            SharedDefaults.shared.organizationID = freshOrgID
            return try await fetchUsage(sessionKey: sessionKey, organizationID: freshOrgID)
        }
    }
}
