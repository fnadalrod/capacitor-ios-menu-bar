#!/usr/bin/env bash
# Runs the Swift tests on a simulator. Simulator names drift between Xcode releases, so the
# destination is discovered: an iPad when there is one (the device the plugin is for), any iOS
# simulator otherwise. The tests need no host app.
set -euo pipefail

cd "$(dirname "$0")/.."

udid=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = [device for runtime, entries in json.load(sys.stdin)["devices"].items()
           if "iOS" in runtime for device in entries]
ipads = [device for device in devices if device["name"].startswith("iPad")]
chosen = (ipads or devices or [None])[0]
print(chosen["udid"] if chosen else "")
')

if [ -z "$udid" ]; then
  echo "No iOS simulator available. Install one from Xcode > Settings > Components." >&2
  exit 1
fi

xcodebuild test -scheme CapacitorIosMenuBar -destination "id=$udid" "$@"
