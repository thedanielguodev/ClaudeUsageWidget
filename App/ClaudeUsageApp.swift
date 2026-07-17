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
        if let percent = store.fiveHourPercent {
            HStack(spacing: 3) {
                Image(systemName: "sparkle")
                    .font(.system(size: 11, weight: .semibold))
                Text("\(percent)%")
                    .font(.system(.body, design: .rounded, weight: .semibold))
            }
        } else {
            Image(systemName: "sparkle")
        }
    }
}
