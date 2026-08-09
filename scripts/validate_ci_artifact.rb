#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "digest"
require "fileutils"
require "find"
require "open3"
require "optparse"
require "rexml/document"
require "time"
require "tmpdir"
require "zlib"

EXPECTED_CI_PROCESS_VERSION = "v0.10"
MAX_ARTIFACT_METADATA_BYTES = 1_048_576
MAX_RUN_METADATA_BYTES = MAX_ARTIFACT_METADATA_BYTES
MAX_ARCHIVE_ENTRY_COUNT = 100_000
MAX_ARCHIVE_ENTRY_NAME_BYTES = 4_096
MAX_ARCHIVE_SINGLE_FILE_BYTES = 4 * 1024 * 1024 * 1024
MAX_ARCHIVE_TOTAL_UNCOMPRESSED_BYTES = 8 * 1024 * 1024 * 1024
EXPECTED_WORKFLOW_RUN_NAME = "ChronoFocus CI Results"
EXPECTED_WORKFLOW_RUN_PATH = ".github/workflows/ci-results.yml"
EXPECTED_WORKFLOW_RUN_REPOSITORY = "Altman-sam114/114"
EXPECTED_WORKFLOW_RUN_EVENT = "push"
EXPECTED_WORKFLOW_RUN_ACTOR = "Altman-sam114"
EXPECTED_WORKFLOW_RUN_HEAD_REPOSITORY = "Altman-sam114/114"

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
  opts.banner = "Usage: ruby scripts/validate_ci_artifact.rb ARTIFACT_DIR --commit SHA --run-id ID --attempt N [--branch main] [--archive ZIP --archive-size BYTES --archive-digest sha256:HEX [--artifact-metadata JSON [--run-metadata JSON]]]"
  opts.on("--commit SHA", "Expected commit SHA") { |value| options["commit"] = value }
  opts.on("--run-id ID", "Expected GitHub Actions run id") { |value| options["run_id"] = value }
  opts.on("--attempt N", "Expected GitHub Actions run attempt") { |value| options["attempt"] = value }
  opts.on("--branch NAME", "Expected branch name, default main") { |value| options["branch"] = value }
  opts.on("--archive ZIP", "Downloaded artifact ZIP to validate") { |value| options["archive"] = value }
  opts.on("--archive-size BYTES", "Expected artifact ZIP byte count") { |value| options["archive_size"] = value }
  opts.on("--archive-digest DIGEST", "Expected artifact ZIP digest in sha256:HEX format") { |value| options["archive_digest"] = value }
  opts.on("--artifact-metadata JSON", "Raw GitHub run artifacts API response") { |value| options["artifact_metadata"] = value }
  opts.on("--run-metadata JSON", "Raw GitHub workflow run API response") { |value| options["run_metadata"] = value }
end

begin
  parser.parse!
rescue OptionParser::MissingArgument => e
  raise unless e.message.include?("--run-metadata")

  warn "#{parser}\n--run-metadata requires a non-empty JSON file path"
  exit 2
end

if options.key?("run_metadata") && options["run_metadata"].empty?
  warn "#{parser}\n--run-metadata requires a non-empty JSON file path"
  exit 2
end

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

archive_option_names = {
  "archive" => "--archive",
  "archive_size" => "--archive-size",
  "archive_digest" => "--archive-digest"
}.freeze
provided_archive_options = archive_option_names.keys.select { |key| options.key?(key) }
unless provided_archive_options.empty? || provided_archive_options.length == archive_option_names.length
  missing_archive_options = archive_option_names.keys.reject { |key| options.key?(key) }
  warn "#{parser}\nArchive arguments must be provided together. Missing: #{missing_archive_options.map { |key| archive_option_names.fetch(key) }.join(", ")}"
  exit 2
end

if options.key?("artifact_metadata") && provided_archive_options.length != archive_option_names.length
  warn "#{parser}\n--artifact-metadata requires --archive, --archive-size, and --archive-digest"
  exit 2
end

if options.key?("run_metadata") &&
   (provided_archive_options.length != archive_option_names.length || !options.key?("artifact_metadata"))
  warn "#{parser}\n--run-metadata requires --archive, --archive-size, --archive-digest, and --artifact-metadata"
  exit 2
end

