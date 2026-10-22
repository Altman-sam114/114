#!/usr/bin/env bash
# This entry point runs only on GitHub Actions, never on the developer's simulator.
set -euo pipefail
test "${GITHUB_ACTIONS:-}" = true
test -n "${UI_DIR:-}"
test "${UI_PLATFORM:-}" = ios-390 || test "${UI_PLATFORM:-}" = ios-375

device_udid="$(cat "$UI_DIR/simulator-udid.txt")"
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
  CODE_SIGNING_ALLOWED=NO test
)
printf '%q ' "${test_command[@]}" > "$UI_DIR/test-command.txt"
printf '\n' >> "$UI_DIR/test-command.txt"
set +e
"${test_command[@]}" 2>&1 | tee "$UI_DIR/ios-ui-tests.log"
test_status=${PIPESTATUS[0]}
set -e

if [[ -d "$UI_DIR/ios.xcresult" ]]; then
  xcrun xcresulttool get test-results summary --path "$UI_DIR/ios.xcresult" > "$UI_DIR/ios-summary.json"
  xcrun xcresulttool export attachments --path "$UI_DIR/ios.xcresult" --output-path "$UI_DIR/attachments"
fi
test "$test_status" -eq 0
python3 scripts/verify_ios_ui_evidence.py
