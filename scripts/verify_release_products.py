"""Actions-only inspection of the actual unsigned Release products."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import plistlib
import struct
import subprocess


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def validate_privacy_manifest(value, uses_defaults):
    require(set(value) == {"NSPrivacyTracking", "NSPrivacyTrackingDomains", "NSPrivacyCollectedDataTypes", "NSPrivacyAccessedAPITypes"}, "Unexpected privacy manifest keys")
    require(value["NSPrivacyTracking"] is False, "Tracking declaration differs from the audited app")
    require(value["NSPrivacyTrackingDomains"] == [] and value["NSPrivacyCollectedDataTypes"] == [], "Unexpected tracking domains or collected data")
    expected = [{"NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults", "NSPrivacyAccessedAPITypeReasons": ["CA92.1"]}] if uses_defaults else []
    require(value["NSPrivacyAccessedAPITypes"] == expected, "Required reason API declaration differs from actual use")


def inspect_mac_icon(content, info, output):
    name = info.get("CFBundleIconFile")
    require(isinstance(name, str) and name and Path(name).name == name, "Missing Mac app icon identity")
    path = content / "Resources" / (name if name.endswith(".icns") else name + ".icns")
    require(path.is_file() and not path.is_symlink(), "Missing Mac app icon resource")
    data = path.read_bytes()
    with (output / "mac-app-icon.icns").open("xb") as icon_copy:
        icon_copy.write(data)
    require(16 < len(data) <= 20971520 and data[:4] == b"icns" and int.from_bytes(data[4:8], "big") == len(data), "Invalid Mac app icon container")
    offset = 8
    entries = []
    while offset < len(data):
        require(offset + 8 <= len(data), "Truncated Mac icon entry")
        size = int.from_bytes(data[offset + 4:offset + 8], "big")
        require(size > 8 and offset + size <= len(data), "Invalid Mac icon entry size")
        payload = data[offset + 8:offset + size]
        entry = {"type": data[offset:offset + 4].decode("ascii", errors="replace"), "byteCount": size}
        if len(payload) >= 24 and payload[:8] == b"\x89PNG\r\n\x1a\n" and payload[12:16] == b"IHDR":
            entry["pixelWidth"], entry["pixelHeight"] = struct.unpack(">II", payload[16:24])
        entries.append(entry)
        offset += size
    with (output / "mac-icon-entries.json").open("x") as destination:
        json.dump(entries, destination, indent=2)
    print("Built Mac icon representations:", entries, flush=True)
    require(any(item["type"] == "ic10" for item in entries), "Mac app icon must include its 1024px representation")
    return {"fileName": path.name, "byteCount": len(data), "sha256": hashlib.sha256(data).hexdigest(),
            "contains1024pxRepresentation": True, "representations": entries}


def inspect_bundle(bundle, label, platform, uses_defaults, output):
    content = bundle / "Contents" if platform == "macosx" else bundle
    info = plistlib.loads((content / "Info.plist").read_bytes())
    require(info.get("DTPlatformName") == platform, "Wrong built platform")
    minimum = info.get("LSMinimumSystemVersion" if platform == "macosx" else "MinimumOSVersion", "")
    require(tuple(int(item) for item in minimum.split(".")[:2]) == ((14, 0) if platform == "macosx" else (17, 0)), "Minimum supported system changed")
    executable = content / "MacOS" / info["CFBundleExecutable"] if platform == "macosx" else content / info["CFBundleExecutable"]
    require(executable.is_file() and not executable.is_symlink(), "Missing Release executable")
    architectures = subprocess.check_output(["xcrun", "lipo", "-archs", str(executable)], text=True).split()
    require(set(architectures) == ({"arm64", "x86_64"} if platform == "macosx" else {"arm64"}), "Unexpected Release architectures")
    strings = subprocess.check_output(["/usr/bin/strings", "-a", str(executable)])
    for flag in (b"--ui-testing", b"--ui-fixture=", b"--ui-large-type", b"ChronoFocusUITests"):
        require(flag not in strings, "Debug UI test entry point leaked into Release")
    privacy_path = content / "Resources" / "PrivacyInfo.xcprivacy" if platform == "macosx" else content / "PrivacyInfo.xcprivacy"
    privacy = plistlib.loads(privacy_path.read_bytes())
    validate_privacy_manifest(privacy, uses_defaults)
    source = Path("Shared/PrivacyInfo.xcprivacy" if uses_defaults else "ChronoFocusLiveActivity/PrivacyInfo.xcprivacy")
    require(privacy == plistlib.loads(source.read_bytes()), "Built privacy manifest differs from source")
    with (output / f"privacy-{label}.xcprivacy").open("xb") as privacy_copy:
        privacy_copy.write(privacy_path.read_bytes())
    report = {
        "name": label, "bundleIdentifier": info["CFBundleIdentifier"], "platform": platform,
        "minimumSystemVersion": minimum, "version": info["CFBundleShortVersionString"],
        "buildNumber": info["CFBundleVersion"], "architectures": sorted(architectures),
        "executableBytes": executable.stat().st_size, "executableSHA256": hashlib.sha256(executable.read_bytes()).hexdigest(),
        "debugUIEntrypointsAbsent": True, "privacyManifest": privacy,
        "extensionPoint": info.get("NSExtension", {}).get("NSExtensionPointIdentifier"),
    }
    if platform == "macosx":
        report["appIcon"] = inspect_mac_icon(content, info, output)
    return report


def main():
    require(os.environ.get("GITHUB_ACTIONS") == "true", "Release product verification is Actions-only")
    parser = argparse.ArgumentParser()
    parser.add_argument("--mac", type=Path, required=True)
    parser.add_argument("--ios", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    reports = [
        inspect_bundle(args.mac, "mac-app", "macosx", True, args.output),
        inspect_bundle(args.ios, "ios-app", "iphoneos", True, args.output),
        inspect_bundle(args.ios / "PlugIns/ChronoFocusLiveActivity.appex", "ios-live-activity", "iphoneos", False, args.output),
    ]
    ios, activity = reports[1:]
    require(activity["bundleIdentifier"] == ios["bundleIdentifier"] + ".LiveActivity", "Embedded extension identity mismatch")
    require((activity["version"], activity["buildNumber"]) == (ios["version"], ios["buildNumber"]), "Embedded extension version mismatch")
    require(activity["extensionPoint"] == "com.apple.widgetkit-extension", "Wrong embedded extension")
    result = {
        "commitSha": subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(),
        "generatedAt": datetime.now(timezone.utc).isoformat(), "engineeringChecksPassed": True,
        "distributionReady": False, "signed": False, "products": reports,
        "remainingReleaseWork": ["Real Apple Team, bundle and product identifiers", "Signing, installation and distribution channel", "Public privacy policy and support information", "StoreKit sandbox, system permissions and physical-device background checks"],
    }
    with (args.output / "release-evidence.json").open("x") as destination:
        json.dump(result, destination, indent=2)
    print("Release products verified: universal Mac, arm64 iOS, embedded Live Activity, privacy resources, no Debug UI entrypoints. Unsigned; distribution approval remains outstanding.")


if __name__ == "__main__":
    main()
