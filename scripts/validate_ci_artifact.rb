#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "optparse"
require "rexml/document"

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

EXPECTED_SUMMARY_ENTRIES = [
  "Static checks: `ci-results/static-checks.log`",
  "Project verification: `ci-results/verify_project.log`",
  "Mac build: `ci-results/xcodebuild.log`",
  "Xcode result bundle: `ci-results/ChronoFocusMac.xcresult`",
  "iOS build: `ci-results/ios-xcodebuild.log`",
  "iOS Xcode result bundle: `ci-results/ChronoFocus-iOS.xcresult`",
  "Mac snapshots: `ci-results/project-reports/mac-snapshots/`"
].freeze

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

EXPECTED_OUTCOME_KEYS = %w[
  staticChecksOutcome
  projectVerificationOutcome
  buildOutcome
  macBuildOutcome
  iosBuildOutcome
  testOutcome
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
  return {} unless File.file?(path)

  File.readlines(path, encoding: "UTF-8").each_with_object({}) do |line, values|
    stripped = line.strip
    next if stripped.empty? || !stripped.include?("=")

    key, value = stripped.split("=", 2)
    values[key] = value
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

begin
artifact_dir = resolve_artifact_dir(artifact_arg)
checks = []

manifest_path = File.join(artifact_dir, "ci-artifact-manifest.json")
index_path = File.join(artifact_dir, "ci-artifact-index.json")
junit_path = File.join(artifact_dir, "junit.xml")
summary_path = File.join(artifact_dir, "ci-failure-summary.md")
context_path = File.join(artifact_dir, "ci-run-context.txt")
verify_log_path = File.join(artifact_dir, "verify_project.log")
mac_build_log_path = File.join(artifact_dir, "xcodebuild.log")
ios_build_log_path = File.join(artifact_dir, "ios-xcodebuild.log")
snapshot_manifest_path = File.join(artifact_dir, "project-reports", "mac-snapshots", "manifest.json")

manifest = read_json(manifest_path)
index = read_json(index_path)
run_context = read_key_values(context_path)
snapshot_manifest = read_json(snapshot_manifest_path)
junit = REXML::Document.new(File.read(junit_path, encoding: "UTF-8")).root
branch_slug = options["branch"].gsub("/", "-")
short_sha = options["commit"][0, 7]
expected_artifact_name = "chronofocus-ci-#{manifest["version"]}-#{branch_slug}-#{short_sha}-run#{options["run_id"]}-attempt#{options["attempt"]}"

check(checks, "artifact dir exists") { File.directory?(artifact_dir) }
check(checks, "manifest branch") { manifest["branch"] == options["branch"] }
check(checks, "manifest commit") { manifest["commitSha"] == options["commit"] }
check(checks, "manifest run") { manifest["runId"] == options["run_id"] }
check(checks, "manifest attempt") { manifest["runAttempt"] == options["attempt"].to_s }
check(checks, "manifest paths") do
  EXPECTED_MANIFEST_PATHS.all? { |key, expected_path| manifest[key] == expected_path }
end
EXPECTED_OUTCOME_KEYS.each do |key|
  check(checks, key) { manifest[key] == "success" }
end
check(checks, "run context fields") do
  %w[artifactName branch commitSha runId runAttempt].all? { |key| !run_context[key].to_s.empty? }
end
check(checks, "run context identity") do
  run_context["branch"] == options["branch"] &&
    run_context["commitSha"] == options["commit"] &&
    run_context["runId"] == options["run_id"] &&
    run_context["runAttempt"] == options["attempt"].to_s
end
check(checks, "run context artifact name") { run_context["artifactName"] == expected_artifact_name }

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
check(checks, "index commit") { index["commitSha"] == options["commit"] }
check(checks, "index run") { index["runId"] == options["run_id"] }
check(checks, "index attempt") { index["runAttempt"] == options["attempt"].to_s }
check(checks, "index totals consistency") do
  expected_index_totals.all? { |key, value| index.dig("totals", key).to_i == value }
end
check(checks, "index missing required") { index.dig("totals", "missingRequiredCount").to_i.zero? }
check(checks, "index entry count") { index.dig("totals", "entryCount").to_i >= EXPECTED_INDEX_ENTRIES.length }
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

check(checks, "junit tests") { junit.attributes["tests"] == "4" }
check(checks, "junit failures") { junit.attributes["failures"] == "0" }
testcases = junit.get_elements("testcase")
testcase_names = testcases.map { |testcase| testcase.attributes["name"] }
check(checks, "junit testcase names") { testcase_names.sort == EXPECTED_JUNIT_TESTCASES.sort }
check(checks, "junit testcase logs") do
  testcases.all? do |testcase|
    expected_log = EXPECTED_JUNIT_LOGS[testcase.attributes["name"]]
    expected_log && testcase.get_text("system-out").to_s.include?("log=#{expected_log}")
  end
end
summary = File.read(summary_path, encoding: "UTF-8")
check(checks, "failure summary") { summary.include?("All CI stages passed.") }
check(checks, "failure summary log entries") do
  EXPECTED_SUMMARY_ENTRIES.all? { |entry| summary.include?(entry) }
end
check(checks, "verify_project core tests") { File.read(verify_log_path, encoding: "UTF-8").include?("Mac core tests passed.") }
check(checks, "verify_project success") { File.read(verify_log_path, encoding: "UTF-8").include?("Project structure verified.") }
check(checks, "mac build succeeded") { File.read(mac_build_log_path, encoding: "UTF-8").include?("** BUILD SUCCEEDED **") }
check(checks, "ios build succeeded") { File.read(ios_build_log_path, encoding: "UTF-8").include?("** BUILD SUCCEEDED **") }

snapshots = snapshot_manifest.fetch("snapshots")
snapshot_names = snapshots.map { |snapshot| snapshot["fileName"] }
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

checks.each do |name, ok, detail|
  puts "#{ok ? "PASS" : "FAIL"} #{name}#{detail ? " - #{detail}" : ""}"
end

exit(checks.all? { |_, ok, _| ok } ? 0 : 1)
rescue StandardError => e
  puts "FAIL artifact validation - #{e.message}"
  exit 1
end
