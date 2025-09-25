# Hello iOS

A small SwiftUI demo app that showcases a friendly Home screen, a Settings page with Dark Mode, an About page, and a Server tab that displays your public IP, location (coordinates, speed, direction), and sunrise/sunset for your current position. The project includes VS Code tasks and scripts to build/run on the iOS Simulator.

> Built by Senthil with assistance from an AI pair programmer.


## Features

- SwiftUI Tab-based UI (Home, Settings, Server, About)
- Personalized greeting (persisted with @AppStorage)
- Live clock (Combine timer) and a Date Picker with formatted output
- Dark Mode toggle (persisted)
- Splash screen on launch
- Server tab:
  - Public IP fetch
  - Location (coordinates, speed, heading)
  - Sunrise/Sunset (computed via NOAA-based algorithm, displayed in local time)
  - Embedded browser link for IP details


## Project structure

```
hello-ios/
├─ hello/                      # SwiftUI source
│  ├─ AboutView.swift
│  ├─ ContentView.swift        # Hosts TabView (Home, Settings, Server, About)
│  ├─ HomeView.swift
│  ├─ ServerView.swift         # IP + Location + Sunrise/Sunset + WebView
│  ├─ SettingsView.swift
│  ├─ SplashView.swift
│  └─ Assets.xcassets/         # AppIcon & AppLogo
├─ hello.xcodeproj/            # Xcode project
├─ scripts/
│  ├─ ios-run.sh               # Build & run on Simulator
│  └─ ios-clean.sh             # Clean derived data, optional uninstall
└─ todo.txt                    # Feature ideas (Completed + Todo)
```


## Requirements

- macOS with Xcode 15+
- iOS Simulator (installed via Xcode)
- VS Code (optional, for the provided tasks)


## Build and run (Simulator)

You can use the VS Code Tasks (Terminal > Run Task…) that are already set up:

- iOS: Run (Simulator) — boots the iPhone 17 simulator, builds, installs, and launches the app
- iOS: Clean (fresh build) — removes derived data and uninstalls the app from the simulator

Or use the scripts directly:

```bash
# From repo root
bash scripts/ios-run.sh

# Clean build artifacts and optionally uninstall from the simulator
bash scripts/ios-clean.sh -c -U -Q
```

If you run into an Xcode CommandLineTools path error, select full Xcode:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```


## Run on a physical iPhone (no paid account)

You can deploy to your own iPhone using a free Apple ID with Xcode’s automatic signing:

1) One-time setup
- Open Xcode → Settings… → Accounts → Sign in with your Apple ID. A Personal Team will be created.
- On your iPhone, enable Developer Mode: Settings → Privacy & Security → Developer Mode (iOS 16+). Restart when prompted.

2) Configure the project
- Open `hello.xcodeproj` in Xcode.
- Select the "hello" target → Signing & Capabilities:
  - Check "Automatically manage signing"
  - Team: your Personal Team
  - Set a unique Bundle Identifier (e.g., com.yourname.hello)
- Ensure the Deployment Target <= your iPhone’s iOS version.

3) Run
- Connect and unlock your iPhone; trust the Mac if prompted.
- In Xcode’s toolbar pick your device as the Run destination, then press Run.
- First run: you may need to trust the developer on the phone (Settings → General → VPN & Device Management → Developer App → Trust) and/or enable Developer Mode.

Limitations with free provisioning: the app expires after 7 days; re-run from Xcode to refresh. Some capabilities are unavailable.


## Privacy

- Location is used to display coordinates, speed, direction, and to calculate sunrise/sunset within the app.
- The public IP is fetched from simple external endpoints (e.g., api.ipify.org). No analytics or tracking are included.


## Troubleshooting

- Build fails with CommandLineTools:
  - Run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- Simulator launch error:
  - Ensure the simulator is booted and the UDID matches in scripts/tasks. You can list devices with `xcrun simctl list devices`.
- Location shows "—":
  - Grant location permission when prompted on first launch. In the simulator, set a custom location via Features → Location.
- Sunrise/Sunset looks wrong:
  - The algorithm uses your coordinates and shows times in local timezone. If it still looks off, check the device time zone and location accuracy.


## Roadmap / Todo

From `todo.txt`:

Completed
- Personalized greeting (with @AppStorage)
- Live clock label (Timer.publish)
- Date picker + formatted output
- Persist dark mode choice
- Save username via @AppStorage
- Tab-based navigation
- About screen

Todo items
- Accent color picker
- Simple notes list
- Share current time (ShareLink)
- Haptic feedback (iOS)
- Accessibility pass
- Localize strings
- Preview variants

If you’d like any of these next items implemented, open an issue or PR.


## License

This repository is for personal/demo use. Consider adding an explicit license file (e.g., MIT) if you plan to share or accept contributions.
