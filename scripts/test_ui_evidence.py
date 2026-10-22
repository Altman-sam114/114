"""Actions-only checks of the exact checkout-before-gate code used for UI evidence."""
import copy
from pathlib import Path
import textwrap
import unittest


WORKFLOW = Path(".github/workflows/ui-evidence.yml").read_text()
GATE_SOURCE = textwrap.dedent(WORKFLOW.split("# BEGIN UI SOURCE GATE\n", 1)[1].split("# END UI SOURCE GATE", 1)[0])
NAMESPACE = {"__name__": "ui_gate_fixture", "__file__": "/tmp/ui-gate-fixture/verify-source.py"}
exec(compile(GATE_SOURCE, "ui-evidence-preflight", "exec"), NAMESPACE)


class UISourceGateTests(unittest.TestCase):
    def setUp(self):
        self.sha = "a" * 40
        self.run = {
            "id": 123, "run_attempt": 1, "head_sha": self.sha, "head_branch": "main",
            "workflow_id": 306720987, "path": ".github/workflows/ci-results.yml",
            "name": "ChronoFocus CI Results [failure_mode=none]",
            "display_title": "ChronoFocus CI Results [failure_mode=none]",
            "event": "push", "status": "completed", "conclusion": "success",
            "repository": {"full_name": "Altman-sam114/114"},
            "head_repository": {"full_name": "Altman-sam114/114"},
            "actor": {"login": "Altman-sam114"}, "triggering_actor": {"login": "Altman-sam114"},
        }
        self.workflow = {"id": 306720987, "name": "ChronoFocus CI Results",
                         "path": ".github/workflows/ci-results.yml", "state": "active"}

    def gate(self, run=None, event=None, sha=None, workflow=None):
        value = self.run if run is None else run
        NAMESPACE["gate"](value, copy.deepcopy(value) if event is None else event,
                          self.sha if sha is None else sha, self.workflow if workflow is None else workflow)

    def test_current_authorized_push(self):
        self.gate()
        static_name = dict(self.run, name="ChronoFocus CI Results")
        self.gate(run=static_name)

    def test_stale_sha_and_attempt(self):
        with self.assertRaises(RuntimeError):
            self.gate(sha="b" * 40)
        with self.assertRaises(RuntimeError):
            self.gate(event=dict(self.run, run_attempt=2))

    def test_source_profile_and_workflow_mutations(self):
        mutations = {"head_branch": "develop", "workflow_id": 1, "name": "Other workflow",
                     "path": ".github/workflows/ui-evidence.yml", "event": "workflow_dispatch",
                     "status": "in_progress", "conclusion": "failure", "id": True, "run_attempt": 0,
                     "head_sha": "not-a-sha", "display_title": "ChronoFocus CI Results [failure_mode=selectXcode]"}
        for key, value in mutations.items():
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                self.gate(run=dict(self.run, **{key: value}))
        for key, field in (("repository", "full_name"), ("head_repository", "full_name"),
                           ("actor", "login"), ("triggering_actor", "login")):
            bad = copy.deepcopy(self.run)
            bad[key][field] = "unauthorized"
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                self.gate(run=bad)
        for key, value in (("id", True), ("name", "Other"), ("path", "other.yml"), ("state", "disabled_manually")):
            with self.subTest(workflow_key=key), self.assertRaises(RuntimeError):
                self.gate(workflow=dict(self.workflow, **{key: value}))

    def test_event_identity_and_duplicate_keys(self):
        bad = copy.deepcopy(self.run)
        bad["triggering_actor"]["login"] = "another-user"
        with self.assertRaises(RuntimeError):
            self.gate(event=bad)
        with self.assertRaises(RuntimeError):
            NAMESPACE["unique_object"]([("id", 1), ("id", 2)])

    def test_workflow_uses_gated_checkout_and_separate_artifact(self):
        self.assertLess(WORKFLOW.index("python3 \"$ui_dir/verify-source.py\" initial"), WORKFLOW.index("uses: actions/checkout@v5"))
        for token in ("contents: read", "actions: read", "ref: ${{ steps.gate.outputs.sha }}",
                      "persist-credentials: false", "before-upload", "after-upload",
                      "actual == run[\"head_sha\"]", "uiWorkflowHeadSha", "sourceRunAttempt",
                      "bash scripts/build_mac_snapshot_renderer.sh"):
            self.assertIn(token, WORKFLOW)
        self.assertEqual(WORKFLOW.count("uses: actions/upload-artifact@v6"), 1)
        self.assertNotIn("path: ci-results", WORKFLOW)
        production = Path(".github/workflows/ci-results.yml").read_text()
        self.assertEqual(production.count("uses: actions/upload-artifact@v6"), 1)


if __name__ == "__main__":
    unittest.main()
