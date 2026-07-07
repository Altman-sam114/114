#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "find"
require "optparse"
require "rexml/document"
require "time"

EXPECTED_CI_PROCESS_VERSION = "v0.10"

EXPECTED_SNAPSHOTS = %w[
  mini-timer.png
  detail-timer.png
  detail-schedule.png
  detail-analytics.png
  detail-settings.png
].freeze

EXPECTED_INDEX_ENTRIES = {
  "ci-results/ci-artifact-manifest.json" => "file",
  "ci-results/ci-artifact-index.json" => "file",
  "ci-results/ci-failure-summary.md" => "file",
  "ci-results/junit.xml" => "file",
  "ci-results/static-checks.log" => "file",
  "ci-results/verify_project.log" => "file",
  "ci-results/xcodebuild.log" => "file",
  "ci-results/ios-xcodebuild.log" => "file",
  "ci-results/xcode-version.log" => "file",
  "ci-results/ci-run-context.txt" => "file",
  "ci-results/ChronoFocusMac.xcresult" => "directory",
  "ci-results/ChronoFocus-iOS.xcresult" => "directory",
  "ci-results/project-reports/mac-snapshots" => "directory",
  "ci-results/project-reports/mac-snapshots/manifest.json" => "file",
  "ci-results/project-reports/mac-snapshots/mini-timer.png" => "file",
  "ci-results/project-reports/mac-snapshots/detail-timer.png" => "file",
  "ci-results/project-reports/mac-snapshots/detail-schedule.png" => "file",
  "ci-results/project-reports/mac-snapshots/detail-analytics.png" => "file",
  "ci-results/project-reports/mac-snapshots/detail-settings.png" => "file"
}.freeze

EXPECTED_MANIFEST_PATHS = {
  "resultBundlePath" => "ci-results/ChronoFocusMac.xcresult",
  "macResultBundlePath" => "ci-results/ChronoFocusMac.xcresult",
  "iosResultBundlePath" => "ci-results/ChronoFocus-iOS.xcresult",
  "junitPath" => "ci-results/junit.xml",
  "buildLogPath" => "ci-results/xcodebuild.log",
  "macBuildLogPath" => "ci-results/xcodebuild.log",
  "iosBuildLogPath" => "ci-results/ios-xcodebuild.log",
  "failureSummaryPath" => "ci-results/ci-failure-summary.md",
  "artifactIndexPath" => "ci-results/ci-artifact-index.json"
}.freeze

EXPECTED_MANIFEST_METADATA = {
  "workflowName" => "ChronoFocus CI Results",
  "projectName" => "ChronoFocus",
  "scheme" => "ChronoFocusMac",
  "destination" => "generic/platform=macOS",
  "macScheme" => "ChronoFocusMac",
  "macDestination" => "generic/platform=macOS",
  "iosScheme" => "ChronoFocus",
  "iosDestination" => "generic/platform=iOS"
}.freeze

EXPECTED_PROJECT_REPORTS = {
  "artifact_index" => "ci-results/ci-artifact-index.json",
  "verify_project_log" => "ci-results/verify_project.log",
  "mac_snapshots" => "ci-results/project-reports/mac-snapshots",
  "mac_snapshot_manifest" => "ci-results/project-reports/mac-snapshots/manifest.json",
  "ios_xcodebuild_log" => "ci-results/ios-xcodebuild.log",
  "ios_xcode_result" => "ci-results/ChronoFocus-iOS.xcresult",
  "xcode_version" => "ci-results/xcode-version.log"
}.freeze

EXPECTED_SUMMARY_ENTRIES = [
  "Static checks: `ci-results/static-checks.log`",
  "Project verification: `ci-results/verify_project.log`",
  "Mac build: `ci-results/xcodebuild.log`",
  "Xcode result bundle: `ci-results/ChronoFocusMac.xcresult`",
  "iOS build: `ci-results/ios-xcodebuild.log`",
  "iOS Xcode result bundle: `ci-results/ChronoFocus-iOS.xcresult`",
  "Mac snapshots: `ci-results/project-reports/mac-snapshots/`"
].freeze

EXPECTED_SUMMARY_OUTCOMES = {
  "Overall outcome" => "overallOutcome",
  "Static checks" => "staticChecksOutcome",
  "Project verification" => "projectVerificationOutcome",
  "Mac build" => "macBuildOutcome",
  "iOS build" => "iosBuildOutcome"
}.freeze

