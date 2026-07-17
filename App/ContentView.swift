import AppKit
import ServiceManagement
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: UsageStore
    @State private var sessionKeyInput = ""
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            if store.isConnected {
                statusCard
            } else {
                setupCard
            }

            if let errorMessage = store.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.red)
            }

            Toggle("Launch at login", isOn: $launchAtLogin)
                .toggleStyle(.switch)
                .controlSize(.small)
                .font(.system(.footnote, design: .rounded))
                .onChange(of: launchAtLogin) { _, newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin.toggle()
                    }
                }
        }
        .padding(20)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Claude Usage", systemImage: "sparkle")
                .font(.system(.title3, design: .rounded, weight: .bold))
            Text("Lives in your menu bar. Click the percentage any time.")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var setupCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Connect your claude.ai account")
                .font(.system(.headline, design: .rounded))

            VStack(alignment: .leading, spacing: 6) {
                instructionRow(1, "Sign in at claude.ai in your browser.")
                instructionRow(2, "Open DevTools (⌥⌘I in Chrome/Edge, ⌥⌘C in Safari).")
                instructionRow(3, "Go to Application → Cookies → https://claude.ai (Storage → Cookies in Firefox).")
                instructionRow(4, "Click the sessionKey row and copy its Value (starts with sk-ant-sid01-…).")
                instructionRow(5, "Paste it below.")
            }
            .font(.system(.footnote, design: .rounded))
            .foregroundStyle(.secondary)

            Text("Never share this value — it grants full access to your claude.ai account.")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.orange)

            SecureField("sessionKey value", text: $sessionKeyInput)
                .textFieldStyle(.roundedBorder)

            Button {
                Task {
                    await store.connect(sessionKey: sessionKeyInput)
                    sessionKeyInput = ""
                }
            } label: {
                if store.isBusy {
                    ProgressView().controlSize(.small)
                } else {
                    Text("Save & Connect")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(sessionKeyInput.isEmpty || store.isBusy)
        }
        .padding(16)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 14))
    }

    private func instructionRow(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).").fontWeight(.semibold)
            Text(text)
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Connected", systemImage: "checkmark.seal.fill")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.green)
                Spacer()
                Button {
                    Task { await store.refresh() }
                } label: {
                    if store.isBusy {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(store.isBusy)
            }

            if let usage = store.usage {
                HStack(alignment: .top, spacing: 20) {
                    UsageRing(fraction: usage.fiveHour?.clampedFraction ?? 0, label: "5h session")
                        .frame(width: 96, height: 96)

                    VStack(alignment: .leading, spacing: 12) {
                        UsageBarRow(
                            title: "7-day (all models)",
                            fraction: usage.sevenDay?.clampedFraction ?? 0,
                            resetsAt: usage.sevenDay?.resetsAt
                        )
                    }
                }

                if let resets = usage.fiveHour?.resetsAt {
                    Text(relativeResetText(resets))
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            if let lastUpdated = store.lastUpdated {
                Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
            }

            Button("Forget session key", role: .destructive) {
                store.disconnect()
            }
            .buttonStyle(.borderless)
            .font(.system(.footnote, design: .rounded))

            Divider()

            Button("Quit Claude Usage") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .font(.system(.footnote, design: .rounded))
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ContentView()
        .environmentObject(UsageStore())
}
