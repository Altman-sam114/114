#!/usr/bin/env python3
"""Actions-only review boundary fixtures; no network and no project builds.

Gate/download/orchestration fixtures mock GitHub and the validator process. The
failure-profile integration fixture separately invokes the real Ruby validator.
All fixture evidence is retained under RUNNER_TEMP, never removed by this script.
"""

import ast
import copy
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile
import textwrap
import unittest
from unittest.mock import patch
import warnings
import zipfile

import review_ci_artifact as review


ROOT = Path(__file__).resolve().parents[1]
SHA = "a" * 40


def run_fixture(injection=None):
    return {
        "id": 12345, "run_attempt": 2, "workflow_id": 23456,
        "head_sha": SHA, "head_branch": "main", "name": review.WORKFLOW_NAME,
        "path": review.WORKFLOW_PATH, "status": "completed",
        "conclusion": "failure" if injection else "success",
        "event": "workflow_dispatch" if injection else "push",
        "display_title": f"ChronoFocus CI Results [failure_mode={injection or 'none'}]",
        "repository": {"full_name": review.REPOSITORY},
        "head_repository": {"full_name": review.REPOSITORY},
        "actor": {"login": review.ACTOR}, "triggering_actor": {"login": review.ACTOR},
    }


def metadata_fixture(run, data=b"zip fixture", fallback=False):
    sha = run["head_sha"] if fallback else run["head_sha"][:7]
    return {"total_count": 1, "artifacts": [{
        "id": 34567, "name": f"chronofocus-ci-v0.10-main-{sha}-run{run['id']}-attempt{run['run_attempt']}",
        "size_in_bytes": len(data), "digest": "sha256:" + hashlib.sha256(data).hexdigest(),
        "expired": False,
        "workflow_run": {"id": run["id"], "head_sha": run["head_sha"], "head_branch": "main"},
    }]}


def jobs_fixture(run, injection):
    steps = [{"name": review.INJECTIONS[injection][0], "number": 7,
              "status": "completed", "conclusion": "success",
              "started_at": "2026-09-08T12:00:00Z", "completed_at": "2026-09-08T12:00:00Z"}]
    if injection == "checkout":
        steps[0].update(number=2, completed_at="2026-09-08T12:00:02Z")
        steps.append({"name": "Bootstrap result package", "number": 4,
                      "status": "completed", "conclusion": "success",
                      "started_at": "2026-09-08T12:00:04Z", "completed_at": "2026-09-08T12:00:04Z"})
    return {"total_count": 1, "jobs": [{
        "id": 45678, "run_id": run["id"], "run_attempt": run["run_attempt"],
        "head_sha": run["head_sha"], "head_branch": "main", "status": "completed", "conclusion": "failure",
        "steps": steps,
    }]}


def write_json(path, value):
    with path.open("x", encoding="utf-8") as stream:
        json.dump(value, stream)
    return path


def bootstrap_namespace():
    source = (ROOT / ".github/workflows/ci-artifact-review.yml").read_text()
    start = source.index("          # BEGIN REVIEW PREFLIGHT\n")
    end = source.index("          # END REVIEW PREFLIGHT\n", start)
    code = textwrap.dedent(source[start:end])
    namespace = {"__name__": "fixture_preflight"}
    exec(compile(code, "review-preflight", "exec"), namespace)
    return namespace


def excerpt_namespace():
    source = (ROOT / review.WORKFLOW_PATH).read_text()
    start = source.index("          failure_pattern = re.compile(")
    end = source.index("\n          def path_metadata", start)
    # Select only the real diagnostic pattern and helpers from the workflow AST.
    block = textwrap.dedent(source[start:end])
    tree = ast.parse(block)
    selected = [node for node in tree.body if (
        isinstance(node, ast.FunctionDef) and node.name in {"compact_log_line", "failure_excerpts"}
    ) or (
        isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "failure_pattern" for t in node.targets)
    )]
    namespace = {"re": re, "Path": Path}
    exec(compile(ast.Module(body=selected, type_ignores=[]), "workflow-excerpts", "exec"), namespace)
    return namespace


