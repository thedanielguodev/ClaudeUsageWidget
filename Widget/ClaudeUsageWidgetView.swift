import SwiftUI
import WidgetKit

struct ClaudeUsageWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ClaudeUsageEntry

    var body: some View {
        Group {
            if let usage = entry.usage {
                switch family {
                case .systemSmall:
                    smallLayout(usage)
                default:
                    mediumLayout(usage)
                }
            } else {
                emptyState
            }
        }
        .containerBackground(.background, for: .widget)
    }

    private func smallLayout(_ usage: ClaudeUsageResponse) -> some View {
        VStack(spacing: 8) {
            UsageRing(fraction: usage.fiveHour?.clampedFraction ?? 0, label: "5H SESSION")
                .frame(width: 76, height: 76)

            if let resets = usage.fiveHour?.resetsAt {
                Text(relativeResetText(resets))
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(4)
    }

    private func mediumLayout(_ usage: ClaudeUsageResponse) -> some View {
        HStack(spacing: 18) {
            UsageRing(fraction: usage.fiveHour?.clampedFraction ?? 0, label: "5H SESSION")
                .frame(width: 84, height: 84)

            VStack(alignment: .leading, spacing: 10) {
                UsageBarRow(
                    title: "7-day (all models)",
                    fraction: usage.sevenDay?.clampedFraction ?? 0,
                    resetsAt: usage.sevenDay?.resetsAt
                )

                if let resets = usage.fiveHour?.resetsAt {
                    Text("5h " + relativeResetText(resets))
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(4)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkle")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(entry.errorMessage ?? "Open the app to connect")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding()
    }
}

#Preview(as: .systemSmall) {
    ClaudeUsageWidget()
} timeline: {
    ClaudeUsageEntry(date: .now, usage: .placeholder, errorMessage: nil)
}

#Preview(as: .systemMedium) {
    ClaudeUsageWidget()
} timeline: {
    ClaudeUsageEntry(date: .now, usage: .placeholder, errorMessage: nil)
}
