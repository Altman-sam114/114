#!/usr/bin/env python3
"""Cloud-only, fail-closed review of an independently completed source run.

Never execute extracted files. The validator comes from the gated source checkout.
Raw API responses and failed download attempts remain outside the extracted tree.
"""

import argparse
import ctypes
from datetime import datetime, timedelta
import hashlib
import json
import os
from pathlib import Path
import re
import resource
import stat
import subprocess
import sys
import time
import zipfile


REPOSITORY = "Altman-sam114/114"
ACTOR = "Altman-sam114"
WORKFLOW_NAME = "ChronoFocus CI Results"
WORKFLOW_PATH = ".github/workflows/ci-results.yml"
RUN_NAME = "ChronoFocus CI Results [failure_mode=${{ github.event_name == 'workflow_dispatch' && inputs.failure_mode || 'none' }}]"
INJECTIONS = {
    "checkout": ("Checkout", "Controlled failure injection: checkout"),
    "prepareMetadata": ("Prepare result metadata", "Controlled failure injection: prepareMetadata"),
    "selectXcode": ("Select Xcode", "Controlled failure injection: selectXcode"),
    "projectVerification": ("Project verification", "Injected project verification failure."),
    "macBuild": ("Build ChronoFocusMac", "Injected Mac build failure."),
    "iosBuild": ("Build ChronoFocus iOS", "Injected iOS build failure."),
}
MAX_JSON = 1024 * 1024
MAX_ZIP = 256 * 1024 * 1024
MAX_EXPANDED = 512 * 1024 * 1024
MAX_FILE = 128 * 1024 * 1024
MAX_ENTRIES = 20000


class Rejected(RuntimeError):
    pass


class Stale(Rejected):
    pass


def require(condition, message):
    if not condition:
        raise Rejected(message)


def positive_int(value):
    return type(value) is int and value > 0


def limit_output_file_size(limit):
    resource.setrlimit(resource.RLIMIT_FSIZE, (limit, limit))


def regular_file(path, limit):
    info = path.lstat()
    require(stat.S_ISREG(info.st_mode) and 0 < info.st_size <= limit,
            f"Non-regular, empty or oversized evidence: {path.name}")
    return info.st_size


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def read_json(path):
    regular_file(path, MAX_JSON)
    return json.loads(path.read_bytes(), object_pairs_hook=unique_object)


def promote(part, final):
    """Atomic no-replace rename on both the Linux review and macOS fixture runners."""
    require(part.parent == final.parent, "Evidence promotion must stay on one filesystem")
    library = ctypes.CDLL(None, use_errno=True)
    if sys.platform == "darwin":
        rename = library.renamex_np
        rename.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_uint]
        args = [os.fsencode(part), os.fsencode(final), 4]  # RENAME_EXCL
    elif sys.platform.startswith("linux"):
        rename = library.renameat2
        rename.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_int, ctypes.c_char_p, ctypes.c_uint]
        args = [-100, os.fsencode(part), -100, os.fsencode(final), 1]  # RENAME_NOREPLACE
    else:
        raise Rejected("No atomic no-replace rename on this platform")
    rename.restype = ctypes.c_int
    if rename(*args) != 0:
        error = ctypes.get_errno()
        raise OSError(error, os.strerror(error), str(final))


def fetch(endpoint, destination, limit=MAX_JSON, json_response=True):
    require(not os.path.lexists(destination), f"Evidence already exists: {destination}")
    require(positive_int(limit) and limit <= MAX_ZIP, "Invalid transfer size limit")
    # gh api follows the artifact endpoint's redirect. Each failed request has its
    # own exclusive .part and stderr, so bounded retries never overwrite evidence.
    for attempt in range(1, 4):
        suffix = ".part" if attempt == 1 else f".retry-{attempt}.part"
        part = destination.with_name(destination.name + suffix)
        error_path = part.with_name(part.name + ".stderr")
        with part.open("xb") as output, error_path.open("xb") as errors:
            try:
                result = subprocess.run(
                    ["gh", "api", "--hostname", "github.com", endpoint],
                    stdout=output, stderr=errors, timeout=30 if json_response else 120, check=False,
                    preexec_fn=lambda: limit_output_file_size(limit),
                )
                ok = result.returncode == 0
            except subprocess.TimeoutExpired:
                ok = False
        if not ok and (part.stat().st_size >= limit or error_path.stat().st_size >= limit):
            raise Rejected("Transfer size limit reached; child reaped and partial evidence retained")
        if ok:
            regular_file(part, limit)
            if json_response:
                read_json(part)
            # ZIP remains .part until size, digest, CRC and path checks all pass.
            if json_response:
                promote(part, destination)
                return destination
            return part
        if attempt < 3:
            time.sleep(attempt)
    raise Rejected(f"Download failed after 3 attempts: {endpoint}")


