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
  "scripts/validate_ci_artifact.rb"
  "scripts/resolve_ios_simulator_destination.rb"
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
grep -q "soundPanel" ChronoFocus/Views/SettingsView.swift
grep -q "CompletionSound.allCases" ChronoFocus/Views/SettingsView.swift
grep -q "previewCompletionSound" ChronoFocus/Views/SettingsView.swift
grep -q "enforceCompletionSoundAccess" ChronoFocus/Views/SettingsView.swift
grep -q "premium.refreshEntitlements" ChronoFocus/Views/DashboardView.swift
grep -q "store.settings.completionSound.isPro" ChronoFocus/Views/DashboardView.swift
grep -q "taskDueRemindersEnabled" ChronoFocus/Models/AppModels.swift
grep -q "soundVolume" ChronoFocus/Models/AppModels.swift
grep -q "completionSound" ChronoFocus/Models/AppModels.swift
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
grep -q "taskListCountText" ChronoFocus/Views/ScheduleView.swift
grep -q "Text(taskListCountText)" ChronoFocus/Views/ScheduleView.swift
grep -q "onAddTask" ChronoFocus/Views/ScheduleView.swift
grep -q "新增此分类" ChronoFocus/Views/ScheduleView.swift
grep -q "frame(minHeight: 44)" ChronoFocus/Views/ScheduleView.swift
grep -q "selectedTaskCategory" ChronoFocus/Views/TimerView.swift
grep -q "filteredUpcomingTasks" ChronoFocus/Views/TimerView.swift
grep -q "TimerSelectedTaskCategorySummaryView" ChronoFocus/Views/TimerView.swift
grep -q "项可启动" ChronoFocus/Views/TimerView.swift
grep -q "当前筛选" ChronoFocus/Views/TimerView.swift
grep -q "clearTaskCategoryFilter" ChronoFocus/Views/TimerView.swift
grep -q "TimerTaskCategoryFilterBar" ChronoFocus/Views/TimerView.swift
grep -q "TimerTaskCategoryBadge" ChronoFocus/Views/TimerView.swift
grep -q "TaskCategoryPreset.prioritizedFilterOptions(categories: categories)" ChronoFocus/Views/TimerView.swift
ruby <<'RUBY'
def source_slice(path, earlier, later, message)
  source = File.read(path)
  earlier_index = source.index(earlier)
  later_index = source.index(later, earlier_index || 0)
  raise message unless earlier_index && later_index && earlier_index < later_index
  source[earlier_index...later_index]
end

def assert_slice_contains(path, earlier, later, pattern, message)
  segment = source_slice(path, earlier, later, message)
  matched = pattern.is_a?(Regexp) ? segment.match?(pattern) : segment.include?(pattern)
  raise message unless matched
end

def assert_chip_accessibility(path, chip_name, later)
  segment = source_slice(path, "private struct #{chip_name}", later, "#{chip_name} slice missing")
  raise "#{chip_name} must expose selected state text" unless segment.include?("accessibilityStateText") && segment.include?("已选中")
  raise "#{chip_name} must expose filter hint text" unless segment.include?("accessibilityHintText") && segment.include?("筛选\\(title)分类")
  raise "#{chip_name} must expose selected clear hint" unless segment.include?("再次点击清除筛选")
  raise "#{chip_name} must attach accessibility hint" unless segment.include?(".accessibilityHint(accessibilityHintText)")
  raise "#{chip_name} must include selected state in label" unless segment.include?("accessibilityStateText)")
  raise "#{chip_name} must expose selected accessibility trait" unless segment.include?("accessibilityTraits: AccessibilityTraits") && segment.include?(".isSelected") && segment.include?(".accessibilityAddTraits(accessibilityTraits)")
  raise "#{chip_name} must expose Voice Control input labels" unless segment.include?("voiceControlInputLabels: [Text]") && segment.include?("Text(\"\\(title)分类\")") && segment.include?(".accessibilityInputLabels(voiceControlInputLabels)")
end

