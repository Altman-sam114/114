"""Actions-only regression fixtures for named, per-test native UI evidence."""
import copy
import json
from pathlib import Path
import struct
import tempfile
import unittest
import uuid
import zlib

from verify_ios_ui_evidence import SCENES, verify_evidence, write_test_summary


def png(width, height):
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress((b"\0" + bytes(width * 3)) * height)) + chunk(b"IEND", b""))


class NativeEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="chronofocus-native-fixture-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "attachments").mkdir()
        self.device = {"udid": "fixture-device", "deviceType": "com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation",
                       "pointWidth": 375, "pointHeight": 667, "scale": 2}
        self.summary = {"totalTestCount": len(SCENES), "passedTests": len(SCENES), "failedTests": 0, "skippedTests": 0,
                        "expectedFailures": 0, "testFailures": [], "result": "Passed",
                        "devicesAndConfigurations": [{"device": {"deviceId": "fixture-device", "platform": "iOS Simulator"},
                                                      "passedTests": len(SCENES), "failedTests": 0, "skippedTests": 0, "expectedFailures": 0}]}
        self.tree = {"devices": [{"deviceId": "fixture-device", "platform": "iOS Simulator"}],
                     "testNodes": [{"nodeType": "Test Suite", "children": [
                         {"nodeType": "Test Case", "nodeIdentifier": "ChronoFocusUITests/" + name + "()",
                          "result": "Passed", "durationInSeconds": 1.0} for name in SCENES]}]}
        self.manifest = []
        image = png(750, 1334)
        for name, scenes in SCENES.items():
            attachments = []
            for scene in scenes:
                token = str(uuid.uuid4())
                filename = token + ".png"
                (self.root / "attachments" / filename).write_bytes(image)
                attachments.append({"exportedFileName": filename, "suggestedHumanReadableName": scene + "_0_" + token + ".png", "deviceId": "fixture-device"})
            self.manifest.append({"testIdentifier": "ChronoFocusUITests/" + name + "()", "attachments": attachments})
        self.save()

    def save(self):
        for path, value in (("ios-summary.json", self.summary), ("ios-tests.json", self.tree), ("device.json", self.device), ("attachments/manifest.json", self.manifest)):
            (self.root / path).write_text(json.dumps(value))

    def rejected(self, message):
        self.save()
        with self.assertRaisesRegex(RuntimeError, message):
            verify_evidence(self.root)

    def test_current_eight_tests_and_thirty_four_bound_scenes(self):
        result = verify_evidence(self.root)
        self.assertEqual(len(result["screenshots"]), 34)
        self.assertEqual(len({item["scene"] for item in result["screenshots"]}), 34)
        self.assertEqual(len(result["executedTests"]), 8)

    def test_tree_missing_duplicate_wrong_identity_and_result_are_rejected(self):
        original = copy.deepcopy(self.tree)
        self.tree["testNodes"][0]["children"].pop()
        self.rejected("Missing executed native test")
        self.tree = copy.deepcopy(original)
        self.tree["testNodes"][0]["children"].append(copy.deepcopy(self.tree["testNodes"][0]["children"][0]))
        self.rejected("duplicate executed test")
        self.tree = copy.deepcopy(original)
        self.tree["testNodes"][0]["children"][0]["nodeIdentifier"] = "ChronoFocusUITests/unrelated()"
        self.rejected("executed test identity")
        for result in ("Skipped", "Failed", "Expected Failure"):
            self.tree = copy.deepcopy(original)
            self.tree["testNodes"][0]["children"][0]["result"] = result
            self.rejected("did not pass")

    def test_tree_device_and_duration_are_bound(self):
        original = copy.deepcopy(self.tree)
        self.tree["devices"][0]["deviceId"] = "another-device"
        self.rejected("tree belongs to a different simulator")
        for duration in (True, -1, float("nan"), "1"):
            self.tree = copy.deepcopy(original)
            self.tree["testNodes"][0]["children"][0]["durationInSeconds"] = duration
            self.rejected("Invalid native test duration")

    def test_failed_test_diagnostics_do_not_claim_acceptance(self):
        case = self.tree["testNodes"][0]["children"][0]
        case["result"] = "Failed"
        self.summary.update(result="Failed", passedTests=len(SCENES) - 1, failedTests=1)
        self.save()
        write_test_summary(self.root)
        text = (self.root / "ios-test-summary.md").read_text()
        self.assertIn(case["nodeIdentifier"], text)
        self.assertIn("Failed", text)
        self.assertIn("does not replace evidence verification", text)
        with self.assertRaises(RuntimeError):
            verify_evidence(self.root)

    def test_missing_scene_cannot_be_replaced_by_other_test(self):
        self.manifest[0]["attachments"][0], self.manifest[1]["attachments"][0] = self.manifest[1]["attachments"][0], self.manifest[0]["attachments"][0]
        self.rejected("screenshot scene")

    def test_missing_scene_and_test_are_rejected(self):
        original = copy.deepcopy(self.manifest)
        self.manifest[0]["attachments"].pop()
        self.rejected("Missing required screenshot")
        self.manifest = original[1:]
        self.rejected("Missing required native test")

    def test_duplicate_test_file_and_scene_are_rejected(self):
        original = copy.deepcopy(self.manifest)
        self.manifest.append(copy.deepcopy(self.manifest[0]))
        self.rejected("duplicate native test")
        self.manifest = copy.deepcopy(original)
        self.manifest[0]["attachments"].append(copy.deepcopy(self.manifest[0]["attachments"][0]))
        self.rejected("Duplicate screenshot file")
        self.manifest = copy.deepcopy(original)
        extra = copy.deepcopy(self.manifest[0]["attachments"][0])
        extra["exportedFileName"] = "different.png"
        self.manifest[0]["attachments"].append(extra)
        self.rejected("duplicate screenshot scene")

    def test_paths_and_device_binding_are_rejected(self):
        original = copy.deepcopy(self.manifest)
        for filename in ("../outside.png", "/outside.png", "..\\outside.png"):
            self.manifest = copy.deepcopy(original)
            self.manifest[0]["attachments"][0]["exportedFileName"] = filename
            self.rejected("Unsafe attachment path")
        self.manifest = original
        self.manifest[0]["attachments"][0]["deviceId"] = "another-device"
        self.rejected("different simulator")

    def test_failed_skipped_expected_and_wrong_device_cannot_pass(self):
        original = copy.deepcopy(self.summary)
        for key, value in (("failedTests", 1), ("skippedTests", 1), ("expectedFailures", 1), ("totalTestCount", 5), ("failedTests", False)):
            self.summary = dict(copy.deepcopy(original), **{key: value})
            self.rejected("native test count")
        self.summary = copy.deepcopy(original)
        self.summary["devicesAndConfigurations"][0]["device"]["deviceId"] = "another-device"
        self.rejected("different simulator")

    def test_dimensions_symlink_and_unbound_images_are_rejected(self):
        image = self.root / "attachments" / self.manifest[0]["attachments"][0]["exportedFileName"]
        original = image.read_bytes()
        image.write_bytes(png(750, 1400))
        self.rejected("portrait device")
        image.write_bytes(original)
        external = self.root / "external.png"
        external.write_bytes(original)
        image.unlink()
        image.symlink_to(external)
        self.rejected("Invalid evidence file")
        image.unlink()
        image.write_bytes(original)
        (self.root / "attachments/extra.png").write_bytes(original)
        self.rejected("Unbound screenshot")


if __name__ == "__main__":
    unittest.main()