archive_path = nil
if provided_archive_options.length == archive_option_names.length
  unless options["archive_size"].match?(/\A[1-9]\d*\z/)
    warn "#{parser}\n--archive-size must be a positive integer"
    exit 2
  end
  unless options["archive_digest"].match?(/\Asha256:[0-9a-fA-F]{64}\z/)
    warn "#{parser}\n--archive-digest must use sha256: followed by 64 hexadecimal characters"
    exit 2
  end

  archive_path = File.expand_path(options["archive"])
  unless File.file?(archive_path)
    warn "#{parser}\n--archive must reference a regular file"
    exit 2
  end
end

def validate_external_metadata_path(raw_path, option_name, max_bytes, parser)
  path = File.expand_path(raw_path)
  begin
    metadata_stat = File.lstat(path)
  rescue SystemCallError
    warn "#{parser}\n#{option_name} must reference an existing regular file"
    exit 2
  end

  if metadata_stat.symlink? || !metadata_stat.file?
    warn "#{parser}\n#{option_name} must reference a regular file and must not be a symlink"
    exit 2
  end
  unless metadata_stat.size.positive?
    warn "#{parser}\n#{option_name} must not be empty"
    exit 2
  end
  if metadata_stat.size > max_bytes
    warn "#{parser}\n#{option_name} must not exceed #{max_bytes} bytes"
    exit 2
  end
  unless File.readable?(path)
    warn "#{parser}\n#{option_name} must reference a readable regular file"
    exit 2
  end

  path
end

artifact_metadata_path =
  if options.key?("artifact_metadata")
    validate_external_metadata_path(
      options["artifact_metadata"],
      "--artifact-metadata",
      MAX_ARTIFACT_METADATA_BYTES,
      parser
    )
  end

run_metadata_path =
  if options.key?("run_metadata")
    validate_external_metadata_path(
      options["run_metadata"],
      "--run-metadata",
      MAX_RUN_METADATA_BYTES,
      parser
    )
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

ZipArchiveEntry = Struct.new(
  :raw_name,
  :path,
  :kind,
  :compression_method,
  :compressed_size,
  :uncompressed_size,
  :crc32,
  :flags,
  :local_data_offset,
  keyword_init: true
).freeze

def zip_read_exact(io, length, context)
  value = io.read(length)
  raise "#{context} is truncated" unless value && value.bytesize == length

  value
end

def zip_parse_zip64_extra(extra, required_fields)
  values = {}
  offset = 0
  while offset < extra.bytesize
    raise "ZIP extra field header is truncated" if extra.bytesize - offset < 4

    field_id, field_size = extra.byteslice(offset, 4).unpack("vv")
    offset += 4
    raise "ZIP extra field is truncated" if offset + field_size > extra.bytesize

    if field_id == 0x0001
      payload = extra.byteslice(offset, field_size)
      payload_offset = 0
      required_fields.each do |field|
        break if values.key?(field)
        raise "ZIP64 extra field is truncated" if payload_offset + 8 > payload.bytesize

        values[field] = payload.byteslice(payload_offset, 8).unpack1("Q<")
        payload_offset += 8
      end
    end
    offset += field_size
  end

  missing = required_fields.reject { |field| values.key?(field) }
  raise "ZIP64 extra field is missing #{missing.join(", ")}" unless missing.empty?

  values
end

def zip_entry_kind(raw_name, external_attributes)
  directory_marker = raw_name.end_with?("/")
  unix_mode = (external_attributes >> 16) & 0xffff
  unix_type = unix_mode & 0xf000

  kind =
    if unix_type != 0
      case unix_type
      when 0x4000
        "directory"
      when 0x8000
        "file"
      else
        raise "ZIP entry #{raw_name.inspect} has an unsupported special file type"
      end
    elsif directory_marker || (external_attributes & 0x10).positive?
      "directory"
    else
      "file"
    end

  if directory_marker && kind != "directory"
    raise "ZIP entry #{raw_name.inspect} has a file type with a directory marker"
  end

  kind
end

def zip_normalize_entry_path(raw_name, kind)
  raise "ZIP entry name is empty" if raw_name.empty?
  raise "ZIP entry name contains NUL" if raw_name.include?("\0")
  raise "ZIP entry name contains a backslash" if raw_name.include?("\\")
  raise "ZIP entry name is absolute" if raw_name.start_with?("/")
  raise "ZIP entry name uses a drive path" if raw_name.match?(/\A[A-Za-z]:/)

  name = raw_name.dup
  name = name.byteslice(0, name.bytesize - 1) if kind == "directory" && name.end_with?("/")
  components = name.split("/", -1)
  if components.empty? || components.any? { |component| component.empty? || component == "." || component == ".." }
    raise "ZIP entry #{raw_name.inspect} contains an invalid path component"
  end

  components.join("/")
