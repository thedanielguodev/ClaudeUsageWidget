import SwiftUI

@main
struct ClaudeUsageApp: App {
    @StateObject private var store = UsageStore()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(store)
                .frame(width: 380)
        } label: {
            MenuBarLabel()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarLabel: View {
    @EnvironmentObject private var store: UsageStore

    var body: some View {
        HStack(spacing: 4) {
            ClawMark.glyph()
            if let percent = store.fiveHourPercent {
                Text("\(percent)%")
                    .font(.system(.body, design: .rounded, weight: .semibold))
            }
        }
    }
}