EXPECTED_STATIC_CHECK_MARKERS = [
  "Running committed diff whitespace check...",
  "Running project plist lint...",
  "Running workflow YAML parse check...",
  "yaml ok"
].freeze

EXPECTED_ARTIFACT_ROOT_ENTRIES = %w[
  ci-artifact-manifest.json
  ci-artifact-index.json
  ci-failure-summary.md
  junit.xml
  static-checks.log
  verify_project.log
  xcodebuild.log
  ios-xcodebuild.log
  xcode-version.log
  ci-run-context.txt
  ChronoFocusMac.xcresult
  ChronoFocus-iOS.xcresult
  project-reports
].freeze

EXPECTED_PROJECT_REPORTS_ENTRIES = %w[
  mac-snapshots
].freeze

EXPECTED_MAC_SNAPSHOT_ENTRIES = (["manifest.json"] + EXPECTED_SNAPSHOTS).freeze

EXPECTED_JUNIT_SUITE_NAME = "ChronoFocus CI Results"
EXPECTED_JUNIT_CLASSNAME = "ChronoFocusCI"

EXPECTED_JUNIT_TESTCASES = %w[
  staticChecks
  projectVerification
  macBuild
  iosBuild
].freeze

EXPECTED_JUNIT_LOGS = {
  "staticChecks" => "ci-results/static-checks.log",
  "projectVerification" => "ci-results/verify_project.log",
  "macBuild" => "ci-results/xcodebuild.log",
  "iosBuild" => "ci-results/ios-xcodebuild.log"
}.freeze

EXPECTED_JUNIT_OUTCOMES = {
  "staticChecks" => "staticChecksOutcome",
  "projectVerification" => "projectVerificationOutcome",
  "macBuild" => "macBuildOutcome",
  "iosBuild" => "iosBuildOutcome"
}.freeze

EXPECTED_OUTCOME_KEYS = %w[
  staticChecksOutcome
  projectVerificationOutcome
  buildOutcome
  macBuildOutcome
  iosBuildOutcome
  testOutcome
].freeze

EXPECTED_OVERALL_OUTCOME_SOURCE_KEYS = %w[
  staticChecksOutcome
  projectVerificationOutcome
  macBuildOutcome
  iosBuildOutcome
].freeze

EXPECTED_RUN_CONTEXT_KEYS = %w[
  artifactName
  branch
  commitSha
  runId
  runAttempt
].freeze