def assert_preset_picker_accessibility(path, picker_name, later)
  segment = source_slice(path, "private struct #{picker_name}", later, "#{picker_name} slice missing")
  raise "#{picker_name} must expose selected state text" unless segment.include?("accessibilityStateText(for preset: TaskCategoryPreset)") && segment.include?("已选中")
  raise "#{picker_name} must expose preset choice hint" unless segment.include?("accessibilityHintText(for preset: TaskCategoryPreset)") && segment.include?("选择\\(preset.title)分类")
  raise "#{picker_name} must attach accessibility hint" unless segment.include?(".accessibilityHint(accessibilityHintText(for: preset))")
  raise "#{picker_name} must include selected state in label" unless segment.include?("accessibilityStateText(for: preset)")
  raise "#{picker_name} must expose selected accessibility trait" unless segment.include?("accessibilityTraits(for preset: TaskCategoryPreset)") && segment.include?(".isSelected") && segment.include?(".accessibilityAddTraits(accessibilityTraits(for: preset))")
  raise "#{picker_name} must expose Voice Control input labels" unless segment.include?("voiceControlInputLabels(for preset: TaskCategoryPreset)") && segment.include?("Text(\"\\(preset.title)分类\")") && segment.include?(".accessibilityInputLabels(voiceControlInputLabels(for: preset))")
end

