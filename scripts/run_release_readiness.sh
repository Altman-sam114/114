#!/usr/bin/env bash
# Actions-only unsigned Release builds; distribution still needs real signing identities.
set -euo pipefail
test "${GITHUB_ACTIONS:-}" = true
test "${UI_PLATFORM:-}" = release
test -n "${UI_DIR:-}"

release_root="$(mktemp -d "$RUNNER_TEMP/chronofocus-release-XXXXXXXX")"
mac_command=(
  xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocusMac -configuration Release
  -destination 'generic/platform=macOS' -derivedDataPath "$release_root/mac"
  -resultBundlePath "$UI_DIR/release-mac.xcresult"
  'ARCHS=arm64 x86_64' ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO build
)
ios_command=(
  xcodebuild -project ChronoFocus.xcodeproj -scheme ChronoFocus -configuration Release
  -destination 'generic/platform=iOS' -derivedDataPath "$release_root/ios"
  -resultBundlePath "$UI_DIR/release-ios.xcresult"
  CODE_SIGNING_ALLOWED=NO build
)
printf '%q ' "${mac_command[@]}" > "$UI_DIR/release-command.txt"
printf '\n' >> "$UI_DIR/release-command.txt"
printf '%q ' "${ios_command[@]}" >> "$UI_DIR/release-command.txt"
printf '\n' >> "$UI_DIR/release-command.txt"

set +e
"${mac_command[@]}" 2>&1 | tee "$UI_DIR/release-mac.log"
mac_status=${PIPESTATUS[0]}
"${ios_command[@]}" 2>&1 | tee "$UI_DIR/release-ios.log"
ios_status=${PIPESTATUS[0]}
set -e
test "$mac_status" -eq 0
test "$ios_status" -eq 0

python3 scripts/verify_release_products.py \
  --mac "$release_root/mac/Build/Products/Release/ChronoFocusMac.app" \
  --ios "$release_root/ios/Build/Products/Release-iphoneos/ChronoFocus.app" \
  --output "$UI_DIR"
