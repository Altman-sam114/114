"""Actions-only checks of the exact checkout-before-gate code used for UI evidence."""
import copy
from pathlib import Path
import re
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
        self.assertIn("|| github.sha }}", production)
        self.assertNotIn("|| github.ref }}", production)

    def test_unverified_matrix_artifacts_have_distinct_platform_and_attempt_names(self):
        upload = WORKFLOW.split("      - name: Upload independent UI evidence\n", 1)[1].split("\n      - name:", 1)[0]
        self.assertIn("if: always() && steps.gate.outputs.directory != ''", upload)
        fallback = re.search(
            r"^\s+name: \$\{\{ steps\.gate\.outputs\.artifact \|\| format\('([^']+)', ([^)]+)\) \}\}$",
            upload, re.MULTILINE,
        )
        self.assertIsNotNone(fallback, "Missing fallback on the actual upload step")
        arguments = [argument.strip() for argument in fallback.group(2).split(",")]
        self.assertCountEqual(arguments, ("matrix.platform", "github.run_id", "github.run_attempt"))
        matrix = re.search(r"^\s+platform: \[([^\]]+)\]$", WORKFLOW, re.MULTILINE)
        self.assertIsNotNone(matrix)
        platforms = [platform.strip() for platform in matrix.group(1).split(",")]
        self.assertCountEqual(platforms, ("mac", "ios-390", "ios-375", "release"))
        names = set()
        for run_id, attempt in ((123, 1), (123, 2), (124, 1)):
            for platform in platforms:
                context = {"matrix.platform": platform, "github.run_id": run_id, "github.run_attempt": attempt}
                name = fallback.group(1).format(*(context[argument] for argument in arguments))
                self.assertTrue(name.startswith("chronofocus-ui-unverified-"))
                self.assertIn(platform, name)
                self.assertNotIn(name, names, "Failed matrix jobs must preserve separate evidence")
                names.add(name)

    def test_schedule_long_text_uses_the_real_wrapping_row_and_separate_actions(self):
        schedule = Path("ChronoFocusMac/Views/MacScheduleDetailView.swift").read_text()
        panel = schedule.split("private struct MacTaskListPanelView: View", 1)[1].split("private struct MacScheduleCategoryEmptyStateView", 1)[0]
        loop = panel.split("ForEach(visibleTasks) { task in", 1)[1].split(".alert(", 1)[0]
        self.assertRegex(loop, r"VStack\(alignment: \.leading, spacing: 8\)\s*\{\s*MacTaskRowView\(task: task, allowsTextWrapping: true\)\s*taskActions\(for: task\)")
        actions = panel.split("private func taskActions(for task: FocusTask)", 1)[1].split("private var taskListControls", 1)[0]
        self.assertNotIn("MacTaskRowView(", actions)
        self.assertEqual(actions.count(".frame(width: 44, height: 44)"), 4)
        for operation in ("toggleTask(task)", "onTimerHandoff(task.category, task.id)", "setTask(task, enabled: $0)", "pendingDeletion = task"):
            self.assertIn(operation, actions)
        row = Path("ChronoFocusMac/Views/MacTimerDetailView.swift").read_text().split("struct MacTaskRowView: View", 1)[1].split("struct MacPageHeaderView", 1)[0]
        self.assertIn("var allowsTextWrapping = false", row)
        self.assertEqual(row.count(".lineLimit(allowsTextWrapping ? nil : 1)"), 2)
        self.assertEqual(row.count(".fixedSize(horizontal: false, vertical: allowsTextWrapping)"), 2)
        self.assertRegex(row, r"if allowsTextWrapping\s*\{\s*VStack\(alignment: \.leading, spacing: 6\)")
        renderer = Path("scripts/render_mac_snapshots.swift").read_text()
        self.assertIn('capture("schedule-long-text-1100.png", section: .schedule, content: AnyView(MacScheduleDetailView(initialTaskSearchQuery: "正式发布前")), width: 1100, height: 1000', renderer)
        self.assertIn("try assertScheduleTextWrapping(for: scheduleLongTask, store: store, directory: checksDirectory)", renderer)
        self.assertIn('directory.appendingPathComponent("schedule-text-wrap-measurements.json")', renderer)
        self.assertIn('short=\\(heights[0]), title=\\(heights[1]), category=\\(heights[2])', renderer)
        self.assertIn("heights[1] > heights[0], heights[2] > heights[0]", renderer)
        self.assertLess(renderer.index('directory.appendingPathComponent("schedule-text-wrap-measurements.json")'), renderer.index("guard heights[1] > heights[0]"))

    def test_native_execution_collect_and_diagnostics_keep_separate_failure_paths(self):
        def step(name):
            return WORKFLOW.split("      - name: " + name + "\n", 1)[1].split("\n      - name:", 1)[0]

        execution = step("Run native iOS UI tests")
        collection = step("Collect native iOS UI results and attachments")
        diagnostics = step("Summarize native UI test results including failures")
        self.assertIn("timeout-minutes: 14", execution)
        self.assertIn("bash scripts/run_ios_ui_tests.sh --test-only", execution)
        self.assertNotIn("xcresulttool", execution)
        self.assertIn("timeout-minutes: 5", collection)
        self.assertIn("bash scripts/run_ios_ui_tests.sh --collect-only", collection)
        for block in (collection, diagnostics):
            self.assertIn("if: always() && startsWith(matrix.platform, 'ios-') && steps.gate.outputs.sha != ''", block)
        self.assertIn("python3 scripts/verify_ios_ui_evidence.py --summary-only", diagnostics)
        ordered_steps = ["Run native iOS UI tests", "Collect native iOS UI results and attachments",
                         "Summarize native UI test results including failures", "Recheck source and bind visual manifest",
                         "Upload independent UI evidence", "Final source freshness check"]
        positions = [WORKFLOW.index("      - name: " + name + "\n") for name in ordered_steps]
        self.assertEqual(positions, sorted(positions))
        script = Path("scripts/run_ios_ui_tests.sh").read_text()
        collector = script.split("collect_native_results() {\n", 1)[1].split("\n}\n", 1)[0]
        for command in ("xcresulttool get test-results summary", "xcresulttool get test-results tests",
                        "xcresulttool export attachments", "python3 scripts/verify_ios_ui_evidence.py"):
            self.assertIn(command, collector)
        self.assertNotIn("xcodebuild", collector)
        self.assertNotIn("simctl", collector)
        self.assertIn('if [[ ! -d "$UI_DIR/ios.xcresult" ]]; then', collector)
        self.assertIn("return 1", collector)
        self.assertLess(script.index('if [[ "$phase" == --collect-only ]]'), script.index("device_udid="))
        self.assertIn('if [[ "$phase" == --test-only ]]; then\n  exit "$test_status"\nfi', script)
        self.assertIn("collect_native_results || collection_status=$?", script)
        self.assertIn('if [[ "$test_status" -ne 0 ]]; then\n  exit "$test_status"\nfi\nexit "$collection_status"', script)
        self.assertEqual(script.count('"${test_command[@]}" 2>&1 | tee'), 1)


if __name__ == "__main__":
    unittest.main()