end

def zip_parse_archive(path)
  File.open(path, "rb") do |io|
    archive_size = io.stat.size
    raise "ZIP archive is empty" if archive_size.zero?

    tail_length = [archive_size, 65_557].min
    io.seek(archive_size - tail_length)
    tail = zip_read_exact(io, tail_length, "ZIP archive tail")
    eocd_relative_offset = tail.rindex("PK\x05\x06".b)
    raise "ZIP end-of-central-directory record is missing" unless eocd_relative_offset

    eocd_offset = archive_size - tail_length + eocd_relative_offset
    io.seek(eocd_offset)
    eocd = zip_read_exact(io, 22, "ZIP end-of-central-directory record")
    raise "ZIP end-of-central-directory signature is invalid" unless eocd.byteslice(0, 4) == "PK\x05\x06".b

    comment_length = eocd.byteslice(20, 2).unpack1("v")
    raise "ZIP end-of-central-directory comment is truncated" unless eocd_offset + 22 + comment_length == archive_size

    disk_number, central_disk_number, entries_on_disk_32, entry_count_32, central_size_32, central_offset_32 =
      eocd.byteslice(4, 16).unpack("vvvvVV")
    zip64_required = [entries_on_disk_32, entry_count_32, central_size_32, central_offset_32].any? do |value|
      value == 0xffff || value == 0xffff_ffff
    end

    if zip64_required
      locator_offset = eocd_offset - 20
      raise "ZIP64 locator is missing" if locator_offset.negative?

      io.seek(locator_offset)
      locator = zip_read_exact(io, 20, "ZIP64 locator")
      raise "ZIP64 locator signature is invalid" unless locator.byteslice(0, 4) == "PK\x06\x07".b

      locator_disk, zip64_offset, total_disks = locator.byteslice(4, 16).unpack("VQ<V")
      raise "multi-disk ZIP archives are not supported" unless locator_disk.zero? && total_disks == 1

      io.seek(zip64_offset)
      zip64_header = zip_read_exact(io, 12, "ZIP64 end-of-central-directory header")
      raise "ZIP64 end-of-central-directory signature is invalid" unless zip64_header.byteslice(0, 4) == "PK\x06\x06".b

      zip64_record_size = zip64_header.byteslice(4, 8).unpack1("Q<")
      raise "ZIP64 end-of-central-directory record is too short" if zip64_record_size < 44
      raise "ZIP64 end-of-central-directory record is out of bounds" if zip64_offset + 12 + zip64_record_size > locator_offset

      zip64_record = zip_read_exact(io, zip64_record_size, "ZIP64 end-of-central-directory record")
      zip64_disk_number = zip64_record.byteslice(4, 4).unpack1("V")
      zip64_central_disk_number = zip64_record.byteslice(8, 4).unpack1("V")
      entries_on_disk = zip64_record.byteslice(12, 8).unpack1("Q<")
      entry_count = zip64_record.byteslice(20, 8).unpack1("Q<")
      central_size = zip64_record.byteslice(28, 8).unpack1("Q<")
      central_offset = zip64_record.byteslice(36, 8).unpack1("Q<")
      raise "multi-disk ZIP archives are not supported" unless zip64_disk_number.zero? && zip64_central_disk_number.zero?
      raise "ZIP entry count differs between disks" unless entries_on_disk == entry_count
    else
      raise "multi-disk ZIP archives are not supported" unless disk_number.zero? && central_disk_number.zero?
      raise "ZIP entry count differs between disks" unless entries_on_disk_32 == entry_count_32

      entry_count = entry_count_32
      central_size = central_size_32
      central_offset = central_offset_32
    end

    raise "ZIP archive has too many entries" if entry_count > MAX_ARCHIVE_ENTRY_COUNT
    central_end = central_offset + central_size
    raise "ZIP central directory is out of bounds" if central_offset.negative? || central_end > eocd_offset || central_end != eocd_offset

    entries = []
    raw_names = {}
    paths = {}
    total_uncompressed_size = 0
    io.seek(central_offset)
    entry_count.times do
      fixed = zip_read_exact(io, 46, "ZIP central directory entry")
      raise "ZIP central directory entry signature is invalid" unless fixed.byteslice(0, 4) == "PK\x01\x02".b

      flags = fixed.byteslice(8, 2).unpack1("v")
      compression_method = fixed.byteslice(10, 2).unpack1("v")
      crc32 = fixed.byteslice(16, 4).unpack1("V")
      compressed_size_32 = fixed.byteslice(20, 4).unpack1("V")
      uncompressed_size_32 = fixed.byteslice(24, 4).unpack1("V")
      name_length = fixed.byteslice(28, 2).unpack1("v")
      extra_length = fixed.byteslice(30, 2).unpack1("v")
      comment_length = fixed.byteslice(32, 2).unpack1("v")
      disk_start_16 = fixed.byteslice(34, 2).unpack1("v")
      external_attributes = fixed.byteslice(38, 4).unpack1("V")
      local_offset_32 = fixed.byteslice(42, 4).unpack1("V")

      raise "ZIP entry name is too long" if name_length > MAX_ARCHIVE_ENTRY_NAME_BYTES
      raw_name = zip_read_exact(io, name_length, "ZIP entry name")
      extra = zip_read_exact(io, extra_length, "ZIP entry extra data")
      zip_read_exact(io, comment_length, "ZIP entry comment")
      raise "encrypted ZIP entries are not supported" if (flags & 0x41).positive?
      raise "ZIP entry starts on another disk" unless disk_start_16.zero? || disk_start_16 == 0xffff

      required_zip64_fields = []
      required_zip64_fields << :uncompressed_size if uncompressed_size_32 == 0xffff_ffff
      required_zip64_fields << :compressed_size if compressed_size_32 == 0xffff_ffff
      required_zip64_fields << :local_offset if local_offset_32 == 0xffff_ffff
      required_zip64_fields << :disk_start if disk_start_16 == 0xffff
      zip64_values = required_zip64_fields.empty? ? {} : zip_parse_zip64_extra(extra, required_zip64_fields)
      uncompressed_size = uncompressed_size_32 == 0xffff_ffff ? zip64_values.fetch(:uncompressed_size) : uncompressed_size_32
      compressed_size = compressed_size_32 == 0xffff_ffff ? zip64_values.fetch(:compressed_size) : compressed_size_32
      local_offset = local_offset_32 == 0xffff_ffff ? zip64_values.fetch(:local_offset) : local_offset_32
      disk_start = disk_start_16 == 0xffff ? zip64_values.fetch(:disk_start) : disk_start_16
      raise "ZIP entry starts on another disk" unless disk_start.zero?
      raise "ZIP entry uses an unsupported compression method" unless [0, 8].include?(compression_method)
      raise "ZIP entry is larger than the supported single-file limit" if uncompressed_size > MAX_ARCHIVE_SINGLE_FILE_BYTES
      total_uncompressed_size += uncompressed_size
      raise "ZIP archive exceeds the supported total extraction limit" if total_uncompressed_size > MAX_ARCHIVE_TOTAL_UNCOMPRESSED_BYTES

      kind = zip_entry_kind(raw_name, external_attributes)
      path_name = zip_normalize_entry_path(raw_name, kind)
      raise "ZIP archive contains a duplicate raw entry path" if raw_names.key?(raw_name)
      raise "ZIP archive contains a duplicate normalized entry path" if paths.key?(path_name)
      raw_names[raw_name] = true
      paths[path_name] = kind
      if kind == "directory" && (compressed_size != 0 || uncompressed_size != 0)
        raise "ZIP directory entry contains file data"
      end

      central_position = io.pos
      io.seek(local_offset)
      local_header = zip_read_exact(io, 30, "ZIP local file header")
      raise "ZIP local file header signature is invalid" unless local_header.byteslice(0, 4) == "PK\x03\x04".b

      local_flags = local_header.byteslice(6, 2).unpack1("v")
      local_method = local_header.byteslice(8, 2).unpack1("v")
      local_name_length = local_header.byteslice(26, 2).unpack1("v")
      local_extra_length = local_header.byteslice(28, 2).unpack1("v")
      local_name = zip_read_exact(io, local_name_length, "ZIP local entry name")
      zip_read_exact(io, local_extra_length, "ZIP local entry extra data")
      raise "ZIP local and central entry names differ" unless local_name == raw_name
      raise "ZIP local and central entry flags differ" unless local_flags == flags
      raise "ZIP local and central compression methods differ" unless local_method == compression_method

      local_data_offset = io.pos
      data_end = local_data_offset + compressed_size
      raise "ZIP entry data is out of bounds" if local_data_offset > central_offset || data_end > central_offset
      io.seek(central_position)

      entries << ZipArchiveEntry.new(
        raw_name: raw_name,
        path: path_name,
        kind: kind,
        compression_method: compression_method,
        compressed_size: compressed_size,
        uncompressed_size: uncompressed_size,
        crc32: crc32,
        flags: flags,
        local_data_offset: local_data_offset
      )
    end
    raise "ZIP central directory entry count does not match its size" unless io.pos == central_end

    entries.each do |entry|
      components = entry.path.split("/")
      components.each_index do |index|
        parent = components[0, index].join("/")
        next if parent.empty?
        raise "ZIP archive contains a file/directory prefix conflict" if paths[parent] == "file"
      end
    end

    entries
  end
