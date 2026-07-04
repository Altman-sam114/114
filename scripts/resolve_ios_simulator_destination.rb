#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"
require "optparse"
require "shellwords"

DEFAULT_DEVICE_PREFERENCES = [
  "iPhone 16 Pro",
  "iPhone 16",
  "iPhone 15 Pro",
  "iPhone 15",
  "iPhone 14 Pro",
  "iPhone 14"
].freeze
DEFAULT_DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer"

if ENV["DEVELOPER_DIR"].to_s.empty? && Dir.exist?(DEFAULT_DEVELOPER_DIR)
  ENV["DEVELOPER_DIR"] = DEFAULT_DEVELOPER_DIR
end

options = {
  print_build_command: false
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby scripts/resolve_ios_simulator_destination.rb [--name DEVICE_NAME] [--simctl-json PATH] [--print-build-command]"
  opts.on("--name NAME", "Prefer a simulator with this exact name") { |value| options[:name] = value }
  opts.on("--simctl-json PATH", "Read simctl devices JSON from a file instead of running xcrun") { |value| options[:simctl_json] = value }
  opts.on("--print-build-command", "Print a ChronoFocus iOS simulator xcodebuild command") { options[:print_build_command] = true }
end

parser.parse!

def simctl_json(options)
  return File.read(options[:simctl_json], encoding: "UTF-8") if options[:simctl_json]

  stdout, stderr, status = Open3.capture3("xcrun", "simctl", "list", "devices", "available", "-j")
  return stdout if status.success?

  raise "Unable to read available simulators with xcrun simctl: #{stderr.strip}"
end

def runtime_version(runtime_identifier)
  runtime_identifier.scan(/\d+/).map(&:to_i)
end

def runtime_sort_key(runtime_identifier)
  version = runtime_version(runtime_identifier)
  [version[0] || 0, version[1] || 0, version[2] || 0]
end

def available_ios_devices(data)
  data.fetch("devices").flat_map do |runtime_identifier, devices|
    next [] unless runtime_identifier.include?("SimRuntime.iOS")

    devices.map do |device|
      next nil if device["isAvailable"] == false

      {
        "name" => device.fetch("name"),
        "udid" => device.fetch("udid"),
        "state" => device["state"].to_s,
        "runtime" => runtime_identifier,
        "runtimeSortKey" => runtime_sort_key(runtime_identifier)
      }
    end.compact
  end
end

def device_preference_rank(device_name, preferred_name)
  return -1 if preferred_name && device_name == preferred_name

  DEFAULT_DEVICE_PREFERENCES.index(device_name) || DEFAULT_DEVICE_PREFERENCES.length
end

def choose_device(devices, preferred_name)
  devices.sort_by do |device|
    base_rank = [
      -device["runtimeSortKey"][0],
      -device["runtimeSortKey"][1],
      -device["runtimeSortKey"][2],
      device["name"]
    ]

    if preferred_name
      [device["name"] == preferred_name ? 0 : 1, device["state"] == "Booted" ? 0 : 1, *base_rank]
    else
      [device["state"] == "Booted" ? 0 : 1, device_preference_rank(device["name"], nil), *base_rank]
    end
  end.first
end

def destination_for(device)
  "platform=iOS Simulator,id=#{device.fetch("udid")}"
end

def shell_assignment(name, value)
  "#{name}=#{Shellwords.escape(value)}"
end

def build_command(destination)
  [
    shell_assignment("DEVELOPER_DIR", ENV.fetch("DEVELOPER_DIR", DEFAULT_DEVELOPER_DIR)),
    "xcodebuild",
    "-project", "ChronoFocus.xcodeproj",
    "-scheme", "ChronoFocus",
    "-configuration", "Debug",
    "-destination", destination,
    "-derivedDataPath", "/tmp/ChronoFocusIOSDerivedData",
    "CODE_SIGNING_ALLOWED=NO",
    "build"
  ].map { |part| part.match?(/\A[A-Z_]+=.+\z/) ? part : Shellwords.escape(part) }.join(" ")
end

begin
  data = JSON.parse(simctl_json(options))
  devices = available_ios_devices(data)
  raise "No available iOS simulators found" if devices.empty?

  device = choose_device(devices, options[:name])
  destination = destination_for(device)

  if options[:print_build_command]
    puts build_command(destination)
  else
    puts destination
  end
rescue StandardError => e
  warn "Unable to resolve iOS simulator destination: #{e.message}"
  exit 1
end
