"""Actions-only verification of actual xcresulttool results and native attachments."""
import hashlib
import json
import os
from pathlib import Path
import struct

root = Path(os.environ["UI_DIR"])
summary = json.loads((root / "ios-summary.json").read_bytes())
assert summary["totalTestCount"] == 5 and summary["passedTests"] == 5, "Expected five executed, passed UI tests"
assert summary["failedTests"] == 0 and summary["skippedTests"] == 0, "Failed or skipped UI tests cannot pass"
device = json.loads((root / "device.json").read_bytes())
screenshots = []
for image in sorted((root / "attachments").rglob("*.png")):
    with image.open("rb") as source:
        header = source.read(24)
    assert header[:8] == b"\x89PNG\r\n\x1a\n", "Invalid screenshot PNG"
    width, height = struct.unpack(">II", header[16:24])
    assert width == device["pointWidth"] * device["scale"] and height > width, "Screenshot does not match the declared portrait device"
    screenshots.append({"path": str(image.relative_to(root)), "width": width, "height": height,
                        "byteCount": image.stat().st_size, "sha256": hashlib.sha256(image.read_bytes()).hexdigest()})
assert len(screenshots) >= 15, "Missing native screenshot attachments"
with (root / "ios-evidence.json").open("x") as output:
    json.dump({"device": device, "summary": summary, "screenshots": screenshots}, output, indent=2)
print(f"Native iOS UI evidence verified: 5 passed, 0 failed, 0 skipped; {len(screenshots)} screenshots")