end

def archive_ensure_directory(root, relative_path)
  current = root
  relative_path.split("/").each do |component|
    current = File.join(current, component)
    begin
      stat = File.lstat(current)
      raise "archive extraction encountered a symlink" if stat.symlink?
      raise "archive extraction path is not a directory" unless stat.directory?
    rescue Errno::ENOENT
      Dir.mkdir(current, 0o700)
    end
  end
end

def archive_target_path(root, relative_path)
  expanded_root = File.expand_path(root)
  target = File.expand_path(File.join(root, *relative_path.split("/")))
  root_prefix = "#{expanded_root}#{File::SEPARATOR}"
  raise "archive extraction path escapes its temporary root" unless target.start_with?(root_prefix)

  target
end

def archive_write_chunk(output, chunk, written, expected_size)
  return written if chunk.nil? || chunk.empty?

  next_written = written + chunk.bytesize
  raise "ZIP entry expanded beyond its declared size" if next_written > expected_size

  output.write(chunk)
  next_written
end

def archive_extract_entry(io, entry, root)
  target = archive_target_path(root, entry.path)
  if entry.kind == "directory"
    archive_ensure_directory(root, entry.path)
    return
  end

  archive_ensure_directory(root, File.dirname(entry.path)) unless File.dirname(entry.path) == "."
  begin
    File.lstat(target)
    raise "ZIP archive extraction would overwrite an existing path"
  rescue Errno::ENOENT
    # The target is created exclusively below.
  end

  io.seek(entry.local_data_offset)
  File.open(target, File::WRONLY | File::CREAT | File::EXCL, 0o600) do |output|
    remaining = entry.compressed_size
    written = 0
    crc32 = 0
    case entry.compression_method
    when 0
      while remaining.positive?
        chunk_length = [remaining, 1_048_576].min
        chunk = zip_read_exact(io, chunk_length, "ZIP stored entry data")
        remaining -= chunk.bytesize
        written = archive_write_chunk(output, chunk, written, entry.uncompressed_size)
        crc32 = Zlib.crc32(chunk, crc32)
      end
    when 8
      inflater = Zlib::Inflate.new(-Zlib::MAX_WBITS)
      begin
        while remaining.positive?
          chunk_length = [remaining, 1_048_576].min
          chunk = zip_read_exact(io, chunk_length, "ZIP deflated entry data")
          remaining -= chunk.bytesize
          output_chunk = inflater.inflate(chunk)
          written = archive_write_chunk(output, output_chunk, written, entry.uncompressed_size)
          crc32 = Zlib.crc32(output_chunk, crc32)
        end
        output_chunk = inflater.finish
        written = archive_write_chunk(output, output_chunk, written, entry.uncompressed_size)
        crc32 = Zlib.crc32(output_chunk, crc32)
        raise "ZIP deflate stream is incomplete" unless inflater.finished?
        raise "ZIP deflate stream contains trailing data" unless inflater.unused.to_s.empty?
      ensure
        inflater.close
      end
    end
    raise "ZIP entry size does not match its central directory metadata" unless written == entry.uncompressed_size
    raise "ZIP entry CRC-32 does not match its central directory metadata" unless crc32 == entry.crc32
  end
