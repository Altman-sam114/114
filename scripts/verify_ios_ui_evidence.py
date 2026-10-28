"""Actions-only verification of xcresult summaries and named native attachments."""
import hashlib
import json
import math
import os
from pathlib import Path
import re
import stat
import struct
import sys


SCENES = {
    "testFreeFocusLifecycle": ("timer-idle", "timer-running", "timer-paused", "timer-resumed", "timer-stopped"),
    "testReminderDisclosure": ("reminders-expanded", "reminders-collapsed"),
    "testThemeSwitchAcrossTabs": ("timer-light", "schedule-light", "settings-notifications-light", "settings-privacy-light", "timer-dark-restored", "schedule-actions-dark"),
    "testScheduleCategoryPrefillAndSave": ("schedule-filtered", "task-editor-prefilled", "schedule-saved"),
    "testAccessibilityTextWithLongTask": ("large-text-idle", "large-text-running", "large-text-notifications"),
    "testScheduleAccessibilityAndActions": ("schedule-large-calendar", "schedule-long-title", "schedule-long-category", "schedule-long-actions", "schedule-long-editor", "schedule-long-handoff"),
    "testTaskSearchAndCompletionFilters": ("tasks-pending", "tasks-search", "tasks-completed", "tasks-restored", "tasks-search-empty", "tasks-created-from-filter"),
    "testTaskDeletionRequiresConfirmation": ("deletion-confirmation", "deletion-cancelled", "deletion-protected", "deletion-completed"),
}
DEVICES = {
    "com.apple.CoreSimulator.SimDeviceType.iPhone-13": (390, 844, 3),
    "com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation": (375, 667, 2),
}


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def regular_file(path, limit):
    info = path.lstat()
    require(stat.S_ISREG(info.st_mode) and 0 < info.st_size <= limit, f"Invalid evidence file: {path.name}")
    return path.read_bytes()


def read_json(path):
    return json.loads(regular_file(path, 1048576))


def test_cases(nodes):
    require(isinstance(nodes, list), "Invalid native test tree")
    cases = []
    for node in nodes:
        require(isinstance(node, dict), "Invalid native test node")
        if node.get("nodeType") == "Test Case":
            cases.append(node)
        cases.extend(test_cases(node.get("children", [])))
    return cases


