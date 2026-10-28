#!/usr/bin/env bash
# This entry point runs only on GitHub Actions, never on the developer's simulator.
set -euo pipefail
test "${GITHUB_ACTIONS:-}" = true
test -n "${UI_DIR:-}"
test "${UI_PLATFORM:-}" = ios-390 || test "${UI_PLATFORM:-}" = ios-375
phase="${1:-all}"
case "$phase" in
  all|--build-only|--test-only) ;;
  *) printf 'Unknown native UI phase: %s\n' "$phase" >&2; exit 64 ;;
esac

device_udid="$(cat "$UI_DIR/simulator-udid.txt")"
build_command=(
  xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocus -configuration Debug
  -destination 'generic/platform=iOS Simulator'
  -derivedDataPath "$RUNNER_TEMP/ChronoFocusUITestDerivedData"
  -resultBundlePath "$UI_DIR/ios-build.xcresult"
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build-for-testing
)
test_command=(
  xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocus -configuration Debug
  -destination "platform=iOS Simulator,id=$device_udid"
  -destination-timeout 120
  -derivedDataPath "$RUNNER_TEMP/ChronoFocusUITestDerivedData"
  -resultBundlePath "$UI_DIR/ios.xcresult"
  -parallel-testing-enabled NO
  -test-timeouts-enabled YES
  -default-test-execution-time-allowance 120
  -maximum-test-execution-time-allowance 180
  CODE_SIGNING_ALLOWED=NO test-without-building
)
if [[ "$phase" != --test-only ]]; then
  printf '%q ' "${build_command[@]}" > "$UI_DIR/build-command.txt"
  printf '\n' >> "$UI_DIR/build-command.txt"
  printf '%q ' xcrun simctl bootstatus "$device_udid" -b > "$UI_DIR/boot-command.txt"
  printf '\n' >> "$UI_DIR/boot-command.txt"

  # The build does not need a booted simulator; both prerequisites must finish before testing.
  python3 - "$device_udid" "$UI_DIR/simulator-ready.log" <<'PY' &
from pathlib import Path
import subprocess
import sys
with Path(sys.argv[2]).open("x") as log:
    subprocess.run(["xcrun", "simctl", "bootstatus", sys.argv[1], "-b"], stdout=log,
                   stderr=subprocess.STDOUT, check=True, timeout=300)
print("Simulator boot readiness confirmed")
PY
  boot_process=$!
  set +e
  "${build_command[@]}" 2>&1 | tee "$UI_DIR/ios-ui-build.log"
  build_status=${PIPESTATUS[0]}
  wait "$boot_process"
  boot_status=$?
  set -e
  test "$build_status" -eq 0
  test "$boot_status" -eq 0
  printf '%s\n' "$device_udid" > "$UI_DIR/prerequisites-ready.txt"
  printf 'Build and simulator prerequisites passed.\n'
fi
if [[ "$phase" == --build-only ]]; then
  exit 0
fi
test "$(cat "$UI_DIR/prerequisites-ready.txt")" = "$device_udid"
printf '%q ' "${test_command[@]}" > "$UI_DIR/test-command.txt"
printf '\n' >> "$UI_DIR/test-command.txt"
printf 'Starting native tests using the completed build.\n'

set +e
"${test_command[@]}" 2>&1 | tee "$UI_DIR/ios-ui-tests.log"
test_status=${PIPESTATUS[0]}
set -e

if [[ -d "$UI_DIR/ios.xcresult" ]]; then
  xcrun xcresulttool get test-results summary --path "$UI_DIR/ios.xcresult" > "$UI_DIR/ios-summary.json"
  xcrun xcresulttool get test-results tests --path "$UI_DIR/ios.xcresult" > "$UI_DIR/ios-tests.json"
  xcrun xcresulttool export attachments --path "$UI_DIR/ios.xcresult" --output-path "$UI_DIR/attachments"
fi
test "$test_status" -eq 0
python3 scripts/verify_ios_ui_evidence.py