end

def archive_extract_to_temporary_directory(archive_path, entries, destination)
  File.open(archive_path, "rb") do |io|
    entries.sort_by(&:path).each { |entry| archive_extract_entry(io, entry, destination) }
  end
end

def archive_sha256_file(path, expected_size)
  digest = Digest::SHA256.new
  File.open(path, "rb") do |io|
    stat = io.stat
    raise "artifact directory file is not a regular single-link file" unless stat.file? && stat.nlink == 1
    raise "artifact directory file size changed during binding" unless stat.size == expected_size

    while (chunk = io.read(1_048_576))
      digest.update(chunk)
    end
  end
  digest.hexdigest
end

def archive_directory_snapshot(root)
  root_stat = File.lstat(root)
  raise "artifact directory root must be a regular directory" if root_stat.symlink? || !root_stat.directory?

  snapshot = {}
  total_size = 0
  walk = lambda do |directory, prefix|
    Dir.children(directory).sort.each do |name|
      child = File.join(directory, name)
      relative_path = prefix.empty? ? name : "#{prefix}/#{name}"
      stat = File.lstat(child)
      raise "artifact directory contains a symlink" if stat.symlink?
      raise "artifact directory contains an unsupported special file" unless stat.directory? || stat.file?
      raise "artifact directory contains too many entries" if snapshot.length >= MAX_ARCHIVE_ENTRY_COUNT

      if stat.directory?
        snapshot[relative_path] = { "kind" => "directory" }
        walk.call(child, relative_path)
      else
        raise "artifact directory contains a hard link" unless stat.nlink == 1
        raise "artifact directory file exceeds the supported single-file limit" if stat.size > MAX_ARCHIVE_SINGLE_FILE_BYTES

        total_size += stat.size
        raise "artifact directory exceeds the supported total extraction limit" if total_size > MAX_ARCHIVE_TOTAL_UNCOMPRESSED_BYTES

        snapshot[relative_path] = {
          "kind" => "file",
          "size" => stat.size,
          "sha256" => archive_sha256_file(child, stat.size)
        }
      end
    end
  end
  walk.call(root, "")
  snapshot
end

def archive_compare_directory_snapshots(expected, actual)
  all_paths = (expected.keys | actual.keys).sort
  mismatches = all_paths.filter_map do |path|
    if !expected.key?(path)
      "extra #{path}"
    elsif !actual.key?(path)
      "missing #{path}"
    elsif expected[path] != actual[path]
      "different #{path}"
    end
  end
  return true if mismatches.empty?

  raise "archive extracted directory differs from the original ZIP (#{mismatches.first(8).join(", ")})"
end

def validate_archive_extracted_directory_binding(archive_path, artifact_dir, archive_integrity_ok)
  raise "archive integrity checks failed; archive binding was skipped" unless archive_integrity_ok

  entries = zip_parse_archive(archive_path)
  Dir.mktmpdir("chronofocus-archive-binding-") do |temporary_directory|
    archive_extract_to_temporary_directory(archive_path, entries, temporary_directory)
    expected = archive_directory_snapshot(artifact_dir)
    actual = archive_directory_snapshot(temporary_directory)
    archive_compare_directory_snapshots(expected, actual)
  end
  true
end

begin
artifact_dir = resolve_artifact_dir(artifact_arg)
checks = []
branch_slug = options["branch"].gsub("/", "-")
short_sha = options["commit"][0, 7]
expected_artifact_name = "chronofocus-ci-#{EXPECTED_CI_PROCESS_VERSION}-#{branch_slug}-#{short_sha}-run#{options["run_id"]}-attempt#{options["attempt"]}"
expected_archive_size = archive_path ? Integer(options["archive_size"], 10) : nil
expected_archive_digest = archive_path ? options["archive_digest"].downcase : nil
actual_archive_size = archive_path ? File.size(archive_path) : nil
actual_archive_digest = archive_path ? "sha256:#{Digest::SHA256.file(archive_path).hexdigest}" : nil
archive_integrity_ok = false

if archive_path
  archive_byte_count_ok = actual_archive_size == expected_archive_size
  archive_digest_ok = actual_archive_digest == expected_archive_digest
  archive_zip_integrity_ok = false
  check(checks, "artifact archive byte count") { archive_byte_count_ok }
  check(checks, "artifact archive sha256 digest") { archive_digest_ok }
  check(checks, "artifact archive zip integrity") do
    stdout, stderr, status = Open3.capture3(*["unzip", "-t", archive_path])
    unless status.success?
      detail = [stderr, stdout].map(&:strip).reject(&:empty?).join(" | ")
      raise(detail.empty? ? "unzip -t exited with status #{status.exitstatus}" : detail[0, 500])
    end

    archive_zip_integrity_ok = true
    true
  end
  archive_integrity_ok = archive_byte_count_ok && archive_digest_ok && archive_zip_integrity_ok
  check(checks, "artifact archive extracted directory binding") do
    validate_archive_extracted_directory_binding(archive_path, artifact_dir, archive_integrity_ok)
  end
end

