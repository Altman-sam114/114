#!/usr/bin/env bash
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
                                  identifier, runtime["identifier"]], text=True, timeout=60).strip()
(root / "simulator-udid.txt").write_text(device + "\n")
metadata = {"udid": device, "deviceType": identifier, "runtime": runtime["identifier"],
            "pointWidth": 390 if platform == "ios-390" else 375, "pointHeight": 844 if platform == "ios-390" else 667,
            "scale": 3 if platform == "ios-390" else 2}
with (root / "device.json").open("x") as output:
    json.dump(metadata, output, indent=2)
with (root / "simulator-boot.log").open("x") as log:
    subprocess.run(["xcrun", "simctl", "boot", device], stdout=log, stderr=subprocess.STDOUT, check=True, timeout=60)
print(f"Simulator boot requested: {identifier}, runtime={runtime['identifier']}, udid={device}")
PY