def identity(run):
    return tuple(run.get(key) for key in (
        "id", "run_attempt", "head_sha", "head_branch", "name", "path",
        "status", "conclusion", "event", "display_title", "workflow_id",
    )) + tuple(run.get(key, {}).get(field) for key, field in (
        ("repository", "full_name"), ("head_repository", "full_name"),
        ("actor", "login"), ("triggering_actor", "login"),
    ))


def gate(run, event_run, main_sha):
    require(isinstance(run, dict) and isinstance(event_run, dict), "Missing source run")
    require(identity(run) == identity(event_run), "Source API/event identity mismatch (possibly stale attempt)")
    require(positive_int(run.get("id")) and positive_int(run.get("run_attempt"))
            and positive_int(run.get("workflow_id")), "Invalid source run/attempt/workflow id")
    require(re.fullmatch(r"[0-9a-f]{40}", run.get("head_sha", "")) is not None, "Invalid source SHA")
    for key, expected in (("repository", REPOSITORY), ("head_repository", REPOSITORY)):
        require(run.get(key, {}).get("full_name") == expected, f"Unauthorized {key}")
    for key in ("actor", "triggering_actor"):
        require(run.get(key, {}).get("login") == ACTOR, f"Unauthorized {key}")
    require(run.get("name") == WORKFLOW_NAME and run.get("path") == WORKFLOW_PATH,
            "Wrong source workflow name/path")
    require(run.get("head_branch") == "main", "Source branch is not main")
    if run["head_sha"] != main_sha:
        raise Stale("Source SHA is no longer current main")
    require(run.get("status") == "completed", "Source run is not completed")
    if run.get("event") == "push" and run.get("conclusion") == "success":
        require(run.get("display_title") == "ChronoFocus CI Results [failure_mode=none]",
                "Unexpected push registration")
        return "success", "none"
    if run.get("event") == "workflow_dispatch" and run.get("conclusion") == "failure":
        for injection in INJECTIONS:
            if run.get("display_title") == f"ChronoFocus CI Results [failure_mode={injection}]":
                return "controlled-failure", injection
    raise Rejected("Source profile refused: failed push, unregistered dispatch or unsupported conclusion")


def workflow_contract(root):
    # Read the actual gated workflow structurally; Ruby/Psych is already required
    # by the existing validator. YAML 1.1 may decode the GitHub 'on' key as true.
    result = subprocess.run([
        "ruby", "-ryaml", "-rjson", "-e",
        'w = YAML.load_file(ARGV[0]); t = w["on"] || w[true]; '
        'puts JSON.generate({version: w.fetch("env").fetch("CI_PROCESS_VERSION"), '
        'run_name: w.fetch("run-name"), '
        'options: t.fetch("workflow_dispatch").fetch("inputs").fetch("failure_mode").fetch("options")})',
        str(root / WORKFLOW_PATH),
    ], capture_output=True, text=True, check=True, timeout=30)
    contract = json.loads(result.stdout)
    require(contract["run_name"] == RUN_NAME, "Run title is not bound to the trusted dispatch input")
    require(contract["options"] == ["none", *INJECTIONS], "Failure input allowlist drift")
    require(re.fullmatch(r"v\d+\.\d+", contract["version"]) is not None, "Invalid process version")
    return contract


def choose_artifact(metadata, run, profile, version):
    require(isinstance(metadata, dict), "Invalid artifact response")
    artifacts = metadata.get("artifacts")
    require(type(metadata.get("total_count")) is int and metadata["total_count"] == 1
            and isinstance(artifacts, list) and len(artifacts) == 1,
            "Cannot prove a unique, unpaginated source artifact")
    artifact = artifacts[0]
    require(isinstance(artifact, dict), "Invalid artifact entry")
    prefix = f"chronofocus-ci-{version}-main-"
    suffix = f"-run{run['id']}-attempt{run['run_attempt']}"
    names = {prefix + run["head_sha"][:7] + suffix}
    if profile == "controlled-failure":
        names.add(prefix + run["head_sha"] + suffix)
    require(artifact.get("name") in names, "Unexpected source artifact name")
    require(positive_int(artifact.get("id")), "Invalid artifact id")
    require(positive_int(artifact.get("size_in_bytes")) and artifact["size_in_bytes"] <= MAX_ZIP,
            "Invalid or excessive artifact size")
    require(re.fullmatch(r"sha256:[0-9a-f]{64}", artifact.get("digest", "")) is not None,
            "Missing or invalid API digest")
    require(artifact.get("expired") is False, "Artifact is expired or expiry is unknown")
    source = artifact.get("workflow_run", {})
    require(type(source.get("id")) is int and source["id"] == run["id"]
            and source.get("head_sha") == run["head_sha"] and source.get("head_branch") == "main",
            "Artifact/run binding mismatch")
    return artifact


