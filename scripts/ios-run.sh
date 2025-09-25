#!/usr/bin/env bash
set -Eeuo pipefail

# iOS Simulator build+deploy helper for SwiftUI app
# - Boots a simulator (by UDID), builds with xcodebuild, installs and launches the app
# - Defaults align with this repo's project (project "hello.xcodeproj", scheme "hello")
#
# Usage:
#   bash scripts/ios-run.sh [-u UDID] [-p project.xcodeproj] [-s scheme] [-c Debug|Release] [-o derivedDataPath] [-b bundleId]
#   SIM_UDID=<udid> bash scripts/ios-run.sh
#
# Tips:
#   - List simulators: xcrun simctl list devices
#   - Get UDID of a booted device: xcrun simctl list devices booted
#   - If you see CommandLineTools errors, run:
#       sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

PROJECT="hello.xcodeproj"
SCHEME="hello"
CONFIGURATION="Debug"
DERIVED_DATA=".vscode/build"
UDID="${SIM_UDID:-C796479F-1DC4-4EF5-B236-3EFAF73F5D98}"
BUNDLE_ID=""

print_usage() {
  cat <<USAGE
Usage: $0 [-u UDID] [-p project.xcodeproj] [-s scheme] [-c Debug|Release] [-o derivedDataPath] [-b bundleId]

Options:
  -u  Simulator UDID to target (default: env SIM_UDID or ${UDID})
  -p  Xcode project file (default: ${PROJECT})
  -s  Xcode scheme (default: ${SCHEME})
  -c  Build configuration (default: ${CONFIGURATION})
  -o  Derived data path (default: ${DERIVED_DATA})
  -b  Bundle identifier override (default: auto-detect from built app, fallback muonium.hello)
  -h  Show this help
USAGE
}

while getopts ":u:p:s:c:o:b:h" opt; do
  case "$opt" in
    u) UDID="$OPTARG" ;;
    p) PROJECT="$OPTARG" ;;
    s) SCHEME="$OPTARG" ;;
    c) CONFIGURATION="$OPTARG" ;;
    o) DERIVED_DATA="$OPTARG" ;;
    b) BUNDLE_ID="$OPTARG" ;;
    h) print_usage; exit 0 ;;
    :) echo "Missing option value for -$OPTARG" >&2; print_usage; exit 2 ;;
    \?) echo "Unknown option -$OPTARG" >&2; print_usage; exit 2 ;;
  esac
done

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Required command not found: $1" >&2; exit 1; }
}

require_cmd xcodebuild
require_cmd xcrun
require_cmd plutil || true # optional

# Ensure full Xcode selected (not CommandLineTools)
XCPATH=$(xcode-select -p || echo "")
if [[ "$XCPATH" == *"CommandLineTools"* ]]; then
  echo "Detected CommandLineTools path: $XCPATH" >&2
  echo "Please select full Xcode before continuing:" >&2
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
  exit 1
fi

if [[ -z "$UDID" ]]; then
  echo "No simulator UDID provided. Use -u or set SIM_UDID. List devices with: xcrun simctl list devices" >&2
  exit 2
fi

# Boot simulator and wait until ready
echo "[1/4] Booting simulator $UDID ..."
open -a Simulator >/dev/null 2>&1 || true
xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$UDID" -b

# Build for that simulator
echo "[2/4] Building: project=$PROJECT scheme=$SCHEME config=$CONFIGURATION ..."
set -o pipefail
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "platform=iOS Simulator,id=$UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  | sed -e 's/\r/\n/g' | sed -u -e 's/\\u001b\[[0-9;]*m//g' || {
  echo "If this failed with CommandLineTools error, run:" >&2
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
  exit 1
}

# Locate the built .app
APP="$DERIVED_DATA/Build/Products/$CONFIGURATION-iphonesimulator/$SCHEME.app"
if [[ ! -d "$APP" ]]; then
  # fallback: pick the first .app in the products dir
  APP=$(find "$DERIVED_DATA/Build/Products/$CONFIGURATION-iphonesimulator" -maxdepth 1 -type d -name "*.app" | head -n1 || true)
fi

if [[ -z "$APP" || ! -d "$APP" ]]; then
  echo "Could not find built .app in $DERIVED_DATA/Build/Products/$CONFIGURATION-iphonesimulator" >&2
  exit 1
fi

echo "[3/4] Installing app: $APP"
# Determine bundle identifier
if [[ -z "$BUNDLE_ID" ]]; then
  INFO_PLIST="$APP/Info.plist"
  if [[ -f "$INFO_PLIST" ]]; then
    # Try plutil (more robust for binary plist)
    if BUNDLE_ID=$(plutil -extract CFBundleIdentifier xml1 -o - "$INFO_PLIST" 2>/dev/null | sed -n 's@.*<string>\(.*\)</string>.*@\1@p'); then
      :
    else
      # Fallback to PlistBuddy or defaults
      BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$INFO_PLIST" 2>/dev/null || defaults read "${INFO_PLIST%.plist}" CFBundleIdentifier 2>/dev/null || echo "")
    fi
  fi
  if [[ -z "$BUNDLE_ID" ]]; then
    BUNDLE_ID="muonium.hello"
    echo "Warning: could not auto-detect CFBundleIdentifier; defaulting to $BUNDLE_ID" >&2
  fi
fi

echo "Using bundle id: $BUNDLE_ID"

# Reinstall and launch
xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$UDID" "$APP"
echo "[4/4] Launching app on simulator..."
LAUNCH_OUT=$(xcrun simctl launch "$UDID" "$BUNDLE_ID" 2>&1 || true)
echo "$LAUNCH_OUT"

if echo "$LAUNCH_OUT" | grep -q "\bAn error was encountered\b"; then
  echo "simctl launch reported an error. Output shown above." >&2
  exit 1
fi

echo "Done. App should now be running on the simulator ($UDID)."