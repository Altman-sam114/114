#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

project="ChronoFocus.xcodeproj/project.pbxproj"

echo "Checking project and property lists..."
plutil -lint "$project" >/dev/null
plutil -lint \
  ChronoFocus/Info.plist \
  ChronoFocusLiveActivity/Info.plist \
  ChronoFocus/ChronoFocus.entitlements \
  ChronoFocusLiveActivity/ChronoFocusLiveActivity.entitlements >/dev/null
python3 -m json.tool ChronoFocus/Assets.xcassets/AppIcon.appiconset/Contents.json >/dev/null
python3 -m json.tool ChronoFocus/Assets.xcassets/AccentColor.colorset/Contents.json >/dev/null
python3 -m json.tool ChronoFocus/Assets.xcassets/Contents.json >/dev/null
python3 -c 'import sys, xml.etree.ElementTree as ET; [ET.parse(path) for path in sys.argv[1:]]' \
  ChronoFocus.xcodeproj/xcshareddata/xcschemes/ChronoFocus.xcscheme \
  ChronoFocus.xcodeproj/xcshareddata/xcschemes/ChronoFocusLiveActivity.xcscheme \
  ChronoFocus.xcodeproj/xcshareddata/xcschemes/ChronoFocusMac.xcscheme

required_files=(
  "ChronoFocus/ChronoFocusApp.swift"
  "ChronoFocus/Models/AppModels.swift"
  "ChronoFocus/Services/FocusStore.swift"
  "ChronoFocus/Services/TimerEngine.swift"
  "ChronoFocus/Services/NotificationService.swift"
  "ChronoFocus/Services/LiveActivityService.swift"
  "ChronoFocus/Services/TimerPlatformServices.swift"
  "ChronoFocus/Services/PremiumAccessService.swift"
  "ChronoFocus/Services/CalendarSyncService.swift"
  "ChronoFocus/Views/DashboardView.swift"
  "ChronoFocus/Views/TimerView.swift"
  "ChronoFocus/Views/ScheduleView.swift"
  "ChronoFocus/Views/AnalyticsView.swift"
  "ChronoFocus/Views/SettingsView.swift"
  "Shared/PomodoroActivityAttributes.swift"
  "Shared/SharedExtensions.swift"
  "ChronoFocusMac/App/ChronoFocusMacApp.swift"
  "ChronoFocusMac/App/MacStatusBarController.swift"
  "ChronoFocusMac/Services/MacNotificationService.swift"
  "ChronoFocusMac/Services/MacLiveActivityService.swift"
  "ChronoFocusMac/Services/MacPremiumAccessService.swift"
  "ChronoFocusMac/Services/MacCalendarSyncService.swift"
  "ChronoFocusMac/Views/MacTheme.swift"
  "ChronoFocusMac/Views/MacGlassPanel.swift"
  "ChronoFocusMac/Views/MacLinearProgressView.swift"
  "ChronoFocusMac/Views/MacMiniTimerView.swift"
  "ChronoFocusMac/Views/MacDetailView.swift"
  "ChronoFocusMac/Views/MacTimerDetailView.swift"
  "ChronoFocusMac/Views/MacScheduleDetailView.swift"
  "ChronoFocusMac/Views/MacAnalyticsDetailView.swift"
  "ChronoFocusMac/Views/MacSettingsDetailView.swift"
  "ChronoFocusLiveActivity/ChronoFocusLiveActivityBundle.swift"
  "ChronoFocusLiveActivity/ChronoFocusLiveActivity.swift"
  "ChronoFocus.xcodeproj/xcshareddata/xcschemes/ChronoFocus.xcscheme"
  "ChronoFocus.xcodeproj/xcshareddata/xcschemes/ChronoFocusLiveActivity.xcscheme"
  "ChronoFocus.xcodeproj/xcshareddata/xcschemes/ChronoFocusMac.xcscheme"
  "scripts/test_mac_core.swift"
  "scripts/render_mac_snapshots.swift"
)

echo "Checking required files..."
for file in "${required_files[@]}"; do
  test -f "$file"
done