def zip_inventory(path):
    regular_file(path, MAX_ZIP)
    with zipfile.ZipFile(path) as archive:
        entries = archive.infolist()
        require(0 < len(entries) <= MAX_ENTRIES, "Invalid ZIP entry count")
        require(sum(entry.file_size for entry in entries) <= MAX_EXPANDED, "ZIP expansion limit exceeded")
        paths = {}
        for entry in entries:
            raw = entry.orig_filename
            require(raw == entry.filename and "\x00" not in raw and "\\" not in raw,
                    "Unsafe ZIP filename")
            require(not any(ord(char) < 32 or ord(char) == 127 for char in raw), "ZIP control character")
            name = raw[:-1] if entry.is_dir() else raw
            parts = name.split("/")
            require(all(part not in ("", ".", "..") for part in parts)
                    and not re.match(r"^[A-Za-z]:", name), "Unsafe ZIP path")
            require(name not in paths, "Duplicate ZIP path")
            require(not entry.flag_bits & 1, "Encrypted ZIP entry")
            kind = stat.S_IFMT(entry.external_attr >> 16)
            require(kind in (0, stat.S_IFDIR if entry.is_dir() else stat.S_IFREG),
                    "ZIP symlink or special entry")
            require(not entry.is_dir() or entry.file_size == 0, "ZIP directory contains data")
            require(0 <= entry.file_size <= MAX_FILE, "ZIP single-file limit exceeded")
            paths[name] = entry.is_dir()
        for name in paths:
            parents = Path(name).parents
            require(all(str(parent) not in paths or paths[str(parent)] for parent in parents),
                    "ZIP file/directory prefix conflict")
        return entries


def check_zip(part, artifact):
    require(regular_file(part, MAX_ZIP) == artifact["size_in_bytes"], "ZIP/API byte count mismatch")
    digest = hashlib.sha256()
    with part.open("rb") as stream:
        while chunk := stream.read(1024 * 1024):
            digest.update(chunk)
    require("sha256:" + digest.hexdigest() == artifact["digest"], "ZIP/API digest mismatch")
    entries = zip_inventory(part)
    with part.with_name(part.name + ".unzip-test.log").open("xb") as output:
        result = subprocess.run(["unzip", "-t", str(part)], stdout=output,
                                stderr=subprocess.STDOUT, check=False, timeout=60)
    require(result.returncode == 0, "ZIP CRC/integrity check failed")
    return entries


def extract_zip(path, destination):
    entries = zip_inventory(path)
    destination.mkdir(mode=0o700, exist_ok=False)
    with zipfile.ZipFile(path) as archive:
        for entry in entries:
            target = destination / entry.filename
            if entry.is_dir():
                target.mkdir(parents=True, exist_ok=True)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                with archive.open(entry) as source, target.open("xb") as output:
                    written = 0
                    while chunk := source.read(1024 * 1024):
                        written += len(chunk)
                        require(written <= entry.file_size and written <= MAX_FILE,
                                "ZIP streaming extraction exceeded declared size")
                        output.write(chunk)
                    require(written == entry.file_size, "ZIP extracted byte count mismatch")


def timestamp(value):
    require(isinstance(value, str) and re.fullmatch(r"\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?Z", value),
            "Missing or invalid step/log timestamp")
    return datetime.fromisoformat(value[:-1] + "+00:00")


def step_window(step):
    start = timestamp(step.get("started_at"))
    end = timestamp(step.get("completed_at"))
    require(end >= start, "Reversed step execution window")
    # GitHub jobs timestamps are usually whole seconds. Include that final
    # second, but never the following one; fractional timestamps stay precise.
    resolution = timedelta(microseconds=1) if "." in step["completed_at"] else timedelta(seconds=1)
    return start, end + resolution