options = {
  "branch" => "main"
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby scripts/validate_ci_artifact.rb ARTIFACT_DIR --commit SHA --run-id ID --attempt N [--branch main]"
  opts.on("--commit SHA", "Expected commit SHA") { |value| options["commit"] = value }
  opts.on("--run-id ID", "Expected GitHub Actions run id") { |value| options["run_id"] = value }
  opts.on("--attempt N", "Expected GitHub Actions run attempt") { |value| options["attempt"] = value }
  opts.on("--branch NAME", "Expected branch name, default main") { |value| options["branch"] = value }
end

parser.parse!

artifact_arg = ARGV.shift
missing_args = []
missing_args << "ARTIFACT_DIR" unless artifact_arg
missing_args << "--commit" unless options["commit"]
missing_args << "--run-id" unless options["run_id"]
missing_args << "--attempt" unless options["attempt"]

unless missing_args.empty?
  warn "#{parser}\nMissing required argument(s): #{missing_args.join(", ")}"
  exit 2
end

def resolve_artifact_dir(path)
  expanded = File.expand_path(path)
  return expanded if File.file?(File.join(expanded, "ci-artifact-manifest.json"))

  children = Dir.children(expanded)
                .map { |child| File.join(expanded, child) }
                .select { |child| File.directory?(child) && File.file?(File.join(child, "ci-artifact-manifest.json")) }
  return children.first if children.length == 1

  raise "Artifact directory must contain ci-artifact-manifest.json or exactly one artifact child directory"
end

def read_json(path)
  JSON.parse(File.read(path, encoding: "UTF-8"))
end

def read_key_values(path)
  read_key_value_entries(path).to_h
end

def read_key_value_entries(path)
  return [] unless File.file?(path)

  File.readlines(path, encoding: "UTF-8").each_with_object([]) do |line, values|
    stripped = line.strip
    next if stripped.empty? || !stripped.include?("=")

    key, value = stripped.split("=", 2)
    values << [key, value]
  end
end

def check(checks, name)
  checks << [name, yield]
rescue StandardError => e
  checks << [name, false, e.message]
end

def local_artifact_path(artifact_dir, contract_path)
  relative_path = contract_path.sub(%r{\Aci-results/}, "")
  File.join(artifact_dir, relative_path)
end

def positive_local_artifact?(artifact_dir, entry)
  path = local_artifact_path(artifact_dir, entry.fetch("path"))
  case entry["kind"]
  when "file"
    File.file?(path) && File.size(path).positive?
  when "directory"
    File.directory?(path) && Dir.children(path).any? &&
      Dir.glob(File.join(path, "**", "*")).any? { |child| File.file?(child) && File.size(child).positive? }
  else
    false
  end
end

def local_artifact_metadata(artifact_dir, entry)
  path = local_artifact_path(artifact_dir, entry.fetch("path"))
  case entry["kind"]
  when "file"
    return nil unless File.file?(path)

    { "kind" => "file", "byteCount" => File.size(path) }
  when "directory"
    return nil unless File.directory?(path)

    file_count = 0
    recursive_byte_count = 0
    Find.find(path) do |child|
      next unless File.file?(child)

      file_count += 1
      recursive_byte_count += File.size(child)
    end
    { "kind" => "directory", "fileCount" => file_count, "recursiveByteCount" => recursive_byte_count }
  end
end

def unexpected_entries(path, expected_names)
  return ["<missing:#{path}>"] unless File.directory?(path)

  Dir.children(path) - expected_names
end

def iso8601_timestamp?(value)
  return false if value.to_s.empty?

  Time.iso8601(value)
  true
rescue ArgumentError
  false
end

begin
artifact_dir = resolve_artifact_dir(artifact_arg)
checks = []

manifest_path = File.join(artifact_dir, "ci-artifact-manifest.json")
index_path = File.join(artifact_dir, "ci-artifact-index.json")
junit_path = File.join(artifact_dir, "junit.xml")
summary_path = File.join(artifact_dir, "ci-failure-summary.md")
context_path = File.join(artifact_dir, "ci-run-context.txt")
static_checks_log_path = File.join(artifact_dir, "static-checks.log")
verify_log_path = File.join(artifact_dir, "verify_project.log")
mac_build_log_path = File.join(artifact_dir, "xcodebuild.log")
ios_build_log_path = File.join(artifact_dir, "ios-xcodebuild.log")
xcode_version_log_path = File.join(artifact_dir, "xcode-version.log")
snapshot_manifest_path = File.join(artifact_dir, "project-reports", "mac-snapshots", "manifest.json")

manifest = read_json(manifest_path)
index = read_json(index_path)
run_context = read_key_values(context_path)
run_context_entries = read_key_value_entries(context_path)
snapshot_manifest = read_json(snapshot_manifest_path)
junit = REXML::Document.new(File.read(junit_path, encoding: "UTF-8")).root
branch_slug = options["branch"].gsub("/", "-")
short_sha = options["commit"][0, 7]
expected_artifact_name = "chronofocus-ci-#{EXPECTED_CI_PROCESS_VERSION}-#{branch_slug}-#{short_sha}-run#{options["run_id"]}-attempt#{options["attempt"]}"

check(checks, "artifact dir exists") { File.directory?(artifact_dir) }
check(checks, "manifest branch") { manifest["branch"] == options["branch"] }
check(checks, "manifest commit") { manifest["commitSha"] == options["commit"] }
check(checks, "manifest run") { manifest["runId"] == options["run_id"] }
check(checks, "manifest attempt") { manifest["runAttempt"] == options["attempt"].to_s }
check(checks, "manifest short sha") { manifest["shortSha"] == short_sha }
check(checks, "ci process version") do
  manifest["version"] == EXPECTED_CI_PROCESS_VERSION &&
    index["version"] == EXPECTED_CI_PROCESS_VERSION
end
check(checks, "manifest metadata") do
  EXPECTED_MANIFEST_METADATA.all? { |key, expected_value| manifest[key] == expected_value }
end
check(checks, "manifest created at") { iso8601_timestamp?(manifest["createdAt"]) }
check(checks, "manifest paths") do
  EXPECTED_MANIFEST_PATHS.all? { |key, expected_path| manifest[key] == expected_path }
end
EXPECTED_OUTCOME_KEYS.each do |key|
  check(checks, key) { manifest[key] == "success" }
end
check(checks, "manifest overall outcome") do
  expected_overall_outcome =
    if EXPECTED_OVERALL_OUTCOME_SOURCE_KEYS.all? { |key| manifest[key] == "success" }
      "success"
    else
      "failure"
    end
  manifest["overallOutcome"] == expected_overall_outcome
end
check(checks, "run context fields") do
  %w[artifactName branch commitSha runId runAttempt].all? { |key| !run_context[key].to_s.empty? }
end
check(checks, "run context exact keys") do
  keys = run_context_entries.map(&:first)
  keys.sort == EXPECTED_RUN_CONTEXT_KEYS.sort &&
    keys.length == EXPECTED_RUN_CONTEXT_KEYS.length
end
check(checks, "run context identity") do
  run_context["branch"] == options["branch"] &&
    run_context["commitSha"] == options["commit"] &&
    run_context["runId"] == options["run_id"] &&
    run_context["runAttempt"] == options["attempt"].to_s
end
check(checks, "run context artifact name") { run_context["artifactName"] == expected_artifact_name }
check(checks, "manifest artifact name") do
  manifest["artifactName"] == expected_artifact_name &&
    manifest["artifactName"] == run_context["artifactName"]
end
check(checks, "index artifact name") do
  index["artifactName"] == expected_artifact_name &&
    index["artifactName"] == manifest["artifactName"] &&
    index["artifactName"] == run_context["artifactName"]
end

entries_by_path = index.fetch("entries").each_with_object({}) do |entry, lookup|
  lookup[entry.fetch("path")] = entry
end
expected_index_totals = {
  "entryCount" => index.fetch("entries").length,
  "missingRequiredCount" => index.fetch("entries").count { |entry| entry["required"] && !entry["exists"] },
  "fileByteCount" => index.fetch("entries").sum { |entry| entry["byteCount"].to_i },
  "directoryRecursiveByteCount" => index.fetch("entries").sum { |entry| entry["recursiveByteCount"].to_i }
}

check(checks, "index branch") { index["branch"] == options["branch"] }
check(checks, "index version") { index["version"] == manifest["version"] }
check(checks, "index commit") { index["commitSha"] == options["commit"] }
check(checks, "index run") { index["runId"] == options["run_id"] }
check(checks, "index attempt") { index["runAttempt"] == options["attempt"].to_s }
check(checks, "index created at") { iso8601_timestamp?(index["createdAt"]) }
check(checks, "index totals consistency") do
  expected_index_totals.all? { |key, value| index.dig("totals", key).to_i == value }
end
check(checks, "index missing required") { index.dig("totals", "missingRequiredCount").to_i.zero? }
check(checks, "index entry count") { index.dig("totals", "entryCount").to_i >= EXPECTED_INDEX_ENTRIES.length }
check(checks, "index unexpected entries") do
  index.fetch("entries").map { |entry| entry.fetch("path") }.sort == EXPECTED_INDEX_ENTRIES.keys.sort
end
check(checks, "index required paths") do
  EXPECTED_INDEX_ENTRIES.all? do |path, expected_kind|
    entry = entries_by_path[path]
    entry && entry["required"] && entry["exists"] && entry["kind"] == expected_kind
  end
end
check(checks, "index required entry sizes") do
  index.fetch("entries").select { |entry| entry["required"] }.all? do |entry|
    next false unless entry["exists"]

    if entry["kind"] == "file"
      entry["byteCount"].to_i.positive?
    elsif entry["kind"] == "directory"
      entry["fileCount"].to_i.positive? && entry["recursiveByteCount"].to_i.positive?
    else
      false
    end
  end
end
check(checks, "index required local artifacts") do
  EXPECTED_INDEX_ENTRIES.keys.all? do |path|
    entry = entries_by_path[path]
    entry && positive_local_artifact?(artifact_dir, entry)
  end
end
check(checks, "index required local metadata") do
  EXPECTED_INDEX_ENTRIES.keys.all? do |path|
    entry = entries_by_path[path]
    metadata = entry && local_artifact_metadata(artifact_dir, entry)
    next false unless metadata && metadata["kind"] == entry["kind"]

    if entry["kind"] == "file"
      metadata["byteCount"] == entry["byteCount"].to_i
    else
      metadata["fileCount"] == entry["fileCount"].to_i &&
        metadata["recursiveByteCount"] == entry["recursiveByteCount"].to_i
    end
  end
end
check(checks, "manifest project reports") do
  reports = manifest["projectSpecificReports"]
  next false unless reports.is_a?(Array) && reports.length == EXPECTED_PROJECT_REPORTS.length

  actual_reports = reports.each_with_object({}) { |report, lookup| lookup[report["name"]] = report["path"] }
  next false unless actual_reports == EXPECTED_PROJECT_REPORTS

  reports.all? do |report|
    name = report["name"]
    path = report["path"]
    entry = entries_by_path[path]

    EXPECTED_PROJECT_REPORTS[name] == path &&
      !report["description"].to_s.empty? &&
      entry &&
      positive_local_artifact?(artifact_dir, entry)
  end
end
check(checks, "unexpected local artifacts") do
  [
    unexpected_entries(artifact_dir, EXPECTED_ARTIFACT_ROOT_ENTRIES),
    unexpected_entries(File.join(artifact_dir, "project-reports"), EXPECTED_PROJECT_REPORTS_ENTRIES),
    unexpected_entries(File.join(artifact_dir, "project-reports", "mac-snapshots"), EXPECTED_MAC_SNAPSHOT_ENTRIES)
  ].all?(&:empty?)
end

check(checks, "junit tests") { junit.attributes["tests"] == "4" }
check(checks, "junit failures") { junit.attributes["failures"] == "0" }
check(checks, "junit errors") { junit.attributes["errors"] == "0" }
testcases = junit.get_elements("testcase")
testcase_names = testcases.map { |testcase| testcase.attributes["name"] }
check(checks, "junit metadata") do
  junit.attributes["name"] == EXPECTED_JUNIT_SUITE_NAME &&
    testcases.all? { |testcase| testcase.attributes["classname"] == EXPECTED_JUNIT_CLASSNAME }
end
check(checks, "junit testcase names") { testcase_names.sort == EXPECTED_JUNIT_TESTCASES.sort }
check(checks, "junit testcase logs") do
  testcases.all? do |testcase|
    expected_log = EXPECTED_JUNIT_LOGS[testcase.attributes["name"]]
    expected_log && testcase.get_text("system-out").to_s.include?("log=#{expected_log}")
  end
end
check(checks, "junit testcase outcomes") do
  testcases.all? do |testcase|
    expected_key = EXPECTED_JUNIT_OUTCOMES[testcase.attributes["name"]]
    expected_key && testcase.get_text("system-out").to_s.include?("outcome=#{manifest[expected_key]};")
  end
end
check(checks, "junit failure elements") do
  testcases.all? do |testcase|
    testcase.get_elements("failure").empty? && testcase.get_elements("error").empty?
  end
end
summary = File.read(summary_path, encoding: "UTF-8")
check(checks, "failure summary") { summary.include?("All CI stages passed.") }
check(checks, "failure summary log entries") do
  EXPECTED_SUMMARY_ENTRIES.all? { |entry| summary.include?(entry) }
end
check(checks, "failure summary identity") do
  [
    "- Version: `#{manifest["version"]}`",
    "- Branch: `#{options["branch"]}`",
    "- Commit: `#{options["commit"]}`",
    "- Run: `#{options["run_id"]}` attempt `#{options["attempt"]}`"
  ].all? { |entry| summary.include?(entry) }
end
check(checks, "failure summary outcomes") do
  EXPECTED_SUMMARY_OUTCOMES.all? do |label, manifest_key|
    summary.include?("- #{label}: `#{manifest[manifest_key]}`")
  end
end
check(checks, "static checks log markers") do
  static_checks_log = File.read(static_checks_log_path, encoding: "UTF-8")
  EXPECTED_STATIC_CHECK_MARKERS.all? { |marker| static_checks_log.include?(marker) }
end
check(checks, "xcode version log") do
  xcode_version_log = File.read(xcode_version_log_path, encoding: "UTF-8")
  xcode_version_log.include?("Xcode") && xcode_version_log.include?("Build version")
end
check(checks, "verify_project core tests") { File.read(verify_log_path, encoding: "UTF-8").include?("Mac core tests passed.") }
check(checks, "verify_project category summary action contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Category summary action contracts verified.")
end
check(checks, "verify_project category accessibility contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Category chip accessibility contracts verified.")
end
check(checks, "verify_project schedule task action accessibility contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Schedule task action accessibility contracts verified.")
end
check(checks, "verify_project plan start action accessibility contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Plan start action accessibility contracts verified.")
end
check(checks, "verify_project plan category badge contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Plan category badge contracts verified.")
end
check(checks, "verify_project mac plan category context contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Mac plan category context contracts verified.")
end
check(checks, "verify_project plan panel action accessibility contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Plan panel action accessibility contracts verified.")
end
check(checks, "verify_project schedule toolbar add category context contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Schedule toolbar add category context contracts verified.")
end
check(checks, "verify_project schedule category empty state action contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Schedule category empty state action contracts verified.")
end
check(checks, "verify_project mac schedule category empty state action contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Mac schedule category empty state action contracts verified.")
end
check(checks, "verify_project mac quick add action accessibility contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Mac quick add action accessibility contracts verified.")
end
check(checks, "verify_project mac quick add title field category context contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Mac quick add title field category context contracts verified.")
end
check(checks, "verify_project category input context contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Category input context contracts verified.")
end
check(checks, "verify_project task editor save category accessibility contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Task editor save category accessibility contracts verified.")
end
check(checks, "verify_project task editor cancel category accessibility contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Task editor cancel category accessibility contracts verified.")
end
check(checks, "verify_project mac mini quick panel accessibility contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Mac mini quick panel accessibility contracts verified.")
end
check(checks, "verify_project analytics category share accessibility contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Analytics category share accessibility contracts verified.")
end
check(checks, "verify_project analytics category share session count contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Analytics category share session count contracts verified.")
end
check(checks, "verify_project analytics category share ranking contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Analytics category share ranking contracts verified.")
end
check(checks, "verify_project analytics category share sort context contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Analytics category share sort context contracts verified.")
end
check(checks, "verify_project analytics category share empty state contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Analytics category share empty state contracts verified.")
end
check(checks, "verify_project analytics category share metadata readability contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Analytics category share metadata readability contracts verified.")
end
check(checks, "verify_project analytics category share percent readability contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Analytics category share percent readability contracts verified.")
end
check(checks, "verify_project analytics recent session category contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Analytics recent session category contracts verified.")
end
check(checks, "verify_project analytics plan review category accessibility contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Analytics plan review category accessibility contracts verified.")
end
check(checks, "verify_project category filter toggle contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Category filter toggle contracts verified.")
end
check(checks, "verify_project current task selection accessibility contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Current task selection accessibility contracts verified.")
end
check(checks, "verify_project timer action accessibility contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Timer action accessibility contracts verified.")
end
check(checks, "verify_project success") { File.read(verify_log_path, encoding: "UTF-8").include?("Project structure verified.") }
check(checks, "mac build succeeded") { File.read(mac_build_log_path, encoding: "UTF-8").include?("** BUILD SUCCEEDED **") }
check(checks, "ios build succeeded") { File.read(ios_build_log_path, encoding: "UTF-8").include?("** BUILD SUCCEEDED **") }

snapshots = snapshot_manifest.fetch("snapshots")
snapshot_names = snapshots.map { |snapshot| snapshot["fileName"] }
check(checks, "snapshot manifest generated at") { iso8601_timestamp?(snapshot_manifest["generatedAt"]) }
check(checks, "snapshot names") { (EXPECTED_SNAPSHOTS - snapshot_names).empty? && snapshots.length == EXPECTED_SNAPSHOTS.length }
check(checks, "snapshot dimensions") do
  snapshots.all? do |snapshot|
    snapshot_path = File.join(artifact_dir, "project-reports", "mac-snapshots", snapshot.fetch("fileName"))
    snapshot["width"].to_i.positive? &&
      snapshot["height"].to_i.positive? &&
      snapshot["byteCount"].to_i.positive? &&
      File.file?(snapshot_path) &&
      File.size(snapshot_path).positive?
  end
end
check(checks, "snapshot byte counts") do
  snapshots.all? do |snapshot|
    snapshot_path = File.join(artifact_dir, "project-reports", "mac-snapshots", snapshot.fetch("fileName"))
    File.file?(snapshot_path) && snapshot["byteCount"].to_i == File.size(snapshot_path)
  end
end

checks.each do |name, ok, detail|
  puts "#{ok ? "PASS" : "FAIL"} #{name}#{detail ? " - #{detail}" : ""}"
end

exit(checks.all? { |_, ok, _| ok } ? 0 : 1)
rescue StandardError => e
  puts "FAIL artifact validation - #{e.message}"
  exit 1
end