echo "Checking project references..."
for basename in \
  ChronoFocusApp.swift AppModels.swift FocusStore.swift TimerEngine.swift \
  NotificationService.swift LiveActivityService.swift PremiumAccessService.swift CalendarSyncService.swift DashboardView.swift \
  TimerPlatformServices.swift ChronoFocusMacApp.swift MacStatusBarController.swift MacNotificationService.swift \
  MacLiveActivityService.swift MacPremiumAccessService.swift MacCalendarSyncService.swift \
  MacLinearProgressView.swift MacMiniTimerView.swift MacDetailView.swift MacTimerDetailView.swift \
  MacScheduleDetailView.swift MacAnalyticsDetailView.swift MacSettingsDetailView.swift \
  TimerView.swift ScheduleView.swift AnalyticsView.swift SettingsView.swift \
  PomodoroActivityAttributes.swift SharedExtensions.swift \
  ChronoFocusLiveActivityBundle.swift ChronoFocusLiveActivity.swift Assets.xcassets; do
  grep -q "$basename" "$project"
done

echo "Checking Swift observable imports..."
for file in ChronoFocus/Services/*.swift; do
  if grep -q "ObservableObject\|@Published" "$file"; then
    grep -Eq "^import (Combine|SwiftUI)$" "$file"
  fi
done

echo "Checking Live Activity support..."
plutil -extract NSSupportsLiveActivities raw ChronoFocus/Info.plist | grep -q "true"
grep -q "com.apple.widgetkit-extension" ChronoFocusLiveActivity/Info.plist
grep -q "APPLICATION_EXTENSION_API_ONLY = YES" "$project"
grep -q "CodeSignOnCopy" "$project"

echo "Checking shared schemes..."
grep -q "BlueprintIdentifier = \"100000000000000000000501\"" ChronoFocus.xcodeproj/xcshareddata/xcschemes/ChronoFocus.xcscheme
grep -q "BuildableName = \"ChronoFocus.app\"" ChronoFocus.xcodeproj/xcshareddata/xcschemes/ChronoFocus.xcscheme
grep -q "BlueprintIdentifier = \"100000000000000000000502\"" ChronoFocus.xcodeproj/xcshareddata/xcschemes/ChronoFocusLiveActivity.xcscheme
grep -q "BuildableName = \"ChronoFocusLiveActivity.appex\"" ChronoFocus.xcodeproj/xcshareddata/xcschemes/ChronoFocusLiveActivity.xcscheme
grep -q "BlueprintIdentifier = \"200000000000000000000501\"" ChronoFocus.xcodeproj/xcshareddata/xcschemes/ChronoFocusMac.xcscheme
grep -q "BuildableName = \"ChronoFocusMac.app\"" ChronoFocus.xcodeproj/xcshareddata/xcschemes/ChronoFocusMac.xcscheme

echo "Checking visual assets..."
test -f ChronoFocus/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
grep -q "AppIcon-1024.png" ChronoFocus/Assets.xcassets/AppIcon.appiconset/Contents.json

echo "Checking feature implementation markers..."
grep -q "UNTimeIntervalNotificationTrigger" ChronoFocus/Services/NotificationService.swift
grep -q "UNCalendarNotificationTrigger" ChronoFocus/Services/NotificationService.swift
grep -q "scheduleTaskReminder" ChronoFocus/Services/NotificationService.swift
grep -q "syncTaskDueReminders" ChronoFocus/Services/NotificationService.swift
grep -q "cancelTaskReminder" ChronoFocus/Services/NotificationService.swift
grep -q "AVAudioPlayer" ChronoFocus/Services/NotificationService.swift
grep -q "playCompletionAlert" ChronoFocus/Services/NotificationService.swift
grep -q "kSystemSoundID_Vibrate" ChronoFocus/Services/NotificationService.swift
grep -q "AudioServicesPlayAlertSound" ChronoFocus/Services/NotificationService.swift
grep -q "UIApplication.openSettingsURLString" ChronoFocus/Services/NotificationService.swift
grep -q "nextMode:" ChronoFocus/Services/NotificationService.swift
grep -q "import StoreKit" ChronoFocus/Services/PremiumAccessService.swift
grep -q "import EventKit" ChronoFocus/Services/CalendarSyncService.swift
grep -q "requestFullAccessToEvents" ChronoFocus/Services/CalendarSyncService.swift
grep -q "syncUpcomingEvents" ChronoFocus/Services/CalendarSyncService.swift
grep -q "NSCalendarsFullAccessUsageDescription" ChronoFocus/Info.plist
grep -q "proProductID" ChronoFocus/Services/PremiumAccessService.swift
grep -q "purchasePro" ChronoFocus/Services/PremiumAccessService.swift
grep -q "restorePurchases" ChronoFocus/Services/PremiumAccessService.swift
grep -q "isProUnlocked" ChronoFocus/Views/AnalyticsView.swift
grep -q "Pro 工作分析" ChronoFocus/Views/AnalyticsView.swift
grep -q "reportPanel" ChronoFocus/Views/AnalyticsView.swift
grep -q "ReportRange" ChronoFocus/Models/AppModels.swift
grep -q "工作复盘报表" ChronoFocus/Views/AnalyticsView.swift
grep -q "premiumPanel" ChronoFocus/Views/SettingsView.swift
grep -q "taskDueRemindersEnabled" ChronoFocus/Models/AppModels.swift
grep -q "soundVolume" ChronoFocus/Models/AppModels.swift
grep -q "vibrationEnabled" ChronoFocus/Models/AppModels.swift
grep -q "keepScreenAwake" ChronoFocus/Models/AppModels.swift
grep -q "AppThemeMode" ChronoFocus/Models/AppModels.swift
grep -q "appThemeMode" ChronoFocus/Views/TimerView.swift
grep -q "isIdleTimerDisabled" ChronoFocus/Services/TimerEngine.swift
grep -q "finishCurrentTask" ChronoFocus/Services/TimerEngine.swift
grep -q "提醒与屏幕" ChronoFocus/Views/TimerView.swift
grep -q "autoGeneratePomodoroPlan" ChronoFocus/Models/AppModels.swift
grep -q "PomodoroPlanItem" ChronoFocus/Models/AppModels.swift
grep -q "WorkloadAnalysis" ChronoFocus/Models/AppModels.swift
grep -q "CalendarDisplayMode" ChronoFocus/Models/AppModels.swift
grep -q "TaskStartMode" ChronoFocus/Models/AppModels.swift
grep -q "TaskRecurrence" ChronoFocus/Models/AppModels.swift
grep -q "pomodoroPlan" ChronoFocus/Services/FocusStore.swift
grep -q "generatePomodoroPlanFromSchedule" ChronoFocus/Services/FocusStore.swift
grep -q "workloadAnalysis" ChronoFocus/Services/FocusStore.swift
grep -q "autoStartCandidate" ChronoFocus/Services/FocusStore.swift
grep -q "createNextRecurrenceIfNeeded" ChronoFocus/Services/FocusStore.swift
grep -q "upsertExternalTask" ChronoFocus/Services/FocusStore.swift
grep -q "startPlanItem" ChronoFocus/Services/TimerEngine.swift
grep -q "checkScheduledAutoStart" ChronoFocus/Services/TimerEngine.swift
grep -q "PomodoroPlanRow" ChronoFocus/Views/ScheduleView.swift
grep -q "CalendarDayButton" ChronoFocus/Views/ScheduleView.swift
grep -q "iPhone 日历同步" ChronoFocus/Views/ScheduleView.swift
grep -q "日程到期提醒" ChronoFocus/Views/SettingsView.swift
grep -q "nextModeHint" ChronoFocus/Views/TimerView.swift
grep -q "skipToNextSession" ChronoFocus/Services/TimerEngine.swift
grep -q "forward.end.fill" ChronoFocus/Views/TimerView.swift
grep -q "Activity<PomodoroActivityAttributes>" ChronoFocus/Services/LiveActivityService.swift
grep -q "Activity<PomodoroActivityAttributes>.activities.first" ChronoFocus/Services/LiveActivityService.swift
grep -q "ActivityProgressBar" ChronoFocusLiveActivity/ChronoFocusLiveActivity.swift
if grep -q "ProgressView(timerInterval" ChronoFocusLiveActivity/ChronoFocusLiveActivity.swift; then
  echo "Unexpected timerInterval ProgressView initializer in Live Activity widget" >&2
  exit 1
fi
grep -q "activeTimer" ChronoFocus/Services/FocusStore.swift
grep -q "weekBuckets" ChronoFocus/Services/FocusStore.swift
grep -q "dailyGoalMinutes" ChronoFocus/Models/AppModels.swift
grep -q "dailyGoalPanel" ChronoFocus/Views/AnalyticsView.swift
grep -q "TaskEditorView" ChronoFocus/Views/ScheduleView.swift
grep -q "updateTask" ChronoFocus/Services/FocusStore.swift
grep -q "editingTask" ChronoFocus/Views/ScheduleView.swift
grep -q "TaskCategoryPreset" ChronoFocus/Models/AppModels.swift
grep -q "TaskCategoryFilterOption" ChronoFocus/Models/AppModels.swift
grep -q "prioritizedFilterOptions" ChronoFocus/Models/AppModels.swift
grep -q "taskCategories" ChronoFocus/Services/FocusStore.swift
grep -q "TaskCategoryFilterBar" ChronoFocus/Views/ScheduleView.swift
grep -q "TaskCategoryPresetPicker" ChronoFocus/Views/ScheduleView.swift
grep -q "initialCategory: selectedCategory" ChronoFocus/Views/ScheduleView.swift
grep -q "frame(minHeight: 44)" ChronoFocus/Views/ScheduleView.swift
grep -q "selectedTaskCategory" ChronoFocus/Views/TimerView.swift
grep -q "filteredUpcomingTasks" ChronoFocus/Views/TimerView.swift
grep -q "TimerTaskCategoryFilterBar" ChronoFocus/Views/TimerView.swift
grep -q "TimerTaskCategoryBadge" ChronoFocus/Views/TimerView.swift
grep -q "TaskCategoryPreset.prioritizedFilterOptions(categories: categories)" ChronoFocus/Views/TimerView.swift
grep -q "DurationStepper" ChronoFocus/Views/SettingsView.swift
grep -q "LSUIElement = YES" "$project"
grep -q "MACOSX_DEPLOYMENT_TARGET = 14.0" "$project"
grep -q "NSCalendarsFullAccessUsageDescription" "$project"
grep -q "NSStatusBar.system.statusItem" ChronoFocusMac/App/MacStatusBarController.swift
grep -q "NSPopover" ChronoFocusMac/App/MacStatusBarController.swift
grep -q "showDetails(section:" ChronoFocusMac/App/MacStatusBarController.swift
grep -q "MacDetailSelection" ChronoFocusMac/Views/MacDetailView.swift
grep -q "openDetails(.schedule)" ChronoFocusMac/Views/MacMiniTimerView.swift
grep -q "openDetails(.analytics)" ChronoFocusMac/Views/MacMiniTimerView.swift
grep -q "openDetails(.settings)" ChronoFocusMac/Views/MacMiniTimerView.swift
grep -q "CHRONOFOCUS_MAC_OPEN_DETAILS" ChronoFocusMac/App/ChronoFocusMacApp.swift
grep -q "CHRONOFOCUS_MAC_OPEN_POPOVER" ChronoFocusMac/App/ChronoFocusMacApp.swift
grep -q "NavigationSplitView" ChronoFocusMac/Views/MacDetailView.swift
grep -q "MacMiniTimerView" ChronoFocusMac/Views/MacMiniTimerView.swift
grep -q "MacAnalyticsDetailView" ChronoFocusMac/Views/MacAnalyticsDetailView.swift
grep -q "MacStaticTimerActionRowView" ChronoFocusMac/Views/MacTimerDetailView.swift
grep -q "MacStaticScheduleActionChipView" ChronoFocusMac/Views/MacScheduleDetailView.swift
grep -q "MacStaticTaskEnablePillView" ChronoFocusMac/Views/MacScheduleDetailView.swift
grep -q "MacStaticAnalyticsActionChipView" ChronoFocusMac/Views/MacAnalyticsDetailView.swift
grep -q "MacStaticSettingsActionChipView" ChronoFocusMac/Views/MacSettingsDetailView.swift
grep -q "SelectedCategorySummaryView" ChronoFocus/Views/ScheduleView.swift
grep -q "MacSelectedCategorySummaryView" ChronoFocusMac/Views/MacScheduleDetailView.swift
grep -q "SnapshotManifest" scripts/render_mac_snapshots.swift
grep -q "manifest.json" scripts/render_mac_snapshots.swift
grep -q "import StoreKit" ChronoFocusMac/Services/MacPremiumAccessService.swift
grep -q "purchasePro" ChronoFocusMac/Services/MacPremiumAccessService.swift
grep -q "restorePurchases" ChronoFocusMac/Services/MacPremiumAccessService.swift
grep -q "import EventKit" ChronoFocusMac/Services/MacCalendarSyncService.swift
grep -q "requestFullAccessToEvents" ChronoFocusMac/Services/MacCalendarSyncService.swift
grep -q "syncUpcomingEvents" ChronoFocusMac/Services/MacCalendarSyncService.swift
grep -q "Mac 日历同步" ChronoFocusMac/Views/MacScheduleDetailView.swift
grep -q "MacCategoryFilterBar" ChronoFocusMac/Views/MacScheduleDetailView.swift
grep -q "MacCategoryPresetPicker" ChronoFocusMac/Views/MacScheduleDetailView.swift
grep -q 'MacTaskListPanelView(selectedCategory: $selectedCategory)' ChronoFocusMac/Views/MacScheduleDetailView.swift
grep -q "onChange(of: selectedCategory)" ChronoFocusMac/Views/MacScheduleDetailView.swift
grep -q "MacProPreviewPanelView" ChronoFocusMac/Views/MacAnalyticsDetailView.swift
grep -q "MacReportPanelView" ChronoFocusMac/Views/MacAnalyticsDetailView.swift
grep -q "MacCategoryChartPanelView" ChronoFocusMac/Views/MacAnalyticsDetailView.swift
grep -q "MacRecentSessionsPanelView" ChronoFocusMac/Views/MacAnalyticsDetailView.swift

echo "Checking CI result package markers..."
grep -q "IOS_SCHEME: ChronoFocus" .github/workflows/ci-results.yml
grep -q "generic/platform=iOS" .github/workflows/ci-results.yml
grep -q "iosBuildOutcome" .github/workflows/ci-results.yml
grep -q "ChronoFocus-iOS.xcresult" .github/workflows/ci-results.yml
grep -q "ios-xcodebuild.log" .github/workflows/ci-results.yml
grep -q "Failure Excerpts" .github/workflows/ci-results.yml
grep -q "failure_excerpts" .github/workflows/ci-results.yml
grep -q "SnapshotError" .github/workflows/ci-results.yml
grep -q "BUILD FAILED" .github/workflows/ci-results.yml

echo "Running Mac core tests..."
xcrun --sdk macosx swiftc \
  -module-cache-path /tmp/chrono_focus_mac_core_module_cache \
  ChronoFocus/Models/AppModels.swift \
  ChronoFocus/Services/FocusStore.swift \
  Shared/SharedExtensions.swift \
  scripts/test_mac_core.swift \
  -o /tmp/chrono_focus_mac_core_tests
/tmp/chrono_focus_mac_core_tests

echo "Rendering Mac UI snapshots..."
xcrun --sdk macosx swiftc \
  -module-cache-path /tmp/chrono_focus_mac_snapshot_module_cache \
  ChronoFocus/Models/AppModels.swift \
  ChronoFocus/Services/FocusStore.swift \
  ChronoFocus/Services/TimerEngine.swift \
  ChronoFocus/Services/TimerPlatformServices.swift \
  Shared/SharedExtensions.swift \
  ChronoFocusMac/Services/MacNotificationService.swift \
  ChronoFocusMac/Services/MacLiveActivityService.swift \
  ChronoFocusMac/Services/MacPremiumAccessService.swift \
  ChronoFocusMac/Services/MacCalendarSyncService.swift \
  ChronoFocusMac/Views/MacTheme.swift \
  ChronoFocusMac/Views/MacGlassPanel.swift \
  ChronoFocusMac/Views/MacLinearProgressView.swift \
  ChronoFocusMac/Views/MacMiniTimerView.swift \
  ChronoFocusMac/Views/MacDetailView.swift \
  ChronoFocusMac/Views/MacTimerDetailView.swift \
  ChronoFocusMac/Views/MacScheduleDetailView.swift \
  ChronoFocusMac/Views/MacAnalyticsDetailView.swift \
  ChronoFocusMac/Views/MacSettingsDetailView.swift \
  scripts/render_mac_snapshots.swift \
  -o /tmp/chrono_focus_render_mac_snapshots
/tmp/chrono_focus_render_mac_snapshots
test -s /tmp/chronofocus-mac-snapshots/mini-timer.png
test -s /tmp/chronofocus-mac-snapshots/detail-timer.png
test -s /tmp/chronofocus-mac-snapshots/detail-schedule.png
test -s /tmp/chronofocus-mac-snapshots/detail-analytics.png
test -s /tmp/chronofocus-mac-snapshots/detail-settings.png
test -s /tmp/chronofocus-mac-snapshots/manifest.json
python3 - <<'PY'
import json
from pathlib import Path

manifest = json.loads(Path("/tmp/chronofocus-mac-snapshots/manifest.json").read_text())
expected = {
    "mini-timer.png",
    "detail-timer.png",
    "detail-schedule.png",
    "detail-analytics.png",
    "detail-settings.png",
}
snapshots = manifest.get("snapshots", [])
actual = {item.get("fileName") for item in snapshots}
if actual != expected:
    raise SystemExit(f"Unexpected Mac snapshot manifest entries: {sorted(actual)}")
for item in snapshots:
    if item.get("width", 0) <= 0 or item.get("height", 0) <= 0 or item.get("byteCount", 0) <= 0:
        raise SystemExit(f"Invalid Mac snapshot manifest metadata: {item}")
PY

echo "Project structure verified."
