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

def check(checks, name)
  checks << [name, yield]
rescue StandardError => e
  checks << [name, false, e.message]
end

begin
artifact_dir = resolve_artifact_dir(artifact_arg)
checks = []

manifest_path = File.join(artifact_dir, "ci-artifact-manifest.json")
index_path = File.join(artifact_dir, "ci-artifact-index.json")
junit_path = File.join(artifact_dir, "junit.xml")
summary_path = File.join(artifact_dir, "ci-failure-summary.md")
verify_log_path = File.join(artifact_dir, "verify_project.log")
mac_build_log_path = File.join(artifact_dir, "xcodebuild.log")
ios_build_log_path = File.join(artifact_dir, "ios-xcodebuild.log")
snapshot_manifest_path = File.join(artifact_dir, "project-reports", "mac-snapshots", "manifest.json")

manifest = read_json(manifest_path)
index = read_json(index_path)
snapshot_manifest = read_json(snapshot_manifest_path)
junit = REXML::Document.new(File.read(junit_path, encoding: "UTF-8")).root

check(checks, "artifact dir exists") { File.directory?(artifact_dir) }
check(checks, "manifest branch") { manifest["branch"] == options["branch"] }
check(checks, "manifest commit") { manifest["commitSha"] == options["commit"] }
check(checks, "manifest run") { manifest["runId"] == options["run_id"] }
check(checks, "manifest attempt") { manifest["runAttempt"] == options["attempt"].to_s }
EXPECTED_OUTCOME_KEYS.each do |key|
  check(checks, key) { manifest[key] == "success" }
end

check(checks, "index branch") { index["branch"] == options["branch"] }
check(checks, "index commit") { index["commitSha"] == options["commit"] }
check(checks, "index run") { index["runId"] == options["run_id"] }
check(checks, "index attempt") { index["runAttempt"] == options["attempt"].to_s }
check(checks, "index missing required") { index.dig("totals", "missingRequiredCount").to_i.zero? }
check(checks, "index entry count") { index.dig("totals", "entryCount").to_i >= 19 }
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

check(checks, "junit tests") { junit.attributes["tests"] == "4" }
check(checks, "junit failures") { junit.attributes["failures"] == "0" }
check(checks, "failure summary") { File.read(summary_path, encoding: "UTF-8").include?("All CI stages passed.") }
check(checks, "verify_project core tests") { File.read(verify_log_path, encoding: "UTF-8").include?("Mac core tests passed.") }
check(checks, "verify_project success") { File.read(verify_log_path, encoding: "UTF-8").include?("Project structure verified.") }
check(checks, "mac build succeeded") { File.read(mac_build_log_path, encoding: "UTF-8").include?("** BUILD SUCCEEDED **") }
check(checks, "ios build succeeded") { File.read(ios_build_log_path, encoding: "UTF-8").include?("** BUILD SUCCEEDED **") }

snapshots = snapshot_manifest.fetch("snapshots")
snapshot_names = snapshots.map { |snapshot| snapshot["fileName"] }
check(checks, "snapshot names") { (EXPECTED_SNAPSHOTS - snapshot_names).empty? && snapshots.length == EXPECTED_SNAPSHOTS.length }
check(checks, "snapshot dimensions") do
  snapshots.all? do |snapshot|
    snapshot["width"].to_i.positive? &&
      snapshot["height"].to_i.positive? &&
      snapshot["byteCount"].to_i.positive?
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