if artifact_metadata_path
  artifact_metadata = nil
  artifact_metadata_error = nil
  begin
    artifact_metadata = read_json(artifact_metadata_path)
  rescue JSON::ParserError, EncodingError, ArgumentError => e
    artifact_metadata_error = "invalid JSON (#{e.class})"
  end

  metadata_artifacts = artifact_metadata.is_a?(Hash) ? artifact_metadata["artifacts"] : nil
  metadata_artifact = metadata_artifacts.is_a?(Array) && metadata_artifacts.length == 1 ? metadata_artifacts.first : nil
  metadata_workflow_run = metadata_artifact.is_a?(Hash) ? metadata_artifact["workflow_run"] : nil

  check(checks, "artifact metadata response shape") do
    raise artifact_metadata_error if artifact_metadata_error

    artifact_metadata.is_a?(Hash) &&
      artifact_metadata["total_count"].is_a?(Integer) &&
      artifact_metadata["total_count"] == 1 &&
      metadata_artifacts.is_a?(Array)
  end
  check(checks, "artifact metadata unique artifact") do
    artifact_metadata.is_a?(Hash) &&
      metadata_artifacts.is_a?(Array) &&
      metadata_artifacts.length == 1 &&
      artifact_metadata["total_count"] == metadata_artifacts.length &&
      metadata_artifact.is_a?(Hash)
  end
  check(checks, "artifact metadata id") do
    metadata_artifact.is_a?(Hash) &&
      metadata_artifact["id"].is_a?(Integer) &&
      metadata_artifact["id"].positive?
  end
  check(checks, "artifact metadata name") do
    metadata_artifact.is_a?(Hash) &&
      metadata_artifact["name"].is_a?(String) &&
      metadata_artifact["name"] == expected_artifact_name
  end
  check(checks, "artifact metadata byte count") do
    metadata_artifact.is_a?(Hash) &&
      metadata_artifact["size_in_bytes"].is_a?(Integer) &&
      metadata_artifact["size_in_bytes"].positive? &&
      metadata_artifact["size_in_bytes"] == expected_archive_size &&
      metadata_artifact["size_in_bytes"] == actual_archive_size
  end
  check(checks, "artifact metadata sha256 digest") do
    metadata_digest = metadata_artifact.is_a?(Hash) ? metadata_artifact["digest"] : nil
    metadata_digest.is_a?(String) &&
      metadata_digest.match?(/\Asha256:[0-9a-fA-F]{64}\z/) &&
      metadata_digest.downcase == expected_archive_digest &&
      metadata_digest.downcase == actual_archive_digest
  end
  check(checks, "artifact metadata not expired") do
    metadata_artifact.is_a?(Hash) && metadata_artifact["expired"].equal?(false)
  end
  check(checks, "artifact metadata workflow run") do
    metadata_workflow_run.is_a?(Hash) &&
      metadata_workflow_run["id"].is_a?(Integer) &&
      metadata_workflow_run["id"].positive? &&
      metadata_workflow_run["id"].to_s == options["run_id"] &&
      metadata_workflow_run["head_sha"].is_a?(String) &&
      metadata_workflow_run["head_sha"] == options["commit"] &&
      metadata_workflow_run["head_branch"].is_a?(String) &&
      metadata_workflow_run["head_branch"] == options["branch"]
  end
end