def verify_evidence(root):
    require((root / "attachments").is_dir() and not (root / "attachments").is_symlink(), "Invalid attachment directory")
    summary = read_json(root / "ios-summary.json")
    counts = {"totalTestCount": len(SCENES), "passedTests": len(SCENES), "failedTests": 0, "skippedTests": 0, "expectedFailures": 0}
    for key, expected in counts.items():
        require(type(summary.get(key)) is int and summary[key] == expected, f"Unexpected native test count: {key}")
    require(summary.get("result") == "Passed" and summary.get("testFailures") == [], "Native tests did not pass cleanly")
    device = read_json(root / "device.json")
    expected_dimensions = DEVICES.get(device.get("deviceType"))
    require(expected_dimensions is not None, "Unexpected native device type")
    require(tuple(device.get(key) for key in ("pointWidth", "pointHeight", "scale")) == expected_dimensions, "Declared device dimensions differ")
    configurations = summary.get("devicesAndConfigurations")
    require(isinstance(configurations, list) and len(configurations) == 1, "Expected one native test device")
    configuration = configurations[0]
    require(configuration.get("device", {}).get("deviceId") == device.get("udid") and bool(device.get("udid")), "Test results belong to a different simulator")
    require(configuration["device"].get("platform") == "iOS Simulator", "Expected simulator results")
    for key in ("passedTests", "failedTests", "skippedTests", "expectedFailures"):
        require(type(configuration.get(key)) is int and configuration[key] == counts[key], "Per-device test counts differ")

    tree = read_json(root / "ios-tests.json")
    tree_devices = tree.get("devices")
    require(isinstance(tree_devices, list) and len(tree_devices) == 1
            and tree_devices[0].get("deviceId") == device["udid"]
            and tree_devices[0].get("platform") == "iOS Simulator", "Native test tree belongs to a different simulator")
    expected_tests = {f"ChronoFocusUITests/{name}()": scenes for name, scenes in SCENES.items()}
    executed = []
    seen_cases = set()
    for case in test_cases(tree.get("testNodes")):
        identifier = case.get("nodeIdentifier")
        require(identifier in expected_tests and identifier not in seen_cases, "Unexpected or duplicate executed test identity")
        require(case.get("result") == "Passed", "Executed native test did not pass")
        seconds = case.get("durationInSeconds")
        require(type(seconds) in (int, float) and math.isfinite(seconds) and seconds >= 0, "Invalid native test duration")
        seen_cases.add(identifier)
        executed.append({"testIdentifier": identifier, "result": case["result"], "durationInSeconds": seconds})
    require(seen_cases == set(expected_tests), "Missing executed native test identity")

    manifest = read_json(root / "attachments/manifest.json")
    require(isinstance(manifest, list), "Missing native attachment manifest")
    seen_tests = set()
    seen_files = set()
    screenshots = []
    for group in manifest:
        identifier = group.get("testIdentifier")
        require(identifier in expected_tests and identifier not in seen_tests, "Unexpected or duplicate native test identity")
        seen_tests.add(identifier)
        seen_scenes = set()
        for item in group["attachments"]:
            filename = item.get("exportedFileName", "")
            require(isinstance(filename, str) and filename not in ("", ".", "..") and Path(filename).name == filename and "\\" not in filename, "Unsafe attachment path")
            if not filename.endswith(".png"):
                continue
            require(filename not in seen_files, "Duplicate screenshot file")
            seen_files.add(filename)
            name = item.get("suggestedHumanReadableName", "")
            scene = next((scene for scene in expected_tests[identifier]
                          if re.fullmatch(re.escape(scene) + r"_\d+_[0-9A-Fa-f-]{36}\.png", name)), None)
            require(scene is not None and scene not in seen_scenes, "Unexpected or duplicate screenshot scene for this test")
            seen_scenes.add(scene)
            require(item.get("deviceId") == device["udid"], "Screenshot belongs to a different simulator")
            data = regular_file(root / "attachments" / filename, 20971520)
            require(len(data) >= 24 and data[:8] == b"\x89PNG\r\n\x1a\n" and data[12:16] == b"IHDR", "Invalid screenshot PNG")
            width, height = struct.unpack(">II", data[16:24])
            point_width, point_height, scale = expected_dimensions
            require((width, height) == (point_width * scale, point_height * scale), "Screenshot does not match the declared portrait device")
            screenshots.append({"testIdentifier": identifier, "scene": scene, "path": "attachments/" + filename,
                                "width": width, "height": height, "byteCount": len(data), "sha256": hashlib.sha256(data).hexdigest()})
        require(seen_scenes == set(expected_tests[identifier]), f"Missing required screenshot scene: {identifier}")
    require(seen_tests == set(expected_tests), "Missing required native test identity")
    require({path.relative_to(root / "attachments").as_posix() for path in (root / "attachments").rglob("*.png")} == seen_files, "Unbound screenshot attachments")
    return {"device": device, "summary": summary, "executedTests": executed, "screenshots": screenshots}


def write_test_summary(root, step_summary=None):
    lines = ["## Native iOS UI diagnostics", "", "This diagnostic summary does not replace evidence verification.", ""]
    if (root / "ios-summary.json").is_file():
        summary = read_json(root / "ios-summary.json")
        lines += [f"Result: {summary.get('result')}; passed: {summary.get('passedTests')}; failed: {summary.get('failedTests')}; skipped: {summary.get('skippedTests')}", ""]
    else:
        lines += ["Native test results are unavailable. Inspect the build and simulator boot logs.", ""]
    if (root / "ios-tests.json").is_file():
        cases = test_cases(read_json(root / "ios-tests.json").get("testNodes"))
        lines += ["| Test | Result | Seconds |", "| --- | --- | ---: |"]
        for case in sorted(cases, key=lambda item: item.get("durationInSeconds", 0), reverse=True):
            identifier = str(case.get("nodeIdentifier", "unknown")).replace("|", "\\|")
            lines.append(f"| {identifier} | {case.get('result')} | {case.get('durationInSeconds', 'unknown')} |")
    text = "\n".join(lines) + "\n"
    with (root / "ios-test-summary.md").open("x") as output:
        output.write(text)
    if step_summary:
        with Path(step_summary).open("a") as output:
            output.write(text)


def main():
    require(os.environ.get("GITHUB_ACTIONS") == "true", "Native evidence verification is Actions-only")
    root = Path(os.environ["UI_DIR"])
    if sys.argv[1:] == ["--summary-only"]:
        write_test_summary(root, os.environ.get("GITHUB_STEP_SUMMARY"))
        return
    require(not sys.argv[1:], "Unexpected native evidence arguments")
    evidence = verify_evidence(root)
    with (root / "ios-evidence.json").open("x") as output:
        json.dump(evidence, output, indent=2)
    print(f"Native iOS UI evidence verified: {len(SCENES)} passed, 0 failed, 0 skipped; {len(evidence['screenshots'])} named screenshots")


if __name__ == "__main__":
    main()
