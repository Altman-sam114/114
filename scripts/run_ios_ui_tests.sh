#!/usr/bin/env bash
# This entry point runs only on GitHub Actions, never on the developer's simulator.
set -euo pipefail
test "${GITHUB_ACTIONS:-}" = true
test -n "${UI_DIR:-}"
test "${UI_PLATFORM:-}" = ios-390 || test "${UI_PLATFORM:-}" = ios-375

xcrun simctl list -j runtimes > "$UI_DIR/simulator-runtimes.json"
xcrun simctl list -j devicetypes > "$UI_DIR/simulator-types.json"
python3 - <<'PY'
import json
import os
from pathlib import Path
import subprocess

root = Path(os.environ["UI_DIR"])
platform = os.environ["UI_PLATFORM"]
types = json.loads((root / "simulator-types.json").read_bytes())["devicetypes"]
identifier = "com.apple.CoreSimulator.SimDeviceType." + ("iPhone-13" if platform == "ios-390" else "iPhone-SE-3rd-generation")
assert any(item["identifier"] == identifier for item in types), "Requested iPhone device type is unavailable"
runtimes = [item for item in json.loads((root / "simulator-runtimes.json").read_bytes())["runtimes"]
            if item.get("isAvailable") is True and ".SimRuntime.iOS-" in item["identifier"]]
assert runtimes, "No available iOS runtime"
runtime = max(runtimes, key=lambda item: tuple(int(part) for part in item["version"].split(".")))
device = subprocess.check_output(["xcrun", "simctl", "create", "ChronoFocus-" + platform,
                                  identifier, runtime["identifier"]], text=True).strip()
(root / "simulator-udid.txt").write_text(device + "\n")
metadata = {"udid": device, "deviceType": identifier, "runtime": runtime["identifier"],
            "pointWidth": 390 if platform == "ios-390" else 375, "scale": 3 if platform == "ios-390" else 2}
with (root / "device.json").open("x") as output:
    json.dump(metadata, output, indent=2)
PY

device_udid="$(cat "$UI_DIR/simulator-udid.txt")"
xcrun simctl boot "$device_udid"
xcrun simctl bootstatus "$device_udid" -b
printf '%s\n' 'xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocus -configuration Debug -destination "platform=iOS Simulator,id=<device.json udid>" -parallel-testing-enabled NO -resultBundlePath "$UI_DIR/ios.xcresult" CODE_SIGNING_ALLOWED=NO test' > "$UI_DIR/test-command.txt"

set +e
xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocus -configuration Debug \
  -destination "platform=iOS Simulator,id=$device_udid" \
  -derivedDataPath "$RUNNER_TEMP/ChronoFocusUITestDerivedData" \
  -resultBundlePath "$UI_DIR/ios.xcresult" \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO test 2>&1 | tee "$UI_DIR/ios-ui-tests.log"
test_status=${PIPESTATUS[0]}
set -e

if [[ -d "$UI_DIR/ios.xcresult" ]]; then
  xcrun xcresulttool get test-results summary --path "$UI_DIR/ios.xcresult" > "$UI_DIR/ios-summary.json"
  xcrun xcresulttool export attachments --path "$UI_DIR/ios.xcresult" --output-path "$UI_DIR/attachments"
fi
test "$test_status" -eq 0
python3 scripts/verify_ios_ui_evidence.py
