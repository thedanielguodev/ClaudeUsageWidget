import SwiftUI
import WidgetKit

/// A minimal circular progress ring with a big percentage label in the center.
struct UsageRing: View {
    let fraction: Double
    let label: String
    var lineWidth: CGFloat = 8

    private var tint: Color {
        switch fraction {
        case ..<0.6: return .green
        case ..<0.85: return .yellow
        default: return .red
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .widgetAccentable()

            VStack(spacing: 2) {
                Text("\(Int((fraction * 100).rounded()))")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())
                Text(label)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// A slim labeled progress bar for a secondary usage window.
struct UsageBarRow: View {
    let title: String
    let fraction: Double
    var resetsAt: Date? = nil

    private var tint: Color {
        switch fraction {
        case ..<0.6: return .green
        case ..<0.85: return .yellow
        default: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int((fraction * 100).rounded()))%")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule()
                        .fill(tint)
                        .widgetAccentable()
                        .frame(width: max(3, proxy.size.width * fraction))
                }
            }
            .frame(height: 5)

            if let resetsAt {
                Text(relativeResetText(resetsAt))
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

func relativeResetText(_ date: Date?) -> String {
    guard let date else { return "" }
    if date <= .now { return "resets soon" }
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return "resets " + formatter.localizedString(for: date, relativeTo: .now)
}
