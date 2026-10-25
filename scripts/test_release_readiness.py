"""Actions-only regression checks for audited privacy declarations."""
import copy
from pathlib import Path
import plistlib
import unittest

from verify_release_products import validate_icon_catalog, validate_privacy_manifest


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


class CompiledIconTests(unittest.TestCase):
    def setUp(self):
        self.icon = {"Name": "AppIcon", "AssetType": "Icon Image", "PixelWidth": 1024, "PixelHeight": 1024}

    def test_named_full_resolution_compiled_icon(self):
        self.assertEqual(validate_icon_catalog([{"AssetStorageVersion": 1}, self.icon], "AppIcon"), [self.icon])

    def test_missing_or_wrong_name_cannot_substitute_another_image(self):
        for value in ([], [dict(self.icon, Name="Unrelated")], [dict(self.icon, AssetType="Color")]):
            with self.subTest(value=value), self.assertRaises(RuntimeError):
                validate_icon_catalog(value, "AppIcon")

    def test_low_resolution_and_wrong_dimensions_are_rejected(self):
        for width, height in ((256, 256), (512, 512), (1024, 512), (512, 1024), (2048, 1024)):
            with self.subTest(width=width, height=height), self.assertRaises(RuntimeError):
                validate_icon_catalog([dict(self.icon, PixelWidth=width, PixelHeight=height)], "AppIcon")

    def test_dimension_types_are_not_coerced(self):
        for key, value in (("PixelWidth", "1024"), ("PixelHeight", 1024.0), ("PixelWidth", True)):
            with self.subTest(key=key, value=value), self.assertRaises(RuntimeError):
                validate_icon_catalog([dict(self.icon, **{key: value})], "AppIcon")

    def test_invalid_catalog_shape_is_rejected(self):
        for value in (None, self.icon, "AppIcon"):
            with self.subTest(value=value), self.assertRaises(RuntimeError):
                validate_icon_catalog(value, "AppIcon")


if __name__ == "__main__":
    unittest.main()