def executed_step(job, name):
    steps = [step for step in job.get("steps", []) if step.get("name") == name]
    require(len(steps) == 1 and steps[0].get("status") == "completed"
            and steps[0].get("conclusion") in ("success", "failure")
            and positive_int(steps[0].get("number")), "Injected job step was not uniquely executed")
    step_window(steps[0])
    return steps[0]


def emitted_in_step(lines, pattern, step):
    start, end = step_window(step)
    for line in lines:
        stamp, separator, message = line.partition(" ")
        if separator and re.fullmatch(pattern, message) and start <= timestamp(stamp) < end:
            return True
    return False


def controlled_evidence(extracted, run, injection, jobs, log_path):
    stage = read_json(extracted / "ci-stage-outcomes.json")
    require(stage.get("failureMode") == injection, "Package injection differs from external registration")
    require(stage.get("stageOutcomeMap", {}).get(injection) == "failure",
            "Registered injected stage did not fail")
    job = select_job(jobs, run, injection)
    regular_file(log_path, MAX_ZIP)
    marker = INJECTIONS[injection][1]
    lines = log_path.read_text(encoding="utf-8", errors="replace").splitlines()
    target = executed_step(job, INJECTIONS[injection][0])
    witness = executed_step(job, "Bootstrap result package") if injection == "checkout" else target
    # Match only emitted output, not the echoed printf command, and bind it to
    # the exact jobs API step window rather than searching the entire job.
    require(emitted_in_step(lines, re.escape(marker), witness),
            "Missing emitted injection marker in its registered step window")
    if injection == "checkout":
        require(target["number"] < witness["number"]
                and timestamp(target["completed_at"]) <= timestamp(witness["started_at"]),
                "Checkout witness must follow the failed checkout")
        error = r"(?:##\[error\])?fatal: couldn't find remote ref refs/heads/__chronofocus_controlled_checkout_failure__"
        require(emitted_in_step(lines, error, target), "Missing real injected-ref checkout error in Checkout window")
    return job


def select_job(metadata, run, injection):
    require(isinstance(metadata, dict), "Invalid jobs API response")
    jobs = metadata.get("jobs")
    require(type(metadata.get("total_count")) is int and metadata["total_count"] == 1
            and isinstance(jobs, list) and len(jobs) == 1, "Cannot prove unique source job")
    job = jobs[0]
    require(positive_int(job.get("id")) and job.get("run_id") == run["id"]
            and job.get("run_attempt") == run["run_attempt"] and job.get("head_sha") == run["head_sha"]
            and job.get("head_branch") == "main" and job.get("status") == "completed"
            and job.get("conclusion") == "failure", "Job/run identity mismatch")
    # continue-on-error can expose conclusion=success in the jobs API. Neither
    # value proves injection: the stage outcome and emitted marker are mandatory.
    executed_step(job, INJECTIONS[injection][0])
    return job


def validator_command(root, extracted, archive, artifact, run, profile, evidence):
    require(profile in ("success", "controlled-failure"), "Unknown review profile")
    require(gate(run, run, run["head_sha"])[0] == profile, "Validator profile does not match source registration")
    # All formal modes require all package-external parameters. Never retry with
    # weaker arguments or switch to failure mode after a rejected success run.
    command = [
        "ruby", str(root / "scripts/validate_ci_artifact.rb"), str(extracted),
        "--commit", run["head_sha"], "--run-id", str(run["id"]),
        "--attempt", str(run["run_attempt"]), "--branch", "main",
        "--expected-event", "push" if profile == "success" else "workflow_dispatch",
        "--archive", str(archive), "--archive-size", str(artifact["size_in_bytes"]),
        "--archive-digest", artifact["digest"],
        "--artifact-metadata", str(evidence / "artifacts-api.json"),
        "--run-metadata", str(evidence / "run-api.json"),
    ]
    if profile == "controlled-failure":
        command.append("--failure-mode")
    return command


def recheck(evidence, run, label):
    current = read_json(fetch(f"repos/{REPOSITORY}/actions/runs/{run['id']}", evidence / f"{label}-run-api.json"))
    main = read_json(fetch(f"repos/{REPOSITORY}/commits/main", evidence / f"{label}-main-api.json"))
    if identity(current) != identity(run) or main.get("sha") != run["head_sha"]:
        raise Stale("Main SHA or source run/attempt changed during review")


