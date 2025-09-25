#!/usr/bin/env bash
set -Eeuo pipefail

# Cleanup script to ensure next run is a fresh full build
# Defaults aligned with this repo's setup (derived data under .vscode/build)
#
# Usage:
#   bash scripts/ios-clean.sh [-o derivedDataPath] [-p project.xcodeproj] [-s scheme] [-c] [-U] [-b bundleId] [-u UDID] [-Q]
#
# Options:
#   -o  Derived data path to remove (default: .vscode/build)
#   -p  Xcode project (default: hello.xcodeproj)
#   -s  Xcode scheme (default: hello)
#   -c  Also run xcodebuild clean (in addition to deleting derived data)
#   -U  Uninstall app from simulator (requires bundle id; auto-detect if possible)
#   -b  Bundle identifier (override; default tries Info.plist, fallback muonium.hello)
#   -u  Simulator UDID for uninstall (default: env SIM_UDID or C796479F-1DC4-4EF5-B236-3EFAF73F5D98)
#   -Q  Quit Simulator app after cleanup
#   -h  Help

DERIVED_DATA=".vscode/build"
PROJECT="hello.xcodeproj"
SCHEME="hello"
DO_XCLEAN=false
DO_UNINSTALL=false
BUNDLE_ID=""
UDID="${SIM_UDID:-C796479F-1DC4-4EF5-B236-3EFAF73F5D98}"
QUIT_SIM=false

print_usage() {
  sed -n '1,100p' "$0" | sed -n '1,/^$/p' >/dev/null 2>&1 || true
  cat <<USAGE
Usage: $0 [-o derivedDataPath] [-p project.xcodeproj] [-s scheme] [-c] [-U] [-b bundleId] [-u UDID] [-Q]

Removes local build artifacts so the next build is fresh.

Options:
  -o  Derived data path (default: ${DERIVED_DATA})
  -p  Xcode project (default: ${PROJECT})
  -s  Scheme (default: ${SCHEME})
  -c  Run \"xcodebuild clean\" as well
  -U  Uninstall previously installed app from simulator
  -b  Bundle identifier (if -U; default auto-detect, fallback muonium.hello)
  -u  Simulator UDID (if -U; default: ${UDID})
  -Q  Quit the Simulator app
  -h  Show this help
USAGE
}

while getopts ":o:p:s:b:u:cUhQ" opt; do
  case "$opt" in
    o) DERIVED_DATA="$OPTARG" ;;
    p) PROJECT="$OPTARG" ;;
    s) SCHEME="$OPTARG" ;;
    b) BUNDLE_ID="$OPTARG" ;;
    u) UDID="$OPTARG" ;;
    c) DO_XCLEAN=true ;;
    U) DO_UNINSTALL=true ;;
    Q) QUIT_SIM=true ;;
    h) print_usage; exit 0 ;;
    :) echo "Missing value for -$OPTARG" >&2; print_usage; exit 2 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; print_usage; exit 2 ;;
  esac
done

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Required command not found: $1" >&2; exit 1; }
}

require_cmd rm
require_cmd mkdir
require_cmd xcodebuild
require_cmd xcrun
require_cmd plutil || true

# 1) Remove derived data path fully
if [[ -d "$DERIVED_DATA" ]]; then
  echo "Deleting derived data at: $DERIVED_DATA"
  rm -rf "$DERIVED_DATA"
else
  echo "No derived data directory to remove at: $DERIVED_DATA"
fi

# 2) Optionally run xcodebuild clean
if [[ "$DO_XCLEAN" == true ]]; then
  echo "Running xcodebuild clean for project=$PROJECT scheme=$SCHEME ..."
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug clean || true
fi

# 3) Optionally uninstall app from simulator
if [[ "$DO_UNINSTALL" == true ]]; then
  if [[ -z "$UDID" ]]; then
    echo "No simulator UDID provided for uninstall. Provide with -u or SIM_UDID env." >&2
  else
    if [[ -z "$BUNDLE_ID" ]]; then
      # Try to detect bundle id from any existing app product (if present)
      APP_CAND=$(find "$DERIVED_DATA" -type d -name "*.app" -maxdepth 4 2>/dev/null | head -n1 || true)
      if [[ -n "$APP_CAND" && -f "$APP_CAND/Info.plist" ]]; then
        BUNDLE_ID=$(plutil -extract CFBundleIdentifier xml1 -o - "$APP_CAND/Info.plist" 2>/dev/null | sed -n 's@.*<string>\(.*\)</string>.*@\1@p') || true
      fi
      if [[ -z "$BUNDLE_ID" ]]; then
        BUNDLE_ID="muonium.hello"
      fi
    fi
    echo "Uninstalling $BUNDLE_ID from simulator $UDID ..."
    xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  fi
fi

# 4) Optionally quit Simulator
if [[ "$QUIT_SIM" == true ]]; then
  echo "Quitting Simulator app..."
  osascript -e 'tell application "Simulator" to quit' >/dev/null 2>&1 || pkill -x Simulator >/dev/null 2>&1 || true
fi

echo "Cleanup complete."