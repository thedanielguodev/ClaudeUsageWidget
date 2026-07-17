# Claude Usage Widget

A minimal macOS desktop/Notification Center widget that shows your claude.ai
**subscription** usage — the rolling 5-hour session window and the 7-day
(all models / Opus) windows — right on your desktop.

Built with SwiftUI + WidgetKit, targeting macOS 14 (Sonoma) and later.

## How it works

Anthropic doesn't publish a public API for claude.ai *subscription* usage
limits (that's different from metered API billing). This app instead calls
the same internal endpoint claude.ai's own web UI uses:

```
GET https://claude.ai/api/organizations/{org_id}/usage
```

authenticated with the `sessionKey` cookie from your logged-in browser
session — the same approach used by several open-source trackers (e.g.
[Claude-Usage-Tracker](https://github.com/hamed-elfayome/Claude-Usage-Tracker)).
This is **unofficial and undocumented**: Anthropic can change or remove it at
any time without notice.

Your session key is a bearer credential for your account — treat it like a
password. It's stored locally in `UserDefaults` inside the app's shared App
Group container (so both the menu bar app and the widget extension can read
it) and is never sent anywhere except `claude.ai`. It never leaves your Mac.

## Requirements

- **Xcode** (the full app, not just Command Line Tools) — install from the
  Mac App Store. The CLT alone can't build app extensions like WidgetKit
  widgets.
- macOS 14 Sonoma or later.
- A free [Apple Developer account](https://developer.apple.com/account) (for
  code signing — no paid membership needed for local builds).

## Building & running

1. Clone this repo and open `ClaudeUsageWidget.xcodeproj` in Xcode.
2. Select your own team under both targets' *Signing & Capabilities* tab
   (**ClaudeUsage** and **ClaudeUsageWidgetExtension**) — Automatic signing
   is already configured, Xcode just needs a team picked once. If you
   regenerate the project from `project.yml` (see below), update
   `DEVELOPMENT_TEAM` there to your own Team ID first.
3. Select the **ClaudeUsage** scheme and Run (⌘R). The setup window opens.
4. Grab your session key:
   - Sign in at [claude.ai](https://claude.ai) in Safari or Chrome.
   - Open DevTools → *Application* (Chrome) or *Storage* (Safari) → Cookies
     → `https://claude.ai`.
   - Copy the value of the `sessionKey` cookie (starts with `sk-ant-sid01-`).
5. Paste it into the app and click **Save & Connect**. You should see live
   usage rings/bars.
6. Right-click the desktop (or open Notification Center) → **Edit Widgets**
   → search "Claude Usage" → drag it onto your desktop, choose small or
   medium.

If the widget shows "Open the app to connect", just relaunch the app once —
launching the app isn't required to stay running, WidgetKit reads the saved
key from the shared App Group storage independently.

## Regenerating the Xcode project

The `.xcodeproj` is generated from [`project.yml`](project.yml) via
[XcodeGen](https://github.com/yonaskolb/XcodeGen). Install it with
`brew install xcodegen`, then, after editing `project.yml` or adding new
source files/groups, regenerate with:

```sh
xcodegen generate
```

## Notes / limitations

- Widget refresh timing is controlled by the OS (WidgetKit budgets
  background refreshes); it requests a refresh every ~15 minutes but the
  system may space that out further. Opening the main app and hitting the
  refresh button always triggers an immediate update.
- If `sessionKey` expires (you're logged out of claude.ai), just repeat the
  paste-and-save step.
- Only tested against a single (first) organization on the account.