def review(evidence, event_path, root, report):
    event = read_json(event_path)
    require(event.get("action") == "completed" and event.get("repository", {}).get("full_name") == REPOSITORY,
            "Wrong workflow_run envelope")
    run = read_json(evidence / "run-api.json")
    main = read_json(evidence / "main-api.json")
    profile, injection = gate(run, event.get("workflow_run"), main.get("sha"))
    report.update(source_run=run["id"], source_attempt=run["run_attempt"], source_sha=run["head_sha"],
                  profile=profile, injection=injection)
    checkout = subprocess.run(["git", "rev-parse", "HEAD"], cwd=root, capture_output=True,
                              text=True, check=True, timeout=30).stdout.strip()
    require(checkout == run["head_sha"], "Validator checkout is not the gated source SHA")
    contract = workflow_contract(root)
    recheck(evidence, run, "before-download")
    metadata = read_json(fetch(f"repos/{REPOSITORY}/actions/runs/{run['id']}/artifacts",
                               evidence / "artifacts-api.json"))
    artifact = choose_artifact(metadata, run, profile, contract["version"])
    report["artifact"] = {key: artifact[key] for key in ("id", "name", "size_in_bytes", "digest")}
    archive = evidence / (artifact["name"] + ".zip")
    part = fetch(f"repos/{REPOSITORY}/actions/artifacts/{artifact['id']}/zip", archive,
                 limit=artifact["size_in_bytes"], json_response=False)
    check_zip(part, artifact)
    promote(part, archive)
    extracted = evidence / "extracted"
    extract_zip(archive, extracted)
    if profile == "controlled-failure":
        jobs = read_json(fetch(f"repos/{REPOSITORY}/actions/runs/{run['id']}/attempts/{run['run_attempt']}/jobs",
                               evidence / "jobs-api.json"))
        job = select_job(jobs, run, injection)
        log_path = evidence / "source-job.log"
        log_part = fetch(f"repos/{REPOSITORY}/actions/jobs/{job['id']}/logs", log_path,
                         limit=MAX_ZIP, json_response=False)
        promote(log_part, log_path)
        controlled_evidence(extracted, run, injection, jobs, log_path)
    command = validator_command(root, extracted, archive, artifact, run, profile, evidence)
    with (evidence / "validator-command.json").open("x") as output:
        json.dump(command, output)
    with (evidence / "validator.log").open("xb") as output:
        result = subprocess.run(command, cwd=root, stdout=output, stderr=subprocess.STDOUT,
                                check=False, timeout=600)
    report["validator_exit"] = result.returncode
    log = (evidence / "validator.log").read_text(encoding="utf-8", errors="replace")
    report["validator_pass"] = len(re.findall(r"^PASS ", log, re.MULTILINE))
    report["validator_fail"] = len(re.findall(r"^FAIL ", log, re.MULTILINE))
    recheck(evidence, run, "final")
    require(result.returncode == 0 and report["validator_pass"] > 0 and report["validator_fail"] == 0,
            "Fourth-mode validator rejected the artifact")
    report["conclusion"] = ("success: product acceptance passed" if profile == "success" else
                            "controlled failure: evidence chain passed; product NOT accepted")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--event", type=Path, required=True)
    parser.add_argument("--checkout", type=Path, required=True)
    args = parser.parse_args()
    require(args.evidence.is_dir() and not args.evidence.is_symlink(), "Invalid evidence directory")
    report = {"review_run": os.environ.get("GITHUB_RUN_ID"),
              "review_attempt": os.environ.get("GITHUB_RUN_ATTEMPT"),
              "profile": "unverified", "validator_exit": None, "conclusion": "rejected"}
    exit_code = 1
    try:
        review(args.evidence, args.event, args.checkout.resolve(), report)
        exit_code = 0
    except Exception as error:
        report["conclusion"] = "stale" if isinstance(error, Stale) else "rejected/returned"
        report["reason"] = str(error)
    with (args.evidence / "review-result.json").open("x", encoding="utf-8") as output:
        json.dump(report, output, indent=2)
        output.write("\n")
    summary = "## Independent Artifact Review\n\n```json\n" + json.dumps(report, indent=2) + "\n```\n"
    with (args.evidence / "review-summary.md").open("x", encoding="utf-8") as output:
        output.write(summary)
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with Path(os.environ["GITHUB_STEP_SUMMARY"]).open("a", encoding="utf-8") as output:
            output.write(summary)
    print(summary)
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