assert_slice_contains(
  "ChronoFocus/Views/ScheduleView.swift",
  "SelectedCategorySummaryView(",
  "if visibleTasks.isEmpty",
  /SelectedCategorySummaryView\([\s\S]*?onAddTask:\s*\{\s*showingEditor = true\s*\}[\s\S]*?onClear:\s*\{\s*selectedCategory = nil\s*\}/,
  "Schedule category summary must wire add and clear actions"
)

schedule_summary_source = source_slice(
  "ChronoFocus/Views/ScheduleView.swift",
  "private struct SelectedCategorySummaryView",
  "private struct CalendarDayButton",
  "Schedule category summary source missing"
)
raise "Schedule category summary accessibility label must announce add and clear actions" unless schedule_summary_source.include?("可新增此分类待办或清除筛选")

schedule_source = File.read("ChronoFocus/Views/ScheduleView.swift")
schedule_count_property = schedule_source[/private var taskListCountText: String \{[\s\S]*?\n    \}/]
raise "Schedule task list count text missing" unless schedule_count_property
raise "Schedule task list count text must handle zero total" unless schedule_count_property.include?("totalCount > 0") && schedule_count_property.include?("0 项")
raise "Schedule task list count text must include filtered and total counts" unless schedule_count_property.include?("visibleTasks.count") && schedule_count_property.include?("totalCount") && schedule_count_property.include?("项")

assert_slice_contains(
  "ChronoFocus/Views/TimerView.swift",
  "TimerSelectedTaskCategorySummaryView(",
  "if upcomingTasks.isEmpty",
  /TimerSelectedTaskCategorySummaryView\([\s\S]*?onClear: clearTaskCategoryFilter/,
  "Timer category summary must use clearTaskCategoryFilter"
)

timer_summary_source = source_slice(
  "ChronoFocus/Views/TimerView.swift",
  "private struct TimerSelectedTaskCategorySummaryView",
  "private struct TimerTaskCategoryEmptyView",
  "Timer category summary source missing"
)
raise "Timer category summary accessibility label must announce clear action" unless timer_summary_source.include?("可清除筛选")

assert_slice_contains(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "MacSelectedCategorySummaryView(",
  "if visibleTasks.isEmpty",
  /MacSelectedCategorySummaryView\([\s\S]*?onAddTask:\s*\{\s*onAddTaskInCategory\(selectedCategoryName\)\s*\}[\s\S]*?\)\s*\{\s*selectedCategory = nil\s*\}/,
  "Mac category summary must wire add and clear actions"
)

assert_slice_contains(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "MacTaskListPanelView(",
  ".onChange(of: selectedCategory)",
  /MacTaskListPanelView\([\s\S]*?selectedCategory:\s*\$selectedCategory,[\s\S]*?onAddTaskInCategory:\s*prepareQuickAdd/,
  "Mac task list panel must pass quick add category action"
)

assert_slice_contains(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "private func prepareQuickAdd(_ category: String)",
  "private struct MacQuickAddCategoryContextView",
  /self\.category = category[\s\S]*?accentHex = TaskCategoryPreset\.matching\(category\)\?\.accentHex \?\? "#3DE8C5"[\s\S]*?isTaskTitleFocused = true/,
  "Mac quick add category action must prefill category and focus title"
)

assert_slice_contains(
  "ChronoFocus/Views/ScheduleView.swift",
  "private struct TaskCategoryFilterBar",
  "private struct TaskCategoryFilterChip",
  /toggleCategory\(option\.category\)[\s\S]*?private func toggleCategory\(_ category: String\)[\s\S]*?selectedCategory == category \? nil : category/,
  "Schedule category filter chip must toggle off the selected category"
)

assert_slice_contains(
  "ChronoFocus/Views/TimerView.swift",
  "private struct TimerTaskCategoryFilterBar",
  "private struct TimerTaskCategoryFilterChip",
  /toggleCategory\(option\.category\)[\s\S]*?private func toggleCategory\(_ category: String\)[\s\S]*?selectedCategory == category \? nil : category/,
  "Timer category filter chip must toggle off the selected category"
)

assert_slice_contains(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "private struct MacCategoryFilterBar",
  "private struct MacCategoryFilterChip",
  /toggleCategory\(option\.category\)[\s\S]*?private func toggleCategory\(_ category: String\)[\s\S]*?selectedCategory == category \? nil : category/,
  "Mac category filter chip must toggle off the selected category"
)

assert_chip_accessibility("ChronoFocus/Views/ScheduleView.swift", "TaskCategoryFilterChip", "private struct ScheduleTaskCell")
assert_chip_accessibility("ChronoFocus/Views/TimerView.swift", "TimerTaskCategoryFilterChip", "private struct TimerSelectedTaskCategorySummaryView")
assert_chip_accessibility("ChronoFocusMac/Views/MacScheduleDetailView.swift", "MacCategoryFilterChip", "@MainActor\nprivate func syncMacTaskReminder")
assert_preset_picker_accessibility("ChronoFocus/Views/ScheduleView.swift", "TaskCategoryPresetPicker", "@MainActor\nprivate func syncTaskReminder")
assert_preset_picker_accessibility("ChronoFocusMac/Views/MacScheduleDetailView.swift", "MacCategoryPresetPicker", "private struct MacCategoryFilterBar")
puts "Category chip accessibility contracts verified."
RUBY
grep -q "DurationStepper" ChronoFocus/Views/SettingsView.swift
grep -q "makeToneWavData(for completionSound: CompletionSound)" ChronoFocus/Services/NotificationService.swift
grep -q "completionSound.frequencies" ChronoFocus/Services/NotificationService.swift
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
grep -q "MacMiniTaskCategoryBadgeView" ChronoFocusMac/Views/MacMiniTimerView.swift
grep -q "taskContextText(for task: FocusTask)" ChronoFocusMac/Views/MacMiniTimerView.swift
grep -q "TaskCategoryPreset.matching(task.category)" ChronoFocusMac/Views/MacMiniTimerView.swift
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
grep -q "MacQuickAddCategoryContextView" ChronoFocusMac/Views/MacScheduleDetailView.swift
grep -q "已预填" ChronoFocusMac/Views/MacScheduleDetailView.swift
grep -q "onAddTaskInCategory" ChronoFocusMac/Views/MacScheduleDetailView.swift
grep -q "MacSummaryStaticActionView" ChronoFocusMac/Views/MacScheduleDetailView.swift
grep -q "新增此分类" ChronoFocusMac/Views/MacScheduleDetailView.swift
grep -q "onChange(of: selectedCategory)" ChronoFocusMac/Views/MacScheduleDetailView.swift
grep -q "taskListCountText" ChronoFocusMac/Views/MacScheduleDetailView.swift
grep -q "Text(taskListCountText)" ChronoFocusMac/Views/MacScheduleDetailView.swift
ruby -e 'source = File.read("ChronoFocusMac/Views/MacScheduleDetailView.swift"); property = source[/private var taskListCountText: String \{[\s\S]*?\n    \}/]; raise "Mac task list count text missing" unless property; raise "Mac task list count text must handle zero total" unless property.include?("totalCount > 0") && property.include?("0 项未完成"); raise "Mac task list count text must include filtered and total counts" unless property.include?("visibleTasks.count") && property.include?("totalCount") && property.include?("项未完成")'
grep -q "MacProPreviewPanelView" ChronoFocusMac/Views/MacAnalyticsDetailView.swift
grep -q "MacReportPanelView" ChronoFocusMac/Views/MacAnalyticsDetailView.swift
grep -q "MacCategoryChartPanelView" ChronoFocusMac/Views/MacAnalyticsDetailView.swift
grep -q "MacRecentSessionsPanelView" ChronoFocusMac/Views/MacAnalyticsDetailView.swift

echo "Checking CI result package markers..."
ruby -c scripts/validate_ci_artifact.rb >/dev/null
ruby -c scripts/resolve_ios_simulator_destination.rb >/dev/null
grep -q "ci-artifact-manifest.json" scripts/validate_ci_artifact.rb
grep -q "missingRequiredCount" scripts/validate_ci_artifact.rb
grep -q "Mac core tests passed." scripts/validate_ci_artifact.rb
grep -q "Project structure verified." scripts/validate_ci_artifact.rb
grep -q "Category chip accessibility contracts verified." scripts/validate_ci_artifact.rb
grep -q "BUILD SUCCEEDED" scripts/validate_ci_artifact.rb
grep -q "EXPECTED_SNAPSHOTS" scripts/validate_ci_artifact.rb
grep -q "EXPECTED_INDEX_ENTRIES" scripts/validate_ci_artifact.rb
grep -q "EXPECTED_SUMMARY_ENTRIES" scripts/validate_ci_artifact.rb
grep -q "EXPECTED_STATIC_CHECK_MARKERS" scripts/validate_ci_artifact.rb
grep -q "EXPECTED_JUNIT_TESTCASES" scripts/validate_ci_artifact.rb
grep -q "ci-run-context.txt" scripts/validate_ci_artifact.rb
grep -q "xcode version log" scripts/validate_ci_artifact.rb
grep -q "run context identity" scripts/validate_ci_artifact.rb
grep -q "run context artifact name" scripts/validate_ci_artifact.rb
grep -q "negative_artifact_fixture" scripts/verify_project.sh
grep -q "negative_index_fixture" scripts/verify_project.sh
grep -q "corrupt_index_totals_fixture" scripts/verify_project.sh
grep -q "missing_local_artifact_fixture" scripts/verify_project.sh
grep -q "FAIL run context artifact name" scripts/verify_project.sh
grep -q "FAIL index commit" scripts/verify_project.sh
grep -q "FAIL index totals consistency" scripts/verify_project.sh
grep -q "FAIL index required local artifacts" scripts/verify_project.sh
grep -q "manifest paths" scripts/validate_ci_artifact.rb
grep -q "index required paths" scripts/validate_ci_artifact.rb
grep -q "index required local artifacts" scripts/validate_ci_artifact.rb
grep -q "index totals consistency" scripts/validate_ci_artifact.rb
grep -q "failure summary log entries" scripts/validate_ci_artifact.rb
grep -q "failure summary identity" scripts/validate_ci_artifact.rb
grep -q "failure summary outcomes" scripts/validate_ci_artifact.rb
grep -q "junit testcase names" scripts/validate_ci_artifact.rb
grep -q "xcrun.*simctl" scripts/resolve_ios_simulator_destination.rb
grep -q "platform=iOS Simulator,id=" scripts/resolve_ios_simulator_destination.rb
grep -q "print_build_command" scripts/resolve_ios_simulator_destination.rb
artifact_fixture="$(mktemp -d)"
python3 - "$artifact_fixture" <<'PY'
import json
import os
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path(sys.argv[1])
commit = "fixture-sha"
run_id = "12345"
attempt = "1"

snapshot_dir = root / "project-reports" / "mac-snapshots"
snapshot_dir.mkdir(parents=True)
(root / "ChronoFocusMac.xcresult").mkdir()
(root / "ChronoFocus-iOS.xcresult").mkdir()

files = {
    "static-checks.log": "Running committed diff whitespace check...\nRunning project plist lint...\nRunning workflow YAML parse check...\nyaml ok\n",
    "verify_project.log": "Mac core tests passed.\nCategory chip accessibility contracts verified.\nProject structure verified.\n",
    "xcodebuild.log": "** BUILD SUCCEEDED **\n",
    "ios-xcodebuild.log": "** BUILD SUCCEEDED **\n",
    "xcode-version.log": "Xcode 16.0\nBuild version 16A000\n",
    "ci-run-context.txt": f"artifactName=chronofocus-ci-v0.10-main-fixture-run{run_id}-attempt{attempt}\nbranch=main\ncommitSha={commit}\nrunId={run_id}\nrunAttempt={attempt}\n",
}

for relative_path, content in files.items():
    (root / relative_path).write_text(content, encoding="utf-8")

(root / "ChronoFocusMac.xcresult" / "Info.plist").write_text("mac result\n", encoding="utf-8")
(root / "ChronoFocus-iOS.xcresult" / "Info.plist").write_text("ios result\n", encoding="utf-8")

snapshots = [
    "mini-timer.png",
    "detail-timer.png",
    "detail-schedule.png",
    "detail-analytics.png",
    "detail-settings.png",
]
for name in snapshots:
    (snapshot_dir / name).write_bytes(b"png-data")

snapshot_manifest = {
    "generatedAt": "2026-07-04T00:00:00Z",
    "snapshots": [
        {"fileName": name, "width": 100, "height": 80, "byteCount": 8}
        for name in snapshots
    ],
}
(snapshot_dir / "manifest.json").write_text(
    json.dumps(snapshot_manifest, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

summary = f"""# ChronoFocus CI Failure Summary

- Version: `v0.10`
- Branch: `main`
- Commit: `{commit}`
- Run: `{run_id}` attempt `{attempt}`
- Static checks: `success`
- Project verification: `success`
- Mac build: `success`
- iOS build: `success`

## Logs

- Static checks: `ci-results/static-checks.log`
- Project verification: `ci-results/verify_project.log`
- Mac build: `ci-results/xcodebuild.log`
- Xcode result bundle: `ci-results/ChronoFocusMac.xcresult`
- iOS build: `ci-results/ios-xcodebuild.log`
- iOS Xcode result bundle: `ci-results/ChronoFocus-iOS.xcresult`
- Mac snapshots: `ci-results/project-reports/mac-snapshots/`

All CI stages passed.
"""
(root / "ci-failure-summary.md").write_text(summary, encoding="utf-8")

tests = [
    ("staticChecks", "ci-results/static-checks.log"),
    ("projectVerification", "ci-results/verify_project.log"),
    ("macBuild", "ci-results/xcodebuild.log"),
    ("iosBuild", "ci-results/ios-xcodebuild.log"),
]
suite = ET.Element("testsuite", name="ChronoFocus CI Results", tests="4", failures="0")
for name, log_path in tests:
    case = ET.SubElement(suite, "testcase", name=name, classname="ChronoFocusCI")
    ET.SubElement(case, "system-out").text = f"outcome=success; log={log_path}"
ET.ElementTree(suite).write(root / "junit.xml", encoding="utf-8", xml_declaration=True)

manifest = {
    "version": "v0.10",
    "branch": "main",
    "commitSha": commit,
    "runId": run_id,
    "runAttempt": attempt,
    "workflowName": "ChronoFocus CI Results",
    "resultBundlePath": "ci-results/ChronoFocusMac.xcresult",
    "macResultBundlePath": "ci-results/ChronoFocusMac.xcresult",
    "iosResultBundlePath": "ci-results/ChronoFocus-iOS.xcresult",
    "junitPath": "ci-results/junit.xml",
    "buildLogPath": "ci-results/xcodebuild.log",
    "macBuildLogPath": "ci-results/xcodebuild.log",
    "iosBuildLogPath": "ci-results/ios-xcodebuild.log",
    "failureSummaryPath": "ci-results/ci-failure-summary.md",
    "artifactIndexPath": "ci-results/ci-artifact-index.json",
    "staticChecksOutcome": "success",
    "projectVerificationOutcome": "success",
    "buildOutcome": "success",
    "macBuildOutcome": "success",
    "iosBuildOutcome": "success",
    "testOutcome": "success",
}
(root / "ci-artifact-manifest.json").write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
(root / "ci-artifact-index.json").write_text("{}\n", encoding="utf-8")

index_paths = [
    "ci-results/ci-artifact-manifest.json",
    "ci-results/ci-artifact-index.json",
    "ci-results/ci-failure-summary.md",
    "ci-results/junit.xml",
    "ci-results/static-checks.log",
    "ci-results/verify_project.log",
    "ci-results/xcodebuild.log",
    "ci-results/ios-xcodebuild.log",
    "ci-results/xcode-version.log",
    "ci-results/ci-run-context.txt",
    "ci-results/ChronoFocusMac.xcresult",
    "ci-results/ChronoFocus-iOS.xcresult",
    "ci-results/project-reports/mac-snapshots",
    "ci-results/project-reports/mac-snapshots/manifest.json",
    "ci-results/project-reports/mac-snapshots/mini-timer.png",
    "ci-results/project-reports/mac-snapshots/detail-timer.png",
    "ci-results/project-reports/mac-snapshots/detail-schedule.png",
    "ci-results/project-reports/mac-snapshots/detail-analytics.png",
    "ci-results/project-reports/mac-snapshots/detail-settings.png",
]

def local_path(contract_path):
    prefix = "ci-results/"
    relative_path = contract_path[len(prefix):] if contract_path.startswith(prefix) else contract_path
    return root / relative_path

def metadata(contract_path):
    path = local_path(contract_path)
    entry = {"path": contract_path, "required": True, "exists": path.exists()}
    if path.is_file():
        entry.update({"kind": "file", "byteCount": path.stat().st_size})
    elif path.is_dir():
        files = [child for child in path.rglob("*") if child.is_file()]
        entry.update({
            "kind": "directory",
            "fileCount": len(files),
            "recursiveByteCount": sum(child.stat().st_size for child in files),
        })
    else:
        entry["kind"] = "missing"
    return entry

index = {
    "version": "v0.10",
    "branch": "main",
    "commitSha": commit,
    "runId": run_id,
    "runAttempt": attempt,
    "entries": [metadata(path) for path in index_paths],
}
index["totals"] = {
    "entryCount": len(index["entries"]),
    "missingRequiredCount": sum(
        1 for entry in index["entries"]
        if entry["required"] and not entry["exists"]
    ),
    "fileByteCount": sum(entry.get("byteCount", 0) for entry in index["entries"]),
    "directoryRecursiveByteCount": sum(
        entry.get("recursiveByteCount", 0) for entry in index["entries"]
    ),
}
(root / "ci-artifact-index.json").write_text(
    json.dumps(index, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
PY
ruby scripts/validate_ci_artifact.rb "$artifact_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >/dev/null
negative_artifact_fixture="$(mktemp -d)"
negative_artifact_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_artifact_fixture"/
python3 - "$negative_artifact_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
(root / "ci-run-context.txt").write_text(
    "artifactName=chronofocus-ci-v0.10-main-wrong-run12345-attempt1\n"
    "branch=main\n"
    "commitSha=fixture-sha\n"
    "runId=12345\n"
    "runAttempt=1\n",
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_artifact_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_artifact_output" 2>&1; then
  echo "Expected negative artifact fixture to fail validation" >&2
  cat "$negative_artifact_output" >&2
  exit 1
fi
grep -q "FAIL run context artifact name" "$negative_artifact_output"
rm -rf "$negative_artifact_fixture"
rm -f "$negative_artifact_output"
negative_index_fixture="$(mktemp -d)"
negative_index_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_index_fixture"/
python3 - "$negative_index_fixture" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
index_path = root / "ci-artifact-index.json"
index = json.loads(index_path.read_text(encoding="utf-8"))
index["commitSha"] = "stale-index-sha"
index_path.write_text(
    json.dumps(index, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_index_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_index_output" 2>&1; then
  echo "Expected negative index fixture to fail validation" >&2
  cat "$negative_index_output" >&2
  exit 1
fi
grep -q "FAIL index commit" "$negative_index_output"
rm -rf "$negative_index_fixture"
rm -f "$negative_index_output"
corrupt_index_totals_fixture="$(mktemp -d)"
corrupt_index_totals_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$corrupt_index_totals_fixture"/
python3 - "$corrupt_index_totals_fixture" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
index_path = root / "ci-artifact-index.json"
index = json.loads(index_path.read_text(encoding="utf-8"))
index["totals"]["fileByteCount"] += 1
index_path.write_text(
    json.dumps(index, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$corrupt_index_totals_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$corrupt_index_totals_output" 2>&1; then
  echo "Expected corrupt index totals fixture to fail validation" >&2
  cat "$corrupt_index_totals_output" >&2
  exit 1
fi
grep -q "FAIL index totals consistency" "$corrupt_index_totals_output"
rm -rf "$corrupt_index_totals_fixture"
rm -f "$corrupt_index_totals_output"
missing_local_artifact_fixture="$(mktemp -d)"
missing_local_artifact_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$missing_local_artifact_fixture"/
rm -f "$missing_local_artifact_fixture/static-checks.log"
if ruby scripts/validate_ci_artifact.rb "$missing_local_artifact_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$missing_local_artifact_output" 2>&1; then
  echo "Expected missing local artifact fixture to fail validation" >&2
  cat "$missing_local_artifact_output" >&2
  exit 1
fi
grep -q "FAIL index required local artifacts" "$missing_local_artifact_output"
rm -rf "$missing_local_artifact_fixture"
rm -f "$missing_local_artifact_output"
rm -rf "$artifact_fixture"
simctl_fixture="$(mktemp)"
python3 - "$simctl_fixture" <<'PY'
import json
import sys

payload = {
    "devices": {
        "com.apple.CoreSimulator.SimRuntime.iOS-18-5": [
            {
                "name": "iPhone 16",
                "udid": "11111111-1111-1111-1111-111111111111",
                "state": "Shutdown",
                "isAvailable": True,
            },
            {
                "name": "iPhone 15",
                "udid": "22222222-2222-2222-2222-222222222222",
                "state": "Booted",
                "isAvailable": True,
            },
        ],
        "com.apple.CoreSimulator.SimRuntime.watchOS-11-0": [
            {
                "name": "Apple Watch",
                "udid": "33333333-3333-3333-3333-333333333333",
                "state": "Booted",
                "isAvailable": True,
            }
        ],
    }
}

with open(sys.argv[1], "w", encoding="utf-8") as handle:
    json.dump(payload, handle)
PY
ruby scripts/resolve_ios_simulator_destination.rb --simctl-json "$simctl_fixture" | grep -q "platform=iOS Simulator,id=22222222-2222-2222-2222-222222222222"
ruby scripts/resolve_ios_simulator_destination.rb --simctl-json "$simctl_fixture" --name "iPhone 16" | grep -q "platform=iOS Simulator,id=11111111-1111-1111-1111-111111111111"
ruby scripts/resolve_ios_simulator_destination.rb --simctl-json "$simctl_fixture" --print-build-command | grep -q "xcodebuild .*ChronoFocus.xcodeproj.*platform\\\\=iOS\\\\ Simulator,id\\\\=22222222-2222-2222-2222-222222222222"
rm -f "$simctl_fixture"
grep -q "IOS_SCHEME: ChronoFocus" .github/workflows/ci-results.yml
grep -q "generic/platform=iOS" .github/workflows/ci-results.yml
grep -q "iosBuildOutcome" .github/workflows/ci-results.yml
grep -q "ChronoFocus-iOS.xcresult" .github/workflows/ci-results.yml
grep -q "ios-xcodebuild.log" .github/workflows/ci-results.yml
grep -q "Failure Excerpts" .github/workflows/ci-results.yml
grep -q "failure_excerpts" .github/workflows/ci-results.yml
grep -q "SnapshotError" .github/workflows/ci-results.yml
grep -q "BUILD FAILED" .github/workflows/ci-results.yml
grep -q "ci-artifact-index.json" .github/workflows/ci-results.yml
grep -q "artifactIndexPath" .github/workflows/ci-results.yml
grep -q "path_metadata" .github/workflows/ci-results.yml
grep -q "recursiveByteCount" .github/workflows/ci-results.yml

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
