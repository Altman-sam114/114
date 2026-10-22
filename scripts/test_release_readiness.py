"""Actions-only regression checks for audited privacy declarations."""
import copy
from pathlib import Path
import plistlib
import unittest

from verify_release_products import validate_privacy_manifest


class PrivacyManifestTests(unittest.TestCase):
    def setUp(self):
        self.app = plistlib.loads(Path("Shared/PrivacyInfo.xcprivacy").read_bytes())
        self.activity = plistlib.loads(Path("ChronoFocusLiveActivity/PrivacyInfo.xcprivacy").read_bytes())

    def test_current_source_declarations(self):
        validate_privacy_manifest(self.app, True)
        validate_privacy_manifest(self.activity, False)

    def test_required_reason_and_bundle_scope(self):
        for value, uses_defaults in ((self.activity, True), (self.app, False)):
            with self.subTest(uses_defaults=uses_defaults), self.assertRaises(RuntimeError):
                validate_privacy_manifest(value, uses_defaults)
        bad = copy.deepcopy(self.app)
        bad["NSPrivacyAccessedAPITypes"][0]["NSPrivacyAccessedAPITypeReasons"] = ["C56D.1"]
        with self.assertRaises(RuntimeError):
            validate_privacy_manifest(bad, True)

    def test_unexpected_collection_or_tracking_is_rejected(self):
        for key, value in (("NSPrivacyTracking", True), ("NSPrivacyTracking", 0),
                           ("NSPrivacyTrackingDomains", ["example.com"]),
                           ("NSPrivacyCollectedDataTypes", [{"NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeEmailAddress"}])):
            bad = dict(self.app, **{key: value})
            with self.subTest(key=key, value=value), self.assertRaises(RuntimeError):
                validate_privacy_manifest(bad, True)


if __name__ == "__main__":
    unittest.main()
