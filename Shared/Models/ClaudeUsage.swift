import Foundation

/// One rate-limit window (e.g. the rolling 5-hour session, or a 7-day window).
struct UsageWindow: Codable, Equatable {
    let utilization: Double
    let resetsAtRaw: String?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAtRaw = "resets_at"
    }

    var resetsAt: Date? {
        resetsAtRaw.flatMap(ISO8601FlexibleParser.parse)
    }

    var clampedFraction: Double {
        min(max(utilization / 100, 0), 1)
    }
}

/// Mirrors the response of GET https://claude.ai/api/organizations/{org_id}/usage
struct ClaudeUsageResponse: Codable, Equatable {
    let fiveHour: UsageWindow?
    let sevenDay: UsageWindow?
    let sevenDayOpus: UsageWindow?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDayOpus = "seven_day_opus"
    }

    static let placeholder = ClaudeUsageResponse(
        fiveHour: UsageWindow(utilization: 42, resetsAtRaw: nil),
        sevenDay: UsageWindow(utilization: 61, resetsAtRaw: nil),
        sevenDayOpus: UsageWindow(utilization: 18, resetsAtRaw: nil)
    )
}

enum ISO8601FlexibleParser {
    private static let withFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let standard: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func parse(_ string: String) -> Date? {
        withFractional.date(from: string) ?? standard.date(from: string)
    }
}

enum ClaudeUsageError: LocalizedError {
    case missingSessionKey
    case invalidSessionKey
    case noOrganization
    case http(Int)
    case decoding

    var errorDescription: String? {
        switch self {
        case .missingSessionKey: return "No session key saved yet"
        case .invalidSessionKey: return "Session key was rejected"
        case .noOrganization: return "No organization found for this account"
        case .http(let code): return "Server returned status \(code)"
        case .decoding: return "Couldn't parse the usage response"
        }
    }
}
