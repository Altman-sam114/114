#!/usr/bin/env ruby
# frozen_string_literal: true

# This file is loaded only by validate_ci_artifact.rb's explicit failure profile.
# It intentionally shares the main validator's archive and metadata helpers.

def failure_profile_json(path)
  return nil unless File.file?(path)

  JSON.parse(File.read(path, encoding: "UTF-8"))
rescue JSON::ParserError, EncodingError, ArgumentError, SystemCallError
  nil
end

def validate_failure_profile(
  options:, artifact_dir:, archive_path:, expected_archive_size:, expected_archive_digest:, artifact_metadata_path:, run_metadata_path:
)
  checks = []
  branch_slug = options["branch"].gsub("/", "-")
  short_sha = options["commit"][0, 7]
  normal_artifact_name = "chronofocus-ci-#{EXPECTED_CI_PROCESS_VERSION}-#{branch_slug}-#{short_sha}-run#{options["run_id"]}-attempt#{options["attempt"]}"
  fallback_artifact_name = "chronofocus-ci-#{EXPECTED_CI_PROCESS_VERSION}-#{branch_slug}-#{options["commit"]}-run#{options["run_id"]}-attempt#{options["attempt"]}"
  allowed_artifact_names = [normal_artifact_name, fallback_artifact_name]

  manifest_path = File.join(artifact_dir, "ci-artifact-manifest.json")
  index_path = File.join(artifact_dir, "ci-artifact-index.json")
  junit_path = File.join(artifact_dir, "junit.xml")
  summary_path = File.join(artifact_dir, "ci-failure-summary.md")
  context_path = File.join(artifact_dir, "ci-run-context.txt")
  stage_path = File.join(artifact_dir, "ci-stage-outcomes.json")
  manifest = failure_profile_json(manifest_path)
  index = failure_profile_json(index_path)
  stage_file = failure_profile_json(stage_path)
  context_entries = read_key_value_entries(context_path)
  context = context_entries.to_h
  summary = File.file?(summary_path) ? File.read(summary_path, encoding: "UTF-8") : ""
  junit =
    if File.file?(junit_path)
      begin
        REXML::Document.new(File.read(junit_path, encoding: "UTF-8")).root
      rescue REXML::ParseException, EncodingError, SystemCallError
        nil
      end
    end

  stage_names = EXPECTED_STAGE_NAMES
  package_stage_names = EXPECTED_PACKAGE_STAGE_NAMES
  execution_stage_names = %w[
    checkout prepareMetadata bootstrap selectXcode staticChecks projectVerification
    macBuild iosBuild createManifest ensureResultPackage
  ]
  stage_entries = stage_file.is_a?(Hash) && stage_file["stages"].is_a?(Array) ? stage_file["stages"] : []
  stage_by_name = stage_entries.each_with_object({}) { |entry, lookup| lookup[entry["name"]] = entry["outcome"] }
  non_success_stages = stage_names.select { |name| stage_by_name[name] != "success" }
  failed_stages = stage_names.select { |name| %w[failure cancelled unknown].include?(stage_by_name[name]) }
  package_stage_entries = stage_file.is_a?(Hash) && stage_file["packageStages"].is_a?(Array) ? stage_file["packageStages"] : []
  package_stage_by_name = package_stage_entries.each_with_object({}) { |entry, lookup| lookup[entry["name"]] = entry["outcome"] }
  non_success_package_stages = package_stage_names.select { |name| package_stage_by_name[name] != "success" }
  failed_package_stages = package_stage_names.select { |name| %w[failure cancelled unknown].include?(package_stage_by_name[name]) }
  ensure_result_package_outcome = stage_file.is_a?(Hash) ? stage_file["ensureResultPackageOutcome"] : nil
  recovery_outcome = stage_file.is_a?(Hash) ? stage_file["recoveryOutcome"] : nil
  outcome_by_name = stage_by_name.merge(package_stage_by_name).merge("ensureResultPackage" => ensure_result_package_outcome)
  all_non_success_stages = execution_stage_names.select { |name| outcome_by_name[name] != "success" }
  all_failed_stages = execution_stage_names.select { |name| %w[failure cancelled unknown].include?(outcome_by_name[name]) }
  expected_first_failed_stage = all_failed_stages.first || all_non_success_stages.first
  expected_index_paths = EXPECTED_INDEX_ENTRIES.keys.sort
  prepare_metadata_failed = stage_by_name["prepareMetadata"] != "success"
  failure_only_paths = prepare_metadata_failed ? FAILURE_ONLY_INDEX_ENTRIES.keys : []
  allowed_index_paths = [expected_index_paths, (expected_index_paths + failure_only_paths).sort]
  required_paths = FAILURE_REQUIRED_ARTIFACT_PATHS.map { |path| "ci-results/#{path}" }
  expected_required_paths = required_paths

  check(checks, "failure artifact archive byte count") do
    archive_path && File.size(archive_path) == expected_archive_size
  end
  check(checks, "failure artifact archive sha256 digest") do
    archive_path && "sha256:#{Digest::SHA256.file(archive_path).hexdigest}" == expected_archive_digest
  end
  archive_zip_integrity_ok = false
  check(checks, "failure artifact archive zip integrity") do
    stdout, stderr, status = Open3.capture3("unzip", "-t", archive_path)
    unless status.success?
      detail = [stderr, stdout].map(&:strip).reject(&:empty?).join(" | ")
      raise(detail.empty? ? "unzip -t exited with status #{status.exitstatus}" : detail[0, 500])
    end

    zip_parse_archive(archive_path)
    archive_zip_integrity_ok = true
    true
  end
  archive_integrity_ok =
    archive_path &&
    File.size(archive_path) == expected_archive_size &&
    "sha256:#{Digest::SHA256.file(archive_path).hexdigest}" == expected_archive_digest &&
    archive_zip_integrity_ok
  check(checks, "failure artifact archive extracted directory binding") do
    validate_archive_extracted_directory_binding(archive_path, artifact_dir, archive_integrity_ok)
  end

  check(checks, "failure artifact required files") do
    expected_required_paths.all? do |path|
      local_path = local_artifact_path(artifact_dir, path)
      File.file?(local_path) && File.size(local_path).positive?
    end
  end
  check(checks, "failure artifact manifest shape") { manifest.is_a?(Hash) }
  check(checks, "failure artifact index shape") { index.is_a?(Hash) }
  check(checks, "failure artifact stage outcomes shape") do
    stage_file.is_a?(Hash) && stage_entries.length == stage_names.length
  end
  check(checks, "failure artifact stage names and outcomes") do
    stage_file.is_a?(Hash) && stage_entries.map { |entry| entry["name"] } == stage_names &&
      stage_entries.all? { |entry| EXPECTED_STAGE_OUTCOMES.include?(entry["outcome"]) } &&
      stage_file["stageOutcomeMap"] == stage_entries.each_with_object({}) { |entry, lookup| lookup[entry["name"]] = entry["outcome"] }
  end
  check(checks, "failure artifact stage outcome duplicates") do
    stage_file.is_a?(Hash) &&
      stage_file["stageOutcomes"] == stage_file["stageOutcomeMap"]
  end
  check(checks, "failure artifact package stage outcomes") do
    package_stage_entries.map { |entry| entry["name"] } == package_stage_names &&
      package_stage_entries.all? { |entry| EXPECTED_STAGE_OUTCOMES.include?(entry["outcome"]) }
  end
  check(checks, "failure artifact stage identity") do
    stage_file.is_a?(Hash) &&
      stage_file["version"] == EXPECTED_CI_PROCESS_VERSION &&
      allowed_artifact_names.include?(stage_file["artifactName"]) &&
      stage_file["branch"] == options["branch"] &&
      stage_file["commitSha"] == options["commit"] &&
      stage_file["runId"].to_s == options["run_id"] &&
      stage_file["runAttempt"].to_s == options["attempt"] &&
      iso8601_timestamp?(stage_file["createdAt"])
  end
  check(checks, "failure artifact stage failure state") do
    stage_file.is_a?(Hash) &&
      stage_file["overallOutcome"] == "failure" &&
      all_non_success_stages.any? &&
      all_failed_stages.any? &&
      stage_file["failedStages"] == failed_stages &&
      stage_file["nonSuccessStages"] == non_success_stages &&
      stage_file["failedPackageStages"] == failed_package_stages &&
      stage_file["nonSuccessPackageStages"] == non_success_package_stages &&
      stage_file["firstFailedStage"] == expected_first_failed_stage
  end
  check(checks, "failure artifact finalizer outcome") do
    normal_finalizer = ensure_result_package_outcome == "success" && recovery_outcome == "skipped"
    recovered_finalizer = EXPECTED_STAGE_OUTCOMES.include?(ensure_result_package_outcome) &&
      ensure_result_package_outcome != "success" && recovery_outcome == "success"
    (normal_finalizer || recovered_finalizer) &&
      manifest.is_a?(Hash) && manifest["ensureResultPackageOutcome"] == ensure_result_package_outcome &&
      manifest["recoveryOutcome"] == recovery_outcome
  end
  check(checks, "failure artifact explicit mode") do
    stage_file.is_a?(Hash) && stage_file["failureMode"].is_a?(String) && !stage_file["failureMode"].empty? && stage_file["failureMode"] != "none"
  end
  expected_fallback_used = stage_file.is_a?(Hash) && stage_file["artifactName"] == fallback_artifact_name
  check(checks, "failure artifact fallback identity") do
    stage_file.is_a?(Hash) &&
      stage_file["fallbackArtifactName"] == fallback_artifact_name &&
      stage_file["fallbackArtifactUsed"] == expected_fallback_used
  end

  check(checks, "failure artifact manifest identity") do
    manifest.is_a?(Hash) &&
      manifest["version"] == EXPECTED_CI_PROCESS_VERSION &&
      allowed_artifact_names.include?(manifest["artifactName"]) &&
      manifest["branch"] == options["branch"] &&
      manifest["commitSha"] == options["commit"] &&
      manifest["runId"].to_s == options["run_id"] &&
      manifest["runAttempt"].to_s == options["attempt"] &&
      manifest["shortSha"] == short_sha &&
      iso8601_timestamp?(manifest["createdAt"])
  end
  check(checks, "failure artifact manifest metadata") do
    manifest.is_a?(Hash) && EXPECTED_MANIFEST_METADATA.all? { |key, value| manifest[key] == value }
  end
  check(checks, "failure artifact project reports metadata") do
    reports = manifest.is_a?(Hash) ? manifest["projectSpecificReports"] : nil
    actual_reports = reports.is_a?(Array) ? reports.each_with_object({}) { |report, lookup| lookup[report["name"]] = report["path"] } : {}
    reports.is_a?(Array) && reports.length == EXPECTED_PROJECT_REPORTS.length && actual_reports == EXPECTED_PROJECT_REPORTS &&
      reports.all? do |report|
        EXPECTED_PROJECT_REPORTS[report["name"]] == report["path"] && !report["description"].to_s.empty?
      end
  end
  check(checks, "failure artifact manifest paths") do
    manifest.is_a?(Hash) && EXPECTED_MANIFEST_PATHS.all? { |key, value| manifest[key] == value }
  end
  check(checks, "failure artifact manifest outcomes") do
    manifest.is_a?(Hash) && stage_file.is_a?(Hash) &&
      manifest["overallOutcome"] == "failure" &&
      manifest["stageOutcomesPath"] == "ci-results/ci-stage-outcomes.json" &&
      manifest["failureMode"] == stage_file["failureMode"] &&
      manifest["failedStages"] == failed_stages &&
      manifest["nonSuccessStages"] == non_success_stages &&
      manifest["packageStages"] == package_stage_entries &&
      manifest["failedPackageStages"] == failed_package_stages &&
      manifest["nonSuccessPackageStages"] == non_success_package_stages &&
      manifest["ensureResultPackageOutcome"] == ensure_result_package_outcome &&
      manifest["firstFailedStage"] == expected_first_failed_stage &&
      manifest["stageOutcomes"] == stage_file["stages"] &&
      manifest["stageOutcomeMap"] == stage_file["stageOutcomeMap"] &&
      manifest["staticChecksOutcome"] == stage_by_name["staticChecks"] &&
      manifest["projectVerificationOutcome"] == stage_by_name["projectVerification"] &&
      manifest["macBuildOutcome"] == stage_by_name["macBuild"] &&
      manifest["iosBuildOutcome"] == stage_by_name["iosBuild"] &&
      manifest["buildOutcome"] == stage_by_name["macBuild"] &&
      manifest["testOutcome"] == stage_by_name["projectVerification"]
  end
  check(checks, "failure artifact manifest fallback identity") do
    manifest.is_a?(Hash) &&
      manifest["fallbackArtifactName"] == fallback_artifact_name &&
      manifest["fallbackArtifactUsed"] == expected_fallback_used
  end

  check(checks, "failure artifact run context exact keys") do
    context_entries.map(&:first).sort == EXPECTED_RUN_CONTEXT_KEYS.sort &&
      context_entries.length == EXPECTED_RUN_CONTEXT_KEYS.length
  end
  check(checks, "failure artifact run context identity") do
    context["branch"] == options["branch"] &&
      context["commitSha"] == options["commit"] &&
      context["runId"] == options["run_id"] &&
      context["runAttempt"] == options["attempt"].to_s
  end
  check(checks, "failure artifact run context artifact name") do
    allowed_artifact_names.include?(context["artifactName"]) && context["artifactName"] == manifest["artifactName"]
  end

  entries = index.is_a?(Hash) && index["entries"].is_a?(Array) ? index["entries"] : []
  entries_by_path = entries.each_with_object({}) { |entry, lookup| lookup[entry["path"]] = entry }
  check(checks, "failure artifact index paths") { allowed_index_paths.include?(entries.map { |entry| entry["path"] }.sort) }
  check(checks, "failure artifact index identity") do
    index.is_a?(Hash) &&
      index["version"] == EXPECTED_CI_PROCESS_VERSION &&
      index["artifactName"] == manifest["artifactName"] &&
      index["branch"] == options["branch"] &&
      index["commitSha"] == options["commit"] &&
      index["runId"].to_s == options["run_id"] &&
      index["runAttempt"].to_s == options["attempt"] &&
      iso8601_timestamp?(index["createdAt"])
  end
  check(checks, "failure artifact index outcomes") do
    index.is_a?(Hash) && stage_file.is_a?(Hash) &&
      index["overallOutcome"] == "failure" &&
      index["stageOutcomes"] == stage_file["stages"] &&
      index["failedStages"] == failed_stages &&
      index["nonSuccessStages"] == non_success_stages &&
      index["packageStages"] == package_stage_entries &&
      index["failedPackageStages"] == failed_package_stages &&
      index["nonSuccessPackageStages"] == non_success_package_stages &&
      index["ensureResultPackageOutcome"] == ensure_result_package_outcome &&
      index["recoveryOutcome"] == recovery_outcome &&
      index["stageOutcomeMap"] == stage_file["stageOutcomeMap"] &&
      index["firstFailedStage"] == expected_first_failed_stage
  end
  check(checks, "failure artifact index fallback identity") do
    index.is_a?(Hash) &&
      index["fallbackArtifactName"] == fallback_artifact_name &&
      index["fallbackArtifactUsed"] == expected_fallback_used
  end
  expected_index_totals = {
    "entryCount" => entries.length,
    "missingRequiredCount" => entries.count { |entry| entry["required"] && !entry["exists"] },
    "fileByteCount" => entries.sum { |entry| entry["byteCount"].to_i },
    "directoryRecursiveByteCount" => entries.sum { |entry| entry["recursiveByteCount"].to_i }
  }
  check(checks, "failure artifact index totals") do
    index.is_a?(Hash) && expected_index_totals.all? { |key, value| index.dig("totals", key).to_i == value }
  end
  check(checks, "failure artifact index required entries") do
    actual_required_paths = entries.select { |entry| entry["required"] }.map { |entry| entry["path"] }.sort
    actual_required_paths == expected_required_paths.sort && expected_required_paths.all? do |path|
      entry = entries_by_path[path]
      entry && entry["required"] && entry["exists"] && positive_local_artifact?(artifact_dir, entry)
    end
  end
  check(checks, "failure artifact index optional entries") do
    entries.all? do |entry|
      path = entry["path"]
      next false unless allowed_index_paths.any? { |paths| paths.include?(path) }
      next false unless entry["required"] == expected_required_paths.include?(path)
      next false if entry["required"] && !entry["exists"]
      next true unless entry["exists"]

      metadata = local_artifact_metadata(artifact_dir, entry)
      metadata && metadata["kind"] == entry["kind"] &&
        (entry["kind"] == "file" ? metadata["byteCount"] == entry["byteCount"].to_i : metadata["fileCount"] == entry["fileCount"].to_i && metadata["recursiveByteCount"] == entry["recursiveByteCount"].to_i)
    end
  end
  expected_missing_paths = entries.select { |entry| !entry["required"] && !entry["exists"] }.map { |entry| entry["path"] }.sort
  check(checks, "failure artifact index missing paths") do
    index.is_a?(Hash) && index["missingArtifactPaths"].is_a?(Array) && index["missingArtifactPaths"].sort == expected_missing_paths
  end
  check(checks, "failure artifact missing paths metadata") do
    stage_file.is_a?(Hash) && manifest.is_a?(Hash) && index.is_a?(Hash) &&
      stage_file["missingArtifactPaths"].is_a?(Array) &&
      manifest["missingArtifactPaths"].is_a?(Array) &&
      stage_file["missingArtifactPaths"].sort == expected_missing_paths &&
      manifest["missingArtifactPaths"].sort == expected_missing_paths &&
      index["missingArtifactPaths"].sort == expected_missing_paths
  end
  check(checks, "failure artifact local allowlist") do
    root_allowed = EXPECTED_ARTIFACT_ROOT_ENTRIES + (prepare_metadata_failed ? FAILURE_ONLY_ARTIFACT_ROOT_ENTRIES : [])
    root_extra = File.directory?(artifact_dir) ? Dir.children(artifact_dir) - root_allowed : ["<missing root>"]
    project_reports = File.join(artifact_dir, "project-reports")
    project_extra = File.directory?(project_reports) ? Dir.children(project_reports) - EXPECTED_PROJECT_REPORTS_ENTRIES : []
    snapshots = File.join(project_reports, "mac-snapshots")
    snapshot_extra = File.directory?(snapshots) ? Dir.children(snapshots) - EXPECTED_MAC_SNAPSHOT_ENTRIES : []
    root_extra.empty? && project_extra.empty? && snapshot_extra.empty?
  end

  check(checks, "failure artifact summary") do
      summary.include?("# ChronoFocus CI Failure Summary") &&
      summary.include?("- Overall outcome: `failure`") &&
      summary.include?("- First failed stage: `#{expected_first_failed_stage}`") &&
      summary.include?("## Failed Stages") &&
      summary.include?("## Failure Excerpts") &&
      !summary.include?("All CI stages passed.") &&
      all_non_success_stages.all? { |name| summary.include?("- `#{name}`:") }
  end
  check(checks, "failure artifact summary package outcomes") do
    package_stage_entries.all? do |entry|
      label = entry["name"] == "bootstrap" ? "Bootstrap result package" : "Create manifest"
      summary.include?("- #{label}: `#{entry["outcome"]}`")
    end
  end
  check(checks, "failure artifact summary finalizer outcome") do
    summary.include?("- Ensure result package: `#{ensure_result_package_outcome}`") &&
      summary.include?("- Recovery result package: `#{recovery_outcome}`")
  end
  check(checks, "failure artifact summary stage outcomes") do
    EXPECTED_SUMMARY_STAGE_LABELS.all? do |name, label|
      summary.include?("- #{label}: `#{outcome_by_name[name]}`")
    end
  end
  check(checks, "failure artifact summary identity") do
    [
      "- Version: `#{EXPECTED_CI_PROCESS_VERSION}`",
      "- Branch: `#{options["branch"]}`",
      "- Commit: `#{options["commit"]}`",
      "- Run: `#{options["run_id"]}` attempt `#{options["attempt"]}`"
    ].all? { |line| summary.include?(line) }
  end
  check(checks, "failure artifact summary entries") { EXPECTED_SUMMARY_ENTRIES.all? { |entry| summary.include?(entry) } }

  testcases = junit ? junit.get_elements("testcase") : []
  check(checks, "failure artifact junit metadata") do
    junit &&
      junit.attributes["name"] == EXPECTED_JUNIT_SUITE_NAME &&
      junit.attributes["tests"] == "4" &&
      junit.attributes["errors"] == "0" &&
      testcases.map { |testcase| testcase.attributes["name"] }.sort == EXPECTED_JUNIT_TESTCASES.sort &&
      testcases.all? { |testcase| testcase.attributes["classname"] == EXPECTED_JUNIT_CLASSNAME }
  end
  check(checks, "failure artifact junit outcomes") do
    testcases.all? do |testcase|
      key = EXPECTED_JUNIT_OUTCOMES[testcase.attributes["name"]]
      key && testcase.get_text("system-out").to_s.include?("outcome=#{manifest[key]};")
    end
  end
  check(checks, "failure artifact junit failures") do
    expected_failures = testcases.count { |testcase| manifest[EXPECTED_JUNIT_OUTCOMES[testcase.attributes["name"]]] != "success" }
    junit && junit.attributes["failures"] == expected_failures.to_s && testcases.all? do |testcase|
      outcome = manifest[EXPECTED_JUNIT_OUTCOMES[testcase.attributes["name"]]]
      if outcome == "success"
        testcase.get_elements("failure").empty? && testcase.get_elements("error").empty?
      else
        testcase.get_elements("failure").length == 1 && testcase.get_elements("error").empty?
      end
    end
  end

  artifact_metadata = failure_profile_json(artifact_metadata_path)
  metadata_artifacts = artifact_metadata.is_a?(Hash) ? artifact_metadata["artifacts"] : nil
  metadata_artifact = metadata_artifacts.is_a?(Array) && metadata_artifacts.length == 1 ? metadata_artifacts.first : nil
  metadata_workflow_run = metadata_artifact.is_a?(Hash) ? metadata_artifact["workflow_run"] : nil
  check(checks, "failure artifact metadata response shape") do
    artifact_metadata.is_a?(Hash) && artifact_metadata["total_count"] == 1 && metadata_artifacts.is_a?(Array) && metadata_artifacts.length == 1
  end
  check(checks, "failure artifact metadata identity") do
    metadata_artifact.is_a?(Hash) &&
      metadata_artifact["id"].is_a?(Integer) && metadata_artifact["id"].positive? &&
      metadata_artifact["name"] == manifest["artifactName"] &&
      metadata_artifact["size_in_bytes"] == expected_archive_size &&
      metadata_artifact["digest"].to_s.downcase == expected_archive_digest &&
      metadata_artifact["expired"].equal?(false) &&
      metadata_workflow_run.is_a?(Hash) &&
      metadata_workflow_run["id"].to_s == options["run_id"] &&
      metadata_workflow_run["head_sha"] == options["commit"] &&
      metadata_workflow_run["head_branch"] == options["branch"]
  end

  run_metadata = failure_profile_json(run_metadata_path)
  check(checks, "failure artifact run metadata identity") do
    repository = run_metadata.is_a?(Hash) ? run_metadata["repository"] : nil
    head_repository = run_metadata.is_a?(Hash) ? run_metadata["head_repository"] : nil
    actor = run_metadata.is_a?(Hash) ? run_metadata["actor"] : nil
    triggering_actor = run_metadata.is_a?(Hash) ? run_metadata["triggering_actor"] : nil
    run_metadata.is_a?(Hash) &&
      run_metadata["id"].to_s == options["run_id"] &&
      run_metadata["run_attempt"].to_s == options["attempt"] &&
      run_metadata["head_sha"] == options["commit"] &&
      run_metadata["head_branch"] == options["branch"] &&
      run_metadata["name"] == EXPECTED_WORKFLOW_RUN_NAME &&
      run_metadata["path"] == EXPECTED_WORKFLOW_RUN_PATH &&
      run_metadata["status"] == "completed" &&
      run_metadata["conclusion"] == "failure" &&
      repository.is_a?(Hash) && repository["full_name"] == EXPECTED_WORKFLOW_RUN_REPOSITORY &&
      head_repository.is_a?(Hash) && head_repository["full_name"] == EXPECTED_WORKFLOW_RUN_HEAD_REPOSITORY &&
      actor.is_a?(Hash) && actor["login"] == EXPECTED_WORKFLOW_RUN_ACTOR &&
      triggering_actor.is_a?(Hash) && triggering_actor["login"] == EXPECTED_WORKFLOW_RUN_ACTOR
  end
  check(checks, "failure artifact run metadata event") do
    run_metadata.is_a?(Hash) &&
      run_metadata["event"].is_a?(String) &&
      run_metadata["event"] == options["expected_event"]
  end
  check(checks, "failure artifact stage provenance") do
    run_metadata.is_a?(Hash) && stage_file.is_a?(Hash) &&
      run_metadata["id"].to_s == stage_file["runId"].to_s &&
      run_metadata["head_sha"] == stage_file["commitSha"] &&
      run_metadata["head_branch"] == stage_file["branch"]
  end

  checks
end