if run_metadata_path
  run_metadata = nil
  run_metadata_error = nil
  begin
    run_metadata = read_json(run_metadata_path)
  rescue JSON::ParserError, EncodingError, ArgumentError => e
    run_metadata_error = "invalid JSON (#{e.class})"
  end

  check(checks, "workflow run metadata response shape") do
    raise run_metadata_error if run_metadata_error

    run_metadata.is_a?(Hash)
  end
  check(checks, "workflow run metadata id") do
    run_metadata.is_a?(Hash) &&
      run_metadata["id"].is_a?(Integer) &&
      run_metadata["id"].positive? &&
      run_metadata["id"].to_s == options["run_id"] &&
      metadata_workflow_run.is_a?(Hash) &&
      run_metadata["id"] == metadata_workflow_run["id"]
  end
  check(checks, "workflow run metadata run attempt") do
    run_metadata.is_a?(Hash) &&
      run_metadata["run_attempt"].is_a?(Integer) &&
      run_metadata["run_attempt"].positive? &&
      run_metadata["run_attempt"].to_s == options["attempt"]
  end
  check(checks, "workflow run metadata head sha") do
    run_metadata.is_a?(Hash) &&
      run_metadata["head_sha"].is_a?(String) &&
      run_metadata["head_sha"] == options["commit"] &&
      metadata_workflow_run.is_a?(Hash) &&
      run_metadata["head_sha"] == metadata_workflow_run["head_sha"]
  end
  check(checks, "workflow run metadata head branch") do
    run_metadata.is_a?(Hash) &&
      run_metadata["head_branch"].is_a?(String) &&
      run_metadata["head_branch"] == options["branch"] &&
      metadata_workflow_run.is_a?(Hash) &&
      run_metadata["head_branch"] == metadata_workflow_run["head_branch"]
  end
  check(checks, "workflow run metadata name") do
    run_metadata.is_a?(Hash) &&
      run_metadata["name"].is_a?(String) &&
      run_metadata["name"] == EXPECTED_WORKFLOW_RUN_NAME
  end
  check(checks, "workflow run metadata path") do
    run_metadata.is_a?(Hash) &&
      run_metadata["path"].is_a?(String) &&
      run_metadata["path"] == EXPECTED_WORKFLOW_RUN_PATH
  end
  check(checks, "workflow run metadata status") do
    run_metadata.is_a?(Hash) &&
      run_metadata["status"].is_a?(String) &&
      run_metadata["status"] == "completed"
  end
  check(checks, "workflow run metadata conclusion") do
    run_metadata.is_a?(Hash) &&
      run_metadata["conclusion"].is_a?(String) &&
      run_metadata["conclusion"] == "success"
  end
  check(checks, "workflow run metadata repository") do
    repository = run_metadata.is_a?(Hash) ? run_metadata["repository"] : nil
    unless repository.is_a?(Hash) &&
           repository["full_name"].is_a?(String) &&
           repository["full_name"] == EXPECTED_WORKFLOW_RUN_REPOSITORY
      raise "repository.full_name must equal #{EXPECTED_WORKFLOW_RUN_REPOSITORY}"
    end

    true
  end
  check(checks, "workflow run metadata event") do
    run_metadata.is_a?(Hash) &&
      run_metadata["event"].is_a?(String) &&
      run_metadata["event"] == EXPECTED_WORKFLOW_RUN_EVENT
  end
  check(checks, "workflow run metadata actor") do
    actor = run_metadata.is_a?(Hash) ? run_metadata["actor"] : nil
    actor.is_a?(Hash) &&
      actor["login"].is_a?(String) &&
      actor["login"] == EXPECTED_WORKFLOW_RUN_ACTOR
  end
  check(checks, "workflow run metadata triggering actor") do
    triggering_actor = run_metadata.is_a?(Hash) ? run_metadata["triggering_actor"] : nil
    triggering_actor.is_a?(Hash) &&
      triggering_actor["login"].is_a?(String) &&
      triggering_actor["login"] == EXPECTED_WORKFLOW_RUN_ACTOR
  end
  check(checks, "workflow run metadata head repository") do
    head_repository = run_metadata.is_a?(Hash) ? run_metadata["head_repository"] : nil
    head_repository.is_a?(Hash) &&
      head_repository["full_name"].is_a?(String) &&
      head_repository["full_name"] == EXPECTED_WORKFLOW_RUN_HEAD_REPOSITORY
  end
end

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
check(checks, "verify_project mac calendar range empty state quick add contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Mac calendar range empty state quick add contracts verified.")
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
check(checks, "verify_project existing category reuse contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Existing category reuse contracts verified.")
end
check(checks, "verify_project existing category usage context contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Existing category usage context contracts verified.")
end
check(checks, "verify_project existing category search contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Existing category search contracts verified.")
end
check(checks, "verify_project schedule to timer handoff contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Schedule to timer handoff contracts verified.")
end
check(checks, "verify_project startable task consistency contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Startable task consistency contracts verified.")
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
check(checks, "verify_project timer category empty state action contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Timer category empty state action contracts verified.")
end
check(checks, "verify_project timer task queue expansion contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Timer task queue expansion contracts verified.")
end
check(checks, "verify_project declaration boundary resilience contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Declaration boundary resilience contracts verified.")
end
check(checks, "verify_project mac timer category queue contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("Mac timer category queue contracts verified.")
end
check(checks, "verify_project ci action Node.js 24 contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("CI action Node.js 24 contracts verified.")
end
check(checks, "verify_project ci failure summary output contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("CI failure summary output contracts verified.")
end
check(checks, "verify_project ci artifact archive integrity contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("CI artifact archive integrity contracts verified.")
end
check(checks, "verify_project ci artifact API metadata contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("CI artifact API metadata contracts verified.")
end
check(checks, "verify_project ci workflow run API metadata contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("CI workflow run API metadata contracts verified.")
end
check(checks, "verify_project ci workflow run provenance contracts") do
  File.read(verify_log_path, encoding: "UTF-8").include?("CI workflow run provenance contracts verified.")
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