class ReviewFixtures(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.evidence = Path(tempfile.mkdtemp(prefix="chronofocus-review-fixtures-", dir=os.environ.get("RUNNER_TEMP")))
        print(f"Review fixture evidence retained: {cls.evidence}", flush=True)
        cls.bootstrap = bootstrap_namespace()

    def setUp(self):
        self.directory = Path(tempfile.mkdtemp(prefix=self._testMethodName + "-", dir=self.evidence))

    def make_zip(self, entries, name="raw.zip.part"):
        path = self.directory / name
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", UserWarning)
            with zipfile.ZipFile(path, "x", compression=zipfile.ZIP_STORED) as archive:
                for entry, content in entries:
                    archive.writestr(entry, content)
        return path

    def test_both_gates_accept_only_registered_profiles(self):
        for gate in (review.gate, self.bootstrap["gate"]):
            run = run_fixture()
            self.assertEqual(gate(run, copy.deepcopy(run), SHA), ("success", "none"))
            for injection in review.INJECTIONS:
                run = run_fixture(injection)
                self.assertEqual(gate(run, copy.deepcopy(run), SHA), ("controlled-failure", injection))

    def test_both_gates_reject_identity_and_profile_mutations(self):
        mutations = [
            ("actor", {"login": "intruder"}), ("triggering_actor", {"login": "intruder"}),
            ("repository", {"full_name": "intruder/114"}), ("head_repository", {"full_name": "intruder/114"}),
            ("name", "Other CI"), ("path", ".github/workflows/other.yml"),
            ("event", "pull_request"), ("head_branch", "feature"), ("head_sha", "b" * 40),
            ("status", "in_progress"), ("conclusion", "failure"), ("conclusion", "cancelled"),
            ("conclusion", "timed_out"), ("conclusion", "skipped"),
            ("display_title", "arbitrary title"), ("id", True), ("run_attempt", 0),
        ]
        for gate in (review.gate, self.bootstrap["gate"]):
            for key, value in mutations:
                with self.subTest(gate=gate.__module__, key=key, value=value):
                    run = run_fixture()
                    run[key] = value
                    with self.assertRaises((RuntimeError, review.Rejected)):
                        gate(run, copy.deepcopy(run), SHA)
            for injection in (None, "none", "unknown", "macBuild] extra"):
                run = run_fixture(injection)
                run.update(event="workflow_dispatch", conclusion="failure")
                with self.assertRaises(RuntimeError):
                    gate(run, copy.deepcopy(run), SHA)
            run = run_fixture("macBuild")
            run["conclusion"] = "success"
            with self.assertRaises(RuntimeError):
                gate(run, copy.deepcopy(run), SHA)
            run = run_fixture()
            event = copy.deepcopy(run)
            event["run_attempt"] = 1
            with self.assertRaises(RuntimeError):
                gate(run, event, SHA)

    def test_workflow_registration_and_permissions(self):
        contract = review.workflow_contract(ROOT)
        self.assertEqual(contract["version"], "v0.10")
        source = (ROOT / ".github/workflows/ci-artifact-review.yml").read_text()
        parsed = subprocess.run([
            "ruby", "-ryaml", "-rjson", "-e", 'puts JSON.generate(YAML.load_file(ARGV[0]))',
            str(ROOT / ".github/workflows/ci-artifact-review.yml"),
        ], capture_output=True, text=True, check=True, timeout=30)
        workflow = json.loads(parsed.stdout)
        self.assertEqual(workflow["permissions"], {"contents": "read", "actions": "read"})
        trigger = workflow.get("on", workflow.get("true"))
        self.assertEqual(trigger, {"workflow_run": {"workflows": [review.WORKFLOW_NAME], "types": ["completed"]}})
        steps = workflow["jobs"]["review"]["steps"]
        self.assertEqual(steps[0]["id"], "gate")
        self.assertIn("# BEGIN REVIEW PREFLIGHT", steps[0]["run"])
        self.assertEqual(steps[1]["with"]["ref"], "${{ steps.gate.outputs.sha }}")
        self.assertIs(steps[1]["with"]["persist-credentials"], False)
        self.assertNotIn("continue-on-error", source)
        self.assertNotIn("secrets.", source)
        self.assertIn("ruby -rrexml/document -rzlib", source)
        self.assertIn("command -v unzip", source)
        source_ci = (ROOT / review.WORKFLOW_PATH).read_text()
        self.assertIn('Dir.glob(".github/workflows/*.{yml,yaml}")', source_ci)
        self.assertIn("python3 scripts/test_review_ci_artifact.py", source_ci)

    def test_artifact_identity_uniqueness_and_external_metadata(self):
        run = run_fixture()
        metadata = metadata_fixture(run)
        self.assertEqual(review.choose_artifact(metadata, run, "success", "v0.10")["id"], 34567)
        failures = [
            {"total_count": 0, "artifacts": []},
            {"total_count": 2, "artifacts": metadata["artifacts"]},
            {"total_count": 2, "artifacts": metadata["artifacts"] * 2},
            {"total_count": 1, "artifacts": metadata["artifacts"] * 2},
        ]
        for key, value in (("expired", True), ("expired", None), ("name", "review-evidence"),
                           ("digest", ""), ("size_in_bytes", 0), ("id", True),
                           ("workflow_run", {"id": 999, "head_sha": SHA, "head_branch": "main"})):
            broken = copy.deepcopy(metadata)
            broken["artifacts"][0][key] = value
            failures.append(broken)
        for broken in failures:
            with self.subTest(metadata=broken), self.assertRaises(review.Rejected):
                review.choose_artifact(broken, run, "success", "v0.10")
        fallback = metadata_fixture(run, fallback=True)
        with self.assertRaises(review.Rejected):
            review.choose_artifact(fallback, run, "success", "v0.10")
        review.choose_artifact(fallback, run, "controlled-failure", "v0.10")

    def test_json_and_atomic_evidence_boundaries(self):
        good = write_json(self.directory / "good.json", {"id": 1})
        self.assertEqual(review.read_json(good), {"id": 1})
        for name, data in (("empty", b""), ("invalid", b"{"), ("duplicate", b'{"id":1,"id":2}'),
                           ("large", b" " * (review.MAX_JSON + 1))):
            path = self.directory / name
            path.write_bytes(data)
            with self.assertRaises((review.Rejected, json.JSONDecodeError)):
                review.read_json(path)
        symlink = self.directory / "link.json"
        symlink.symlink_to(good)
        with self.assertRaises(review.Rejected):
            review.read_json(symlink)
        with self.assertRaises(review.Rejected):
            review.read_json(self.directory)
        part = self.directory / "new.json.part"
        part.write_bytes(b'{"new":true}')
        with self.assertRaises(OSError):
            review.promote(part, good)
        self.assertTrue(part.exists())
        self.assertEqual(review.read_json(good), {"id": 1})
        final = self.directory / "new.json"
        review.promote(part, final)
        self.assertEqual(review.read_json(final), {"new": True})

    def test_download_retries_retain_failed_parts_and_never_overwrite(self):
        destination = self.directory / "api.json"
        calls = []

        def download(command, **kwargs):
            calls.append(command)
            kwargs["stdout"].write(b"partial" if len(calls) == 1 else b'{"ok":true}')
            return subprocess.CompletedProcess(command, 1 if len(calls) == 1 else 0)

        with patch.object(review.subprocess, "run", side_effect=download), patch.object(review.time, "sleep"):
            review.fetch("repos/example/actions/runs/1", destination)
        self.assertEqual(len(calls), 2)
        self.assertEqual((self.directory / "api.json.part").read_bytes(), b"partial")
        self.assertEqual(review.read_json(destination), {"ok": True})
        with self.assertRaises(review.Rejected):
            review.fetch("not-called", destination)
        with patch.object(review.subprocess, "run", return_value=subprocess.CompletedProcess([], 1)), patch.object(review.time, "sleep"):
            with self.assertRaises(review.Rejected):
                review.fetch("unavailable", self.directory / "failed.json")
        self.assertEqual(len(list(self.directory.glob("failed.json*.part"))), 3)
        self.assertFalse((self.directory / "failed.json").exists())

    def test_real_child_transfer_limit_stops_both_download_paths(self):
        real_run = subprocess.run
        for preflight in (False, True):
            with self.subTest(preflight=preflight):
                destination = self.directory / ("preflight.json" if preflight else "download.json")
                results = []

                def oversized_child(command, **kwargs):
                    self.assertEqual(command[:2], ["gh", "api"])
                    self.assertTrue(callable(kwargs.get("preexec_fn")))
                    result = real_run([sys.executable, "-c", "import os\nwhile True: os.write(1, b'x' * 4096)"], **kwargs)
                    results.append(result)
                    return result

                with patch.object(review.subprocess, "run", side_effect=oversized_child), \
                        patch.dict(self.bootstrap, MAX_JSON=1024):
                    with self.assertRaisesRegex(RuntimeError, "Transfer size limit"):
                        if preflight:
                            self.bootstrap["fetch_json"]("fixture-only", destination)
                        else:
                            review.fetch("fixture-only", destination, limit=1024)
                self.assertEqual(len(results), 1)
                self.assertNotEqual(results[0].returncode, 0)
                self.assertFalse(destination.exists())
                self.assertEqual(Path(str(destination) + ".part").stat().st_size, 1024)
                self.assertLessEqual(Path(str(destination) + ".part.stderr").stat().st_size, 1024)

    def test_zip_safe_streaming_and_tampered_bytes(self):
        path = self.make_zip([("nested/file.txt", "frozen fixture content")])
        artifact = metadata_fixture(run_fixture(), path.read_bytes())["artifacts"][0]
        review.check_zip(path, artifact)
        final = self.directory / "raw.zip"
        review.promote(path, final)
        extracted = self.directory / "extracted"
        review.extract_zip(final, extracted)
        self.assertEqual((extracted / "nested/file.txt").read_text(), "frozen fixture content")
        with self.assertRaises(FileExistsError):
            review.extract_zip(final, extracted)
        bad = copy.deepcopy(artifact)
        bad["digest"] = "sha256:" + "0" * 64
        with self.assertRaisesRegex(review.Rejected, "digest"):
            review.check_zip(final, bad)
        bad["size_in_bytes"] += 1
        with self.assertRaisesRegex(review.Rejected, "byte count"):
            review.check_zip(final, bad)
        link = self.directory / "link.zip"
        link.symlink_to(final)
        with self.assertRaises(review.Rejected):
            review.check_zip(link, artifact)

    def test_zip_rejects_unsafe_paths_types_encryption_and_limits(self):
        symlink = zipfile.ZipInfo("link")
        symlink.create_system = 3
        symlink.external_attr = (stat.S_IFLNK | 0o777) << 16
        fifo = zipfile.ZipInfo("fifo")
        fifo.create_system = 3
        fifo.external_attr = (stat.S_IFIFO | 0o600) << 16
        cases = [
            [("../escape", "x")], [("/absolute", "x")], [("a\\b", "x")],
            [("C:/absolute", "x")], [("a/./b", "x")], [("a//b", "x")],
            [("a", "x"), ("a", "y")], [("a/b", "x"), ("a", "y")],
            [("a", "x"), ("a/", "")], [(symlink, "../outside")], [(fifo, "")],
            [("bad\nname", "x")], [("directory/", "unexpected data")],
        ]
        for index, entries in enumerate(cases):
            path = self.make_zip(entries, f"unsafe-{index}.zip")
            with self.subTest(index=index), self.assertRaises(review.Rejected):
                review.zip_inventory(path)
        encrypted = self.make_zip([("plain", "payload")], "encrypted.zip")
        data = bytearray(encrypted.read_bytes())
        data[6] |= 1
        data[data.index(b"PK\x01\x02") + 8] |= 1
        encrypted.write_bytes(data)
        with self.assertRaisesRegex(review.Rejected, "Encrypted"):
            review.zip_inventory(encrypted)
        path = self.make_zip([("a", "1234"), ("b", "5678")], "limited.zip")
        for limit, value in (("MAX_ENTRIES", 1), ("MAX_EXPANDED", 7), ("MAX_FILE", 3)):
            with patch.object(review, limit, value), self.assertRaises(review.Rejected):
                review.zip_inventory(path)
        corrupt = self.make_zip([("entry", "original-unique-payload")], "crc.zip")
        corrupt.write_bytes(corrupt.read_bytes().replace(b"original-unique-payload", b"modified-unique-payload"))
        artifact = metadata_fixture(run_fixture(), corrupt.read_bytes())["artifacts"][0]
        with self.assertRaisesRegex(review.Rejected, "CRC/integrity"):
            review.check_zip(corrupt, artifact)

    def test_controlled_injection_binds_registration_stage_job_and_emitted_log(self):
        run = run_fixture("macBuild")
        write_json(self.directory / "ci-stage-outcomes.json", {
            "failureMode": "macBuild", "stageOutcomeMap": {"macBuild": "failure"},
        })
        log = self.directory / "job.log"
        log.write_text("2026-09-08T12:00:00.000Z Injected Mac build failure.\n")
        jobs = jobs_fixture(run, "macBuild")
        review.controlled_evidence(self.directory, run, "macBuild", jobs, log)
        for conclusion in ("skipped", "cancelled", None):
            broken = copy.deepcopy(jobs)
            broken["jobs"][0]["steps"][0]["conclusion"] = conclusion
            with self.assertRaises(review.Rejected):
                review.select_job(broken, run, "macBuild")
        with self.assertRaises(review.Rejected):
            review.controlled_evidence(self.directory, run, "iosBuild", jobs, log)
        log.write_text("2026-09-08T12:00:00.000Z printf 'Injected Mac build failure.'\n")
        with self.assertRaisesRegex(review.Rejected, "emitted"):
            review.controlled_evidence(self.directory, run, "macBuild", jobs, log)
        for key, value in (("run_attempt", 1), ("head_sha", "b" * 40), ("conclusion", "success")):
            broken = copy.deepcopy(jobs)
            broken["jobs"][0][key] = value
            with self.assertRaises(review.Rejected):
                review.select_job(broken, run, "macBuild")

    def test_injection_step_windows_all_modes_and_checkout_error_witness(self):
        for injection in review.INJECTIONS:
            with self.subTest(injection=injection):
                directory = self.directory / injection
                directory.mkdir()
                write_json(directory / "ci-stage-outcomes.json", {
                    "failureMode": injection, "stageOutcomeMap": {injection: "failure"},
                })
                run = run_fixture(injection)
                jobs = jobs_fixture(run, injection)
                log = directory / "job.log"
                second = "04" if injection == "checkout" else "00"
                marker = review.INJECTIONS[injection][1]
                error = "2026-09-08T12:00:01.123Z fatal: couldn't find remote ref refs/heads/__chronofocus_controlled_checkout_failure__\n" if injection == "checkout" else ""
                for fraction in ("000000", "999999"):
                    log.write_text(error + f"2026-09-08T12:00:{second}.{fraction}Z {marker}\n")
                    review.controlled_evidence(directory, run, injection, jobs, log)
                # The next second belongs outside this executed step, even when
                # the target step started and completed within one API second.
                next_second = "05" if injection == "checkout" else "01"
                jobs["jobs"][0]["steps"].append({
                    "name": "Unrelated later step", "number": 10, "status": "completed", "conclusion": "success",
                    "started_at": f"2026-09-08T12:00:{next_second}Z",
                    "completed_at": f"2026-09-08T12:00:{next_second}Z",
                })
                log.write_text(error + f"2026-09-08T12:00:{next_second}.000000Z {marker}\n")
                with self.assertRaisesRegex(review.Rejected, "step window"):
                    review.controlled_evidence(directory, run, injection, jobs, log)
                log.write_text(error + f"2026-09-08T11:59:59.999999Z {marker}\n")
                with self.assertRaisesRegex(review.Rejected, "step window"):
                    review.controlled_evidence(directory, run, injection, jobs, log)
                if injection == "checkout":
                    witness = f"2026-09-08T12:00:04.500Z {marker}\n"
                    for bad_error in ("", error.replace("12:00:01.123", "12:00:04.123"),
                                      error.replace("__chronofocus_controlled_checkout_failure__", "unrelated-ref")):
                        log.write_text(bad_error + witness)
                        with self.assertRaisesRegex(review.Rejected, "checkout error"):
                            review.controlled_evidence(directory, run, injection, jobs, log)

    def test_prepare_metadata_injection_emits_and_persists_marker(self):
        source = (ROOT / review.WORKFLOW_PATH).read_text()
        start = source.index('          if [[ "$FAILURE_INJECTION" == "prepareMetadata" ]]; then')
        end = source.index("\n          fi", start) + len("\n          fi")
        command = "set -euo pipefail\n" + textwrap.dedent(source[start:end])
        result = subprocess.run(["bash", "-c", command], cwd=self.directory,
                                env=dict(os.environ, FAILURE_INJECTION="prepareMetadata"),
                                capture_output=True, text=True, check=False, timeout=10)
        self.assertEqual(result.returncode, 91)
        marker = "Controlled failure injection: prepareMetadata\n"
        self.assertEqual(result.stdout, marker)
        self.assertEqual((self.directory / "ci-results/prepare-metadata.log").read_text(), marker)

    def test_formal_command_cannot_omit_external_parameters_or_downgrade(self):
        run = run_fixture()
        artifact = metadata_fixture(run)["artifacts"][0]
        for profile in ("success", "controlled-failure"):
            source = run_fixture("macBuild" if profile == "controlled-failure" else None)
            source_artifact = metadata_fixture(source)["artifacts"][0]
            command = review.validator_command(ROOT, self.directory / "extracted", self.directory / "raw.zip",
                                               source_artifact, source, profile, self.directory)
            for flag in ("--commit", "--run-id", "--attempt", "--branch", "--archive", "--archive-size",
                         "--archive-digest", "--artifact-metadata", "--run-metadata", "--expected-event"):
                self.assertEqual(command.count(flag), 1)
            self.assertEqual("--failure-mode" in command, profile == "controlled-failure")
        with self.assertRaises(review.Rejected):
            review.validator_command(ROOT, self.directory, self.directory / "raw.zip", artifact, run, "controlled-failure", self.directory)
        for key in ("size_in_bytes", "digest"):
            broken = copy.deepcopy(artifact)
            del broken[key]
            with self.assertRaises(KeyError):
                review.validator_command(ROOT, self.directory, self.directory / "raw.zip", broken, run, "success", self.directory)

    def test_pre_download_and_final_recheck_refuse_stale_sources(self):
        run = run_fixture()
        for label, field, value in (("before-download", "head_sha", "b" * 40), ("final", "run_attempt", 3)):
            changed = copy.deepcopy(run)
            changed[field] = value

            def fetch(endpoint, destination, **kwargs):
                return write_json(destination, {"sha": SHA} if endpoint.endswith("commits/main") else changed)

            with patch.object(review, "fetch", side_effect=fetch), self.assertRaises(review.Stale):
                review.recheck(self.directory, run, label)

    def test_preflight_rejection_never_exports_checkout_sha(self):
        run = run_fixture()
        run["conclusion"] = "failure"
        event_path = write_json(self.directory / "event.json", {
            "action": "completed", "repository": {"full_name": review.REPOSITORY}, "workflow_run": run,
        })
        output = self.directory / "github-output"
        summary = self.directory / "github-summary"

        def fetch(endpoint, destination):
            value = {"sha": SHA} if endpoint.endswith("commits/main") else run
            write_json(destination, value)
            return value

        with patch.dict(os.environ, RUNNER_TEMP=str(self.directory), GITHUB_EVENT_PATH=str(event_path),
                        GITHUB_OUTPUT=str(output), GITHUB_STEP_SUMMARY=str(summary),
                        GITHUB_RUN_ID="999", GITHUB_RUN_ATTEMPT="1"), \
                patch.dict(self.bootstrap, fetch_json=fetch):
            with self.assertRaises(RuntimeError):
                self.bootstrap["main"]()
        self.assertIn("evidence=", output.read_text())
        self.assertNotIn("sha=", output.read_text())
        self.assertIn("rejected before checkout", summary.read_text())

    def test_orchestration_mock_validator_profiles_and_no_failure_retry(self):
        real_run = subprocess.run
        for injection, validator_exit, failure_point in (
            (None, 0, None), ("macBuild", 0, None), (None, 1, None),
            (None, 0, "final-stale"), (None, 0, "download"),
        ):
            with self.subTest(injection=injection, validator_exit=validator_exit, failure_point=failure_point):
                evidence = Path(tempfile.mkdtemp(prefix="mock-validator-", dir=self.directory))
                run = run_fixture(injection)
                event = write_json(evidence / "event.json", {
                    "action": "completed", "repository": {"full_name": review.REPOSITORY}, "workflow_run": run,
                })
                write_json(evidence / "run-api.json", run)
                write_json(evidence / "main-api.json", {"sha": SHA})
                source_zip = evidence / "fixture-source.zip"
                with zipfile.ZipFile(source_zip, "x") as archive:
                    archive.writestr("ci-stage-outcomes.json", json.dumps({
                        "failureMode": injection, "stageOutcomeMap": {"macBuild": "failure"},
                    }))
                metadata = metadata_fixture(run, source_zip.read_bytes())
                commands = []

                def fetch(endpoint, destination, **kwargs):
                    if endpoint.endswith("/zip"):
                        self.assertEqual(kwargs["limit"], metadata["artifacts"][0]["size_in_bytes"])
                        part = destination.with_name(destination.name + ".part")
                        with part.open("xb") as output:
                            output.write(source_zip.read_bytes())
                        if failure_point == "download":
                            raise review.Rejected("Fixture download failed; part retained")
                        return part
                    if endpoint.endswith("/logs"):
                        part = destination.with_name(destination.name + ".part")
                        with part.open("x") as output:
                            output.write("2026-09-08T12:00:00.000Z Injected Mac build failure.\n")
                        return part
                    if endpoint.endswith("/artifacts"):
                        value = metadata
                    elif endpoint.endswith("/jobs"):
                        value = jobs_fixture(run, injection)
                    elif endpoint.endswith("commits/main"):
                        value = {"sha": "b" * 40 if failure_point == "final-stale" and destination.name == "final-main-api.json" else SHA}
                    else:
                        value = run
                    return write_json(destination, value)

                def execute(command, **kwargs):
                    if command[:3] == ["git", "rev-parse", "HEAD"]:
                        return subprocess.CompletedProcess(command, 0, stdout=SHA + "\n")
                    if command[:2] == ["ruby", str(ROOT / "scripts/validate_ci_artifact.rb")]:
                        commands.append(command)
                        kwargs["stdout"].write(b"PASS mock validator boundary\n" if validator_exit == 0 else b"FAIL mock validator boundary\n")
                        return subprocess.CompletedProcess(command, validator_exit)
                    return real_run(command, **kwargs)

                report = {"conclusion": "rejected"}
                with patch.object(review, "fetch", side_effect=fetch), patch.object(review.subprocess, "run", side_effect=execute):
                    if validator_exit or failure_point:
                        with self.assertRaises(review.Rejected):
                            review.review(evidence, event, ROOT, report)
                    else:
                        review.review(evidence, event, ROOT, report)
                self.assertEqual(len(commands), 0 if failure_point == "download" else 1)
                if commands:
                    self.assertEqual("--failure-mode" in commands[0], injection is not None)
                    self.assertEqual(report["validator_exit"], validator_exit)
                    self.assertTrue((evidence / "final-run-api.json").is_file())
                    self.assertTrue((evidence / "final-main-api.json").is_file())
                if validator_exit or failure_point:
                    self.assertEqual(report["conclusion"], "rejected")
                self.assertFalse((evidence / "extracted/run-api.json").exists())

    def test_failure_excerpt_preserves_one_to_seven_diagnostics(self):
        excerpts = excerpt_namespace()["failure_excerpts"]
        for count in (1, 3, 7, 8, 10):
            log = self.directory / f"diagnostics-{count}.log"
            log.write_text("\n".join([f"error: diagnostic {i}" for i in range(count)] + ["ordinary tail"] * 20))
            result = excerpts("failure", log)
            self.assertEqual(len(result), min(count, 8))
            self.assertTrue(all("diagnostic" in line and not line.startswith("tail:") for line in result))
        log = self.directory / "tail.log"
        log.write_text("only ordinary output\n")
        self.assertEqual(excerpts("failure", log), ["tail: only ordinary output"])
        self.assertEqual(excerpts("success", log), [])

    def test_real_failure_fourth_mode_and_directory_binding_negative(self):
        fixture = self.directory / "package"
        fixture.mkdir()
        package = fixture / "ci-results"
        package.mkdir()
        (package / "xcodebuild.log").write_text("Injected Mac build failure.\n")
        run = run_fixture("macBuild")
        env = dict(os.environ, CI_PROCESS_VERSION="v0.10", PROJECT_NAME="ChronoFocus",
                   GITHUB_REF_NAME="main", GITHUB_SHA=SHA, GITHUB_RUN_ID=str(run["id"]),
                   GITHUB_RUN_ATTEMPT=str(run["run_attempt"]), GITHUB_WORKFLOW=review.WORKFLOW_NAME,
                   MAC_SCHEME="ChronoFocusMac", MAC_DESTINATION="generic/platform=macOS",
                   IOS_SCHEME="ChronoFocus", IOS_DESTINATION="generic/platform=iOS", FAILURE_INJECTION="macBuild",
                   CHECKOUT_OUTCOME="success", PREPARE_METADATA_OUTCOME="success", SCAFFOLD_OUTCOME="success",
                   SELECT_XCODE_OUTCOME="success", STATIC_OUTCOME="success", PROJECT_VERIFY_OUTCOME="success",
                   BUILD_OUTCOME="failure", IOS_BUILD_OUTCOME="success", CREATE_MANIFEST_OUTCOME="success",
                   ENSURE_RESULT_PACKAGE_OUTCOME="failure")
        with (self.directory / "recovery.log").open("xb") as output:
            subprocess.run(["python3", str(ROOT / "scripts/recover_ci_result_package.py")], cwd=fixture,
                           env=env, stdout=output, stderr=subprocess.STDOUT, check=True, timeout=60)
        archive = self.directory / "failure.zip"
        with zipfile.ZipFile(archive, "x", compression=zipfile.ZIP_DEFLATED) as output:
            for path in sorted(package.rglob("*")):
                if path.is_file():
                    output.write(path, path.relative_to(package).as_posix())
        metadata = metadata_fixture(run, archive.read_bytes(), fallback=True)
        write_json(self.directory / "run-api.json", run)
        write_json(self.directory / "artifacts-api.json", metadata)
        artifact = metadata["artifacts"][0]
        review.check_zip(archive, artifact)
        extracted = self.directory / "extracted"
        review.extract_zip(archive, extracted)
        command = review.validator_command(ROOT, extracted, archive, artifact, run, "controlled-failure", self.directory)
        positive = subprocess.run(command, capture_output=True, text=True, timeout=120)
        (self.directory / "validator-positive.log").write_text(positive.stdout + positive.stderr)
        self.assertEqual(positive.returncode, 0, positive.stdout + positive.stderr)
        for flag in ("--archive", "--archive-size", "--archive-digest", "--artifact-metadata", "--run-metadata"):
            incomplete = list(command)
            index = incomplete.index(flag)
            del incomplete[index:index + 2]
            result = subprocess.run(incomplete, capture_output=True, text=True, timeout=30)
            (self.directory / f"missing-{flag[2:]}.log").write_text(result.stdout + result.stderr)
            self.assertNotEqual(result.returncode, 0, flag)
        # Same-length mutation isolates directory binding and leaves API ZIP identity intact.
        (extracted / "xcodebuild.log").write_text("Injected Mac build failure!\n")
        negative = subprocess.run(command, capture_output=True, text=True, timeout=120)
        (self.directory / "validator-binding-negative.log").write_text(negative.stdout + negative.stderr)
        self.assertNotEqual(negative.returncode, 0)
        failures = re.findall(r"^FAIL ([^\n]+)", negative.stdout, re.MULTILINE)
        self.assertEqual(len(failures), 1, negative.stdout + negative.stderr)
        self.assertTrue(failures[0].startswith("failure artifact archive extracted directory binding"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
