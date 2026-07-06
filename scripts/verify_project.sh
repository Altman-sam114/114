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

def segment_slice(source, earlier, later, message)
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

def assert_calendar_day_accessibility(path, day_name, later)
  segment = source_slice(path, "private struct #{day_name}", later, "#{day_name} slice missing")
  raise "#{day_name} must expose date text" unless segment.include?("accessibilityDateText") && segment.include?("M月d日 E")
  raise "#{day_name} must expose selected and muted state text" unless segment.include?("accessibilityStateText") && segment.include?("已选中") && segment.include?("非本月")
  raise "#{day_name} must expose date choice hint" unless segment.include?("accessibilityHintText") && segment.include?("当前正在查看此日期的待办") && segment.include?("选择此日期查看待办")
  raise "#{day_name} must expose selected trait" unless segment.include?("accessibilityTraits: AccessibilityTraits") && segment.include?(".isSelected") && segment.include?(".accessibilityAddTraits(accessibilityTraits)")
  raise "#{day_name} must expose Voice Control input labels" unless segment.include?("voiceControlInputLabels: [Text]") && segment.include?("Text(accessibilityDateText)") && segment.include?("Text(\"选择\\(accessibilityDateText)\")") && segment.include?("Text(\"\\(dayText)日\")") && segment.include?(".accessibilityInputLabels(voiceControlInputLabels)")
  raise "#{day_name} must include date, count, and state in label" unless segment.include?(".accessibilityLabel(\"\\(accessibilityDateText)，\\(taskCount)项待办\\(accessibilityStateText)\")")
  raise "#{day_name} must attach accessibility hint" unless segment.include?(".accessibilityHint(accessibilityHintText)")
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
schedule_summary_add_button = segment_slice(
  schedule_summary_source,
  "Button(\"新增此分类\", systemImage: \"plus.circle.fill\", action: onAddTask)",
  "Button(\"清除\", systemImage: \"xmark.circle.fill\", action: onClear)",
  "Schedule category summary add button source missing"
)
raise "Schedule category summary add button tap target missing" unless schedule_summary_add_button.include?(".frame(maxWidth: .infinity)") && schedule_summary_add_button.include?(".frame(minHeight: 44)")
raise "Schedule category summary add accessibility label missing" unless schedule_summary_add_button.include?(".accessibilityLabel(\"新增\\(category)分类待办\")")
raise "Schedule category summary add Voice Control input labels missing" unless schedule_summary_add_button.include?(".accessibilityInputLabels([Text(\"新增此分类\"), Text(\"新增\\(category)分类待办\"), Text(\"新增\\(category)分类\")])")
schedule_summary_clear_button = segment_slice(
  schedule_summary_source,
  "Button(\"清除\", systemImage: \"xmark.circle.fill\", action: onClear)",
  ".accessibilityElement(children: .contain)",
  "Schedule category summary clear button source missing"
)
raise "Schedule category summary clear button tap target missing" unless schedule_summary_clear_button.include?(".frame(minWidth: 72)") && schedule_summary_clear_button.include?(".frame(minHeight: 44)")
raise "Schedule category summary clear accessibility label missing" unless schedule_summary_clear_button.include?(".accessibilityLabel(\"清除\\(category)分类筛选\")")
raise "Schedule category summary clear Voice Control input labels missing" unless schedule_summary_clear_button.include?(".accessibilityInputLabels([Text(\"清除筛选\"), Text(\"清除\\(category)分类\")])")

schedule_source = File.read("ChronoFocus/Views/ScheduleView.swift")
schedule_count_property = schedule_source[/private var taskListCountText: String \{[\s\S]*?\n    \}/]
raise "Schedule task list count text missing" unless schedule_count_property
raise "Schedule task list count text must handle zero total" unless schedule_count_property.include?("totalCount > 0") && schedule_count_property.include?("0 项")
raise "Schedule task list count text must include filtered and total counts" unless schedule_count_property.include?("visibleTasks.count") && schedule_count_property.include?("totalCount") && schedule_count_property.include?("项")
schedule_add_toolbar_source = source_slice(
  "ChronoFocus/Views/ScheduleView.swift",
  "private var addTaskAccessibilityLabel",
  "private var calendarPanel",
  "Schedule toolbar add source missing"
)
raise "Schedule toolbar add accessibility label helper missing category context" unless schedule_add_toolbar_source.include?("private var addTaskAccessibilityLabel: String") && schedule_add_toolbar_source.include?("return \"新增\\(selectedCategory)分类待办\"")
raise "Schedule toolbar add accessibility hint helper missing category prefill" unless schedule_add_toolbar_source.include?("private var addTaskAccessibilityHint: String") && schedule_add_toolbar_source.include?("预填\\(selectedCategory)分类")
raise "Schedule toolbar add Voice Control labels helper missing category context" unless schedule_add_toolbar_source.include?("private var addTaskInputLabels: [Text]") && schedule_add_toolbar_source.include?("Text(\"新增此分类\")") && schedule_add_toolbar_source.include?("Text(\"新增\\(selectedCategory)分类待办\")") && schedule_add_toolbar_source.include?("Text(\"新增\\(selectedCategory)分类\")")
raise "Schedule toolbar add button missing accessibility label helper" unless schedule_add_toolbar_source.include?(".accessibilityLabel(addTaskAccessibilityLabel)")
raise "Schedule toolbar add button missing accessibility hint helper" unless schedule_add_toolbar_source.include?(".accessibilityHint(addTaskAccessibilityHint)")
raise "Schedule toolbar add button missing Voice Control labels helper" unless schedule_add_toolbar_source.include?(".accessibilityInputLabels(addTaskInputLabels)")
puts "Schedule toolbar add category context contracts verified."

schedule_task_cell = source_slice(
  "ChronoFocus/Views/ScheduleView.swift",
  "private struct ScheduleTaskCell",
  "private struct TaskEditorView",
  "Schedule task cell source missing"
)
raise "Schedule task cell category preset missing" unless schedule_task_cell.include?("TaskCategoryPreset.matching(task.category)")
raise "Schedule task cell category symbol missing" unless schedule_task_cell.include?("private var categorySymbolName")
raise "Schedule task cell category badge missing" unless schedule_task_cell.include?("Label(task.category, systemImage: categorySymbolName)")
raise "Schedule task cell category accessibility label missing" unless schedule_task_cell.include?(".accessibilityLabel(\"\\(task.category)分类\")")
raise "Schedule task cell category Voice Control input labels missing" unless schedule_task_cell.include?(".accessibilityInputLabels([Text(task.category), Text(\"\\(task.category)分类\")])")
raise "Schedule task cell must keep due date as secondary metadata" unless schedule_task_cell.include?("if let dueDate = task.dueDate") && schedule_task_cell.include?("dueDate.scheduleTimeText")
raise "Schedule task completion action accessibility label missing task title" unless schedule_task_cell.include?(".accessibilityLabel(task.isDone ? \"标记\\(task.title)待办未完成\" : \"完成\\(task.title)待办\")")
raise "Schedule task completion action Voice Control labels missing task title" unless schedule_task_cell.include?("Text(task.isDone ? \"标记\\(task.title)未完成\" : \"完成\\(task.title)\")") && schedule_task_cell.include?("Text(task.isDone ? \"\\(task.title)未完成\" : \"\\(task.title)完成\")")
raise "Schedule task enable action accessibility label missing task title" unless schedule_task_cell.include?(".accessibilityLabel(task.isEnabled ? \"停用\\(task.title)待办\" : \"启用\\(task.title)待办\")")
raise "Schedule task enable action Voice Control labels missing task title" unless schedule_task_cell.include?("Text(task.isEnabled ? \"停用\\(task.title)\" : \"启用\\(task.title)\")") && schedule_task_cell.include?("Text(task.isEnabled ? \"\\(task.title)停用\" : \"\\(task.title)启用\")")
raise "Schedule task edit action accessibility label missing task title" unless schedule_task_cell.include?(".accessibilityLabel(\"编辑\\(task.title)待办\")")
raise "Schedule task edit action Voice Control labels missing task title" unless schedule_task_cell.include?("Text(\"编辑\\(task.title)\")") && schedule_task_cell.include?("Text(\"\\(task.title)编辑\")")

pomodoro_plan_row = File.read("ChronoFocus/Views/ScheduleView.swift")[/private struct PomodoroPlanRow[\s\S]*\z/]
raise "PomodoroPlanRow source missing" unless pomodoro_plan_row
raise "iOS plan start accessibility label missing task, time, round, and category" unless pomodoro_plan_row.include?(".accessibilityLabel(\"开始\\(item.taskTitle)计划番茄钟，\\(item.timeRangeText)，第 \\(item.roundNumber) 轮，\\(item.category)分类\")")
raise "iOS plan start Voice Control labels missing task context" unless pomodoro_plan_row.include?("Text(\"开始\\(item.taskTitle)\")") && pomodoro_plan_row.include?("Text(\"\\(item.taskTitle)第 \\(item.roundNumber) 轮\")") && pomodoro_plan_row.include?("Text(\"\\(item.category)分类开始\")")
raise "iOS plan category badge preset missing" unless pomodoro_plan_row.include?("private var categoryPreset: TaskCategoryPreset?") && pomodoro_plan_row.include?("TaskCategoryPreset.matching(item.category)")
raise "iOS plan category badge tint fallback missing" unless pomodoro_plan_row.include?("private var categoryTint: Color") && pomodoro_plan_row.include?("categoryPreset?.accentHex ?? item.accentHex")
raise "iOS plan category badge symbol fallback missing" unless pomodoro_plan_row.include?("private var categorySymbolName: String") && pomodoro_plan_row.include?("categoryPreset?.symbolName ?? \"tag.fill\"")
raise "iOS plan category badge visible label missing" unless pomodoro_plan_row.include?("Label(item.category, systemImage: categorySymbolName)")
raise "iOS plan category badge accessibility missing" unless pomodoro_plan_row.include?(".accessibilityLabel(\"\\(item.category)分类\")") && pomodoro_plan_row.include?(".accessibilityInputLabels([Text(item.category), Text(\"\\(item.category)分类\")])")

schedule_plan_panel = source_slice(
  "ChronoFocus/Views/ScheduleView.swift",
  "private var pomodoroPlanPanel",
  "private var taskList",
  "Schedule pomodoro plan panel source missing"
)
raise "iOS plan panel remaining count helper missing" unless File.read("ChronoFocus/Views/ScheduleView.swift").include?("private var remainingPlanCount: Int") && schedule_plan_panel.include?("remainingPlanCount")
raise "iOS plan generate accessibility label missing count" unless schedule_plan_panel.include?(".accessibilityLabel(\"按日程生成番茄钟计划，当前\\(remainingPlanCount)轮未完成\")")
raise "iOS plan generate Voice Control labels missing" unless schedule_plan_panel.include?("Text(\"按日程生成\")") && schedule_plan_panel.include?("Text(\"生成番茄钟计划\")") && schedule_plan_panel.include?("Text(\"生成\\(remainingPlanCount)轮计划\")")
raise "iOS plan clear accessibility label missing count" unless schedule_plan_panel.include?(".accessibilityLabel(\"清空番茄钟计划，当前\\(remainingPlanCount)轮未完成\")")
raise "iOS plan clear Voice Control labels missing" unless schedule_plan_panel.include?("Text(\"清空番茄钟计划\")") && schedule_plan_panel.include?("Text(\"清空\\(remainingPlanCount)轮计划\")")

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
raise "Timer category summary clear button missing" unless timer_summary_source.include?("Button(\"清除\", systemImage: \"xmark.circle.fill\", action: onClear)")
raise "Timer category summary clear button tap target missing" unless timer_summary_source.include?(".frame(minWidth: 72)") && timer_summary_source.include?(".frame(minHeight: 44)")
raise "Timer category summary clear accessibility label missing" unless timer_summary_source.include?(".accessibilityLabel(\"清除\\(category)分类筛选\")")
raise "Timer category summary clear Voice Control input labels missing" unless timer_summary_source.include?(".accessibilityInputLabels([Text(\"清除筛选\"), Text(\"清除\\(category)分类\")])")

timer_empty_source = source_slice(
  "ChronoFocus/Views/TimerView.swift",
  "private struct TimerTaskCategoryEmptyView",
  "private struct TimerTaskCategoryBadge",
  "Timer category empty view source missing"
)
raise "Timer category empty view preset missing" unless timer_empty_source.include?("TaskCategoryPreset.matching(category)")
raise "Timer category empty clear button missing" unless timer_empty_source.include?("Button(\"清除\", systemImage: \"xmark.circle.fill\", action: onClear)")
raise "Timer category empty clear button tap target missing" unless timer_empty_source.include?(".frame(minWidth: 72)") && timer_empty_source.include?(".frame(minHeight: 44)")
raise "Timer category empty clear accessibility label missing" unless timer_empty_source.include?(".accessibilityLabel(\"清除\\(category)分类筛选\")")
raise "Timer category empty clear Voice Control input labels missing" unless timer_empty_source.include?(".accessibilityInputLabels([Text(\"清除筛选\"), Text(\"清除\\(category)分类\")])")
raise "Timer category empty state accessibility label missing" unless timer_empty_source.include?(".accessibilityLabel(\"\\(category)分类暂无可启动待办，可清除筛选\")")

timer_task_badge = source_slice(
  "ChronoFocus/Views/TimerView.swift",
  "private struct TimerTaskCategoryBadge",
  "private struct IconActionButtonStyle",
  "Timer task category badge source missing"
)
raise "Timer task category badge preset missing" unless timer_task_badge.include?("TaskCategoryPreset.matching(task.category)")
raise "Timer task category badge symbol missing" unless timer_task_badge.include?("private var categorySymbolName")
raise "Timer task category badge label missing" unless timer_task_badge.include?("Label(task.category, systemImage: categorySymbolName)")
raise "Timer task category badge accessibility label missing" unless timer_task_badge.include?(".accessibilityLabel(\"\\(task.category)分类\")")
raise "Timer task category badge Voice Control input labels missing" unless timer_task_badge.include?(".accessibilityInputLabels([Text(task.category), Text(\"\\(task.category)分类\")])")

assert_slice_contains(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "MacSelectedCategorySummaryView(",
  "if visibleTasks.isEmpty",
  /MacSelectedCategorySummaryView\([\s\S]*?onAddTask:\s*\{\s*onAddTaskInCategory\(selectedCategoryName\)\s*\}[\s\S]*?\)\s*\{\s*selectedCategory = nil\s*\}/,
  "Mac category summary must wire add and clear actions"
)

mac_schedule_summary_source = source_slice(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "private struct MacSelectedCategorySummaryView",
  "private struct MacSummaryStaticActionView",
  "Mac category summary source missing"
)
raise "Mac category summary must keep child accessibility elements" unless mac_schedule_summary_source.include?(".accessibilityElement(children: .contain)")
mac_schedule_summary_add_button = segment_slice(
  mac_schedule_summary_source,
  "Button(\"新增此分类\", systemImage: \"plus.circle.fill\", action: onAddTask)",
  "Button(\"清除\", systemImage: \"xmark.circle.fill\", action: onClear)",
  "Mac category summary add button source missing"
)
raise "Mac category summary add accessibility label missing" unless mac_schedule_summary_add_button.include?(".accessibilityLabel(\"新增\\(category)分类待办\")")
raise "Mac category summary add Voice Control input labels missing" unless mac_schedule_summary_add_button.include?(".accessibilityInputLabels([Text(\"新增此分类\"), Text(\"新增\\(category)分类待办\"), Text(\"新增\\(category)分类\")])")
raise "Mac category summary add button tap target missing" unless mac_schedule_summary_add_button.include?(".frame(minWidth: 104, minHeight: 36)")
mac_schedule_summary_clear_button = segment_slice(
  mac_schedule_summary_source,
  "Button(\"清除\", systemImage: \"xmark.circle.fill\", action: onClear)",
  ".accessibilityElement(children: .contain)",
  "Mac category summary clear button source missing"
)
raise "Mac category summary clear accessibility label missing" unless mac_schedule_summary_clear_button.include?(".accessibilityLabel(\"清除\\(category)分类筛选\")")
raise "Mac category summary clear Voice Control input labels missing" unless mac_schedule_summary_clear_button.include?(".accessibilityInputLabels([Text(\"清除筛选\"), Text(\"清除\\(category)分类\")])")
raise "Mac category summary clear button tap target missing" unless mac_schedule_summary_clear_button.include?(".frame(minWidth: 72, minHeight: 36)")
mac_summary_static_action_source = source_slice(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "private struct MacSummaryStaticActionView",
  "private struct MacCategoryPresetPicker",
  "Mac summary static action source missing"
)
raise "Mac summary static action tap target missing" unless mac_summary_static_action_source.include?(".frame(minWidth: isProminent ? 104 : 72, minHeight: 36)")
puts "Category summary action contracts verified."

mac_task_list_source = source_slice(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "private struct MacTaskListPanelView",
  "private struct MacSelectedCategorySummaryView",
  "Mac task list panel source missing"
)
raise "Mac task completion static accessibility label missing task title" unless mac_task_list_source.include?("title: task.isDone ? \"标记\\(task.title)待办未完成\" : \"完成\\(task.title)待办\"")
raise "Mac task completion action accessibility label missing task title" unless mac_task_list_source.include?(".accessibilityLabel(task.isDone ? \"标记\\(task.title)待办未完成\" : \"完成\\(task.title)待办\")")
raise "Mac task completion action Voice Control labels missing task title" unless mac_task_list_source.include?("Text(task.isDone ? \"标记\\(task.title)未完成\" : \"完成\\(task.title)\")") && mac_task_list_source.include?("Text(task.isDone ? \"\\(task.title)未完成\" : \"\\(task.title)完成\")")
raise "Mac task enable static accessibility label missing task title" unless mac_task_list_source.include?("MacStaticTaskEnablePillView(isEnabled: task.isEnabled, taskTitle: task.title)")
raise "Mac task enable action accessibility label missing task title" unless mac_task_list_source.include?(".accessibilityLabel(task.isEnabled ? \"停用\\(task.title)待办\" : \"启用\\(task.title)待办\")")
raise "Mac task enable action Voice Control labels missing task title" unless mac_task_list_source.include?("Text(task.isEnabled ? \"停用\\(task.title)\" : \"启用\\(task.title)\")") && mac_task_list_source.include?("Text(task.isEnabled ? \"\\(task.title)停用\" : \"\\(task.title)启用\")")
raise "Mac task delete static accessibility label missing task title" unless mac_task_list_source.include?("MacStaticScheduleActionChipView(title: \"删除\\(task.title)待办\"")
raise "Mac task delete action accessibility label missing task title" unless mac_task_list_source.include?(".accessibilityLabel(\"删除\\(task.title)待办\")")
raise "Mac task delete action Voice Control labels missing task title" unless mac_task_list_source.include?("Text(\"删除\\(task.title)\")") && mac_task_list_source.include?("Text(\"\\(task.title)删除\")")
mac_static_enable_source = source_slice(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "private struct MacStaticTaskEnablePillView",
  "private struct MacCalendarPanelView",
  "Mac static task enable pill source missing"
)
raise "Mac static task enable pill task title semantics missing" unless mac_static_enable_source.include?("var taskTitle: String?") && mac_static_enable_source.include?("return isEnabled ? \"\\(taskTitle)待办已启用\" : \"\\(taskTitle)待办已停用\"")
puts "Schedule task action accessibility contracts verified."

mac_plan_source = source_slice(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "ForEach(store.pomodoroPlan.prefix(6))",
  "private struct MacTaskListPanelView",
  "Mac pomodoro plan source missing"
)
mac_plan_panel_source = source_slice(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "private struct MacPlanPanelView",
  "private struct MacTaskListPanelView",
  "Mac pomodoro plan panel source missing"
)
raise "Mac plan static start accessibility label missing task, time, round, and category" unless mac_plan_source.include?("MacStaticScheduleActionChipView(title: \"开始\\(item.taskTitle)计划番茄钟，\\(item.timeRangeText)，第 \\(item.roundNumber) 轮，\\(item.category)分类\"")
raise "Mac plan start accessibility label missing task, time, round, and category" unless mac_plan_source.include?(".accessibilityLabel(\"开始\\(item.taskTitle)计划番茄钟，\\(item.timeRangeText)，第 \\(item.roundNumber) 轮，\\(item.category)分类\")")
raise "Mac plan start Voice Control labels missing task context" unless mac_plan_source.include?("Text(\"开始\\(item.taskTitle)\")") && mac_plan_source.include?("Text(\"\\(item.taskTitle)第 \\(item.roundNumber) 轮\")")
puts "Plan start action accessibility contracts verified."
raise "Mac plan category badge view missing" unless mac_plan_source.include?("MacPlanCategoryBadgeView(item: item)")
raise "Mac plan category badge preset missing" unless mac_plan_source.include?("private var categoryPreset: TaskCategoryPreset?") && mac_plan_source.include?("TaskCategoryPreset.matching(item.category)")
raise "Mac plan category badge tint fallback missing" unless mac_plan_source.include?("private var categoryTint: Color") && mac_plan_source.include?("categoryPreset?.accentHex ?? item.accentHex")
raise "Mac plan category badge symbol fallback missing" unless mac_plan_source.include?("private var categorySymbolName: String") && mac_plan_source.include?("categoryPreset?.symbolName ?? \"tag.fill\"")
raise "Mac plan category badge visible label missing" unless mac_plan_source.include?("Label(item.category, systemImage: categorySymbolName)")
raise "Mac plan category badge accessibility missing" unless mac_plan_source.include?(".accessibilityLabel(\"\\(item.category)分类\")") && mac_plan_source.include?(".accessibilityInputLabels([Text(item.category), Text(\"\\(item.category)分类\")])")
raise "Mac plan start Voice Control category label missing" unless mac_plan_source.include?("Text(\"\\(item.category)分类开始\")")
puts "Mac plan category context contracts verified."
puts "Plan category badge contracts verified."
raise "Mac static schedule action accessibility override missing" unless File.read("ChronoFocusMac/Views/MacScheduleDetailView.swift").include?("var accessibilityLabelText: String?") && File.read("ChronoFocusMac/Views/MacScheduleDetailView.swift").include?(".accessibilityLabel(accessibilityLabelText ?? title)")
raise "Mac plan panel remaining count helper missing" unless mac_plan_panel_source.include?("private var remainingPlanCount: Int") && mac_plan_panel_source.include?("remainingPlanCount")
raise "Mac plan static generate accessibility label missing count" unless mac_plan_panel_source.include?("accessibilityLabelText: \"按日程生成番茄钟计划，当前\\(remainingPlanCount)轮未完成\"")
raise "Mac plan static clear accessibility label missing count" unless mac_plan_panel_source.include?("accessibilityLabelText: \"清空番茄钟计划，当前\\(remainingPlanCount)轮未完成\"")
raise "Mac plan generate accessibility label missing count" unless mac_plan_panel_source.include?(".accessibilityLabel(\"按日程生成番茄钟计划，当前\\(remainingPlanCount)轮未完成\")")
raise "Mac plan generate Voice Control labels missing" unless mac_plan_panel_source.include?("Text(\"按日程生成\")") && mac_plan_panel_source.include?("Text(\"生成番茄钟计划\")") && mac_plan_panel_source.include?("Text(\"生成\\(remainingPlanCount)轮计划\")")
raise "Mac plan clear accessibility label missing count" unless mac_plan_panel_source.include?(".accessibilityLabel(\"清空番茄钟计划，当前\\(remainingPlanCount)轮未完成\")")
raise "Mac plan clear Voice Control labels missing" unless mac_plan_panel_source.include?("Text(\"清空番茄钟计划\")") && mac_plan_panel_source.include?("Text(\"清空\\(remainingPlanCount)轮计划\")")
puts "Plan panel action accessibility contracts verified."

mac_quick_add_source = source_slice(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "struct MacScheduleDetailView",
  "private struct MacQuickAddCategoryContextView",
  "Mac quick add source missing"
)
raise "Mac quick add category helper missing fallback" unless mac_quick_add_source.include?("private var quickAddCategoryName: String") && mac_quick_add_source.include?("trimmedCategory.isEmpty ? \"未分类\" : trimmedCategory")
raise "Mac quick add accessibility label missing category and rounds" unless mac_quick_add_source.include?("private var quickAddAccessibilityLabel: String") && mac_quick_add_source.include?("\"新增\\(quickAddCategoryName)分类待办，预计 \\(estimatedRounds) 轮\"")
raise "Mac quick add Voice Control labels missing category context" unless mac_quick_add_source.include?("private var quickAddInputLabels: [Text]") && mac_quick_add_source.include?("Text(\"新增待办\")") && mac_quick_add_source.include?("Text(\"新增\\(quickAddCategoryName)分类待办\")") && mac_quick_add_source.include?("Text(\"新增\\(quickAddCategoryName)分类\")")
raise "Mac quick add static button accessibility override missing" unless mac_quick_add_source.include?("MacStaticScheduleActionChipView(title: \"新增待办\", symbolName: \"plus\", tint: .cyan, isProminent: true, accessibilityLabelText: quickAddAccessibilityLabel)")
raise "Mac quick add button accessibility label missing" unless mac_quick_add_source.include?(".accessibilityLabel(quickAddAccessibilityLabel)")
raise "Mac quick add button Voice Control labels missing" unless mac_quick_add_source.include?(".accessibilityInputLabels(quickAddInputLabels)")
puts "Mac quick add action accessibility contracts verified."

task_editor_category_source = source_slice(
  "ChronoFocus/Views/ScheduleView.swift",
  "private struct TaskEditorView",
  "private struct TaskCategoryPresetPicker",
  "Task editor category input source missing"
)
raise "Task editor category display helper missing fallback" unless task_editor_category_source.include?("private var categoryDisplayName: String") && task_editor_category_source.include?("trimmedCategory.isEmpty ? \"未分类\" : trimmedCategory")
raise "Task editor category preset helper missing" unless task_editor_category_source.include?("private var categoryPreset: TaskCategoryPreset?") && task_editor_category_source.include?("TaskCategoryPreset.matching(categoryDisplayName)")
raise "Task editor category tint helper missing" unless task_editor_category_source.include?("private var categoryTint: Color") && task_editor_category_source.include?("categoryPreset?.accentHex ?? accentHex")
raise "Task editor category symbol helper missing" unless task_editor_category_source.include?("private var categorySymbolName: String") && task_editor_category_source.include?("categoryPreset?.symbolName ?? \"tag.fill\"")
raise "Task editor category input accessibility label missing current category" unless task_editor_category_source.include?("private var categoryInputAccessibilityLabel: String") && task_editor_category_source.include?("\"待办分类，当前\\(categoryDisplayName)分类\"")
raise "Task editor category input Voice Control labels missing current category" unless task_editor_category_source.include?("private var categoryInputLabels: [Text]") && task_editor_category_source.include?("Text(\"待办分类\")") && task_editor_category_source.include?("Text(\"\\(categoryDisplayName)分类\")")
raise "Task editor category text field accessibility missing" unless task_editor_category_source.include?(".accessibilityLabel(categoryInputAccessibilityLabel)") && task_editor_category_source.include?(".accessibilityHint(\"可输入自定义分类，或选择常用分类\")") && task_editor_category_source.include?(".accessibilityInputLabels(categoryInputLabels)")
raise "Task editor category context view call missing" unless task_editor_category_source.include?("TaskEditorCategoryContextView(") && task_editor_category_source.include?("category: categoryDisplayName") && task_editor_category_source.include?("tint: categoryTint") && task_editor_category_source.include?("symbolName: categorySymbolName")
raise "Task editor category context view missing visible current category" unless task_editor_category_source.include?("Label(\"当前分类：\\(category)\", systemImage: symbolName)")
raise "Task editor category context accessibility missing" unless task_editor_category_source.include?(".accessibilityLabel(\"当前待办分类\\(category)\")") && task_editor_category_source.include?("Text(\"\\(category)分类\")") && task_editor_category_source.include?("Text(\"当前分类\\(category)\")")

mac_quick_add_category_context_source = source_slice(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "struct MacScheduleDetailView",
  "private struct MacStaticCategoryPresetStrip",
  "Mac quick add category input source missing"
)
raise "Mac quick add category preset helper missing" unless mac_quick_add_category_context_source.include?("private var quickAddCategoryPreset: TaskCategoryPreset?") && mac_quick_add_category_context_source.include?("TaskCategoryPreset.matching(quickAddCategoryName)")
raise "Mac quick add category tint helper missing" unless mac_quick_add_category_context_source.include?("private var quickAddCategoryTint: Color") && mac_quick_add_category_context_source.include?("quickAddCategoryPreset?.accentHex ?? accentHex")
raise "Mac quick add category symbol helper missing" unless mac_quick_add_category_context_source.include?("private var quickAddCategorySymbolName: String") && mac_quick_add_category_context_source.include?("quickAddCategoryPreset?.symbolName ?? \"tag.fill\"")
raise "Mac quick add prefilled helper missing" unless mac_quick_add_category_context_source.include?("private var isQuickAddCategoryPrefilled: Bool") && mac_quick_add_category_context_source.include?("selectedCategory?.trimmingCharacters")
raise "Mac quick add category input accessibility label missing current category" unless mac_quick_add_category_context_source.include?("private var quickAddCategoryInputAccessibilityLabel: String") && mac_quick_add_category_context_source.include?("\"快速新增分类，当前\\(quickAddCategoryName)分类\"")
raise "Mac quick add category input Voice Control labels missing current category" unless mac_quick_add_category_context_source.include?("private var quickAddCategoryInputLabels: [Text]") && mac_quick_add_category_context_source.include?("Text(\"快速新增分类\")") && mac_quick_add_category_context_source.include?("Text(\"\\(quickAddCategoryName)分类\")")
raise "Mac quick add category text field accessibility missing" unless mac_quick_add_category_context_source.include?(".accessibilityLabel(quickAddCategoryInputAccessibilityLabel)") && mac_quick_add_category_context_source.include?(".accessibilityHint(\"可输入自定义分类，或选择常用分类\")") && mac_quick_add_category_context_source.include?(".accessibilityInputLabels(quickAddCategoryInputLabels)")
raise "Mac quick add category context view call missing" unless mac_quick_add_category_context_source.include?("MacQuickAddCategoryContextView(") && mac_quick_add_category_context_source.include?("category: quickAddCategoryName") && mac_quick_add_category_context_source.include?("tint: quickAddCategoryTint") && mac_quick_add_category_context_source.include?("symbolName: quickAddCategorySymbolName") && mac_quick_add_category_context_source.include?("isPrefilled: isQuickAddCategoryPrefilled")
raise "Mac quick add category context visible labels missing" unless mac_quick_add_category_context_source.include?("已预填「\\(category)」分类") && mac_quick_add_category_context_source.include?("当前分类：\\(category)")
raise "Mac quick add category context accessibility missing" unless mac_quick_add_category_context_source.include?("快速新增已预填\\(category)分类") && mac_quick_add_category_context_source.include?("快速新增当前分类\\(category)") && mac_quick_add_category_context_source.include?("Text(\"\\(category)分类\")") && mac_quick_add_category_context_source.include?("Text(\"当前分类\\(category)\")")
puts "Category input context contracts verified."

mac_mini_quick_panel_source = source_slice(
  "ChronoFocusMac/Views/MacMiniTimerView.swift",
  "private struct MacMiniQuickPanelView",
  "private struct MacMiniQuickButton",
  "Mac mini quick panel source missing"
)
mac_mini_quick_button_source = source_slice(
  "ChronoFocusMac/Views/MacMiniTimerView.swift",
  "private struct MacMiniQuickButton",
  "private struct MacMiniPillButtonStyle",
  "Mac mini quick button source missing"
)
raise "Mac mini quick button accessibility parameters missing" unless mac_mini_quick_button_source.include?("var accessibilityLabelText: String?") && mac_mini_quick_button_source.include?("var accessibilityHintText: String?") && mac_mini_quick_button_source.include?("var accessibilityInputLabels: [Text]") && mac_mini_quick_button_source.include?("var accessibilityTraits: AccessibilityTraits")
raise "Mac mini quick button accessibility modifiers missing" unless mac_mini_quick_button_source.include?(".accessibilityLabel(accessibilityLabelText ?? title)") && mac_mini_quick_button_source.include?(".accessibilityHint(accessibilityHintText ?? \"\")") && mac_mini_quick_button_source.include?(".accessibilityInputLabels(accessibilityInputLabels)") && mac_mini_quick_button_source.include?(".accessibilityAddTraits(accessibilityTraits)")
raise "Mac mini mode quick button accessibility missing" unless mac_mini_quick_panel_source.include?("accessibilityLabelText: modeAccessibilityLabel(for: mode)") && mac_mini_quick_panel_source.include?("accessibilityHintText: modeAccessibilityHint(for: mode)") && mac_mini_quick_panel_source.include?("accessibilityInputLabels: modeAccessibilityInputLabels(for: mode)") && mac_mini_quick_panel_source.include?("accessibilityTraits: modeAccessibilityTraits(for: mode)")
raise "Mac mini mode accessibility helpers missing" unless mac_mini_quick_panel_source.include?("private func modeAccessibilityLabel(for mode: TimerMode) -> String") && mac_mini_quick_panel_source.include?("\"\\(mode.title)模式，当前模式\"") && mac_mini_quick_panel_source.include?("\"切换到\\(mode.title)模式\"") && mac_mini_quick_panel_source.include?("计时运行中不可切换模式") && mac_mini_quick_panel_source.include?("mode == engine.mode ? [.isSelected] : []")
raise "Mac mini focus duration accessibility missing" unless mac_mini_quick_panel_source.include?(".accessibilityLabel(focusDurationAccessibilityLabel(for: minute))") && mac_mini_quick_panel_source.include?(".accessibilityHint(focusDurationAccessibilityHint(for: minute))") && mac_mini_quick_panel_source.include?(".accessibilityInputLabels(focusDurationAccessibilityInputLabels(for: minute))") && mac_mini_quick_panel_source.include?(".accessibilityAddTraits(focusDurationAccessibilityTraits(for: minute))")
raise "Mac mini focus duration helpers missing" unless mac_mini_quick_panel_source.include?("private func focusDurationAccessibilityLabel(for minute: Int) -> String") && mac_mini_quick_panel_source.include?("\"设置专注时长为 \\(minute) 分钟\"") && mac_mini_quick_panel_source.include?("当前已选") && mac_mini_quick_panel_source.include?("计时运行中不可调整专注时长") && mac_mini_quick_panel_source.include?("store.settings.focusMinutes == minute ? [.isSelected] : []")
raise "Mac mini sound quick button accessibility missing" unless mac_mini_quick_panel_source.include?("accessibilityLabelText: \"切换到点铃声，当前\\(store.settings.completionSound.title)\"") && mac_mini_quick_panel_source.include?("Text(\"切换铃声\")") && mac_mini_quick_panel_source.include?("Text(\"到点铃声\")")
raise "Mac mini preview quick button accessibility missing" unless mac_mini_quick_panel_source.include?("accessibilityLabelText: \"试听\\(store.settings.completionSound.title)到点铃声\"") && mac_mini_quick_panel_source.include?("当前 Pro 音色未解锁，暂不可试听") && mac_mini_quick_panel_source.include?("Text(\"试听铃声\")")
raise "Mac mini detail quick button accessibility missing" unless mac_mini_quick_panel_source.include?("accessibilityLabelText: \"打开日程详情\"") && mac_mini_quick_panel_source.include?("accessibilityLabelText: \"打开统计详情\"") && mac_mini_quick_panel_source.include?("accessibilityLabelText: \"打开设置详情\"") && mac_mini_quick_panel_source.include?("Text(\"打开日程详情\")") && mac_mini_quick_panel_source.include?("Text(\"打开统计详情\")") && mac_mini_quick_panel_source.include?("Text(\"打开设置详情\")")
puts "Mac mini quick panel accessibility contracts verified."

[
  File.read("ChronoFocus/Views/AnalyticsView.swift"),
  File.read("ChronoFocusMac/Views/MacAnalyticsDetailView.swift")
].each do |source|
  raise "analytics category share total missing" unless source.include?("private var categoryShareTotalSeconds: Int") && source.include?("store.categoryBreakdown().reduce(0) { $0 + $1.seconds }")
  raise "analytics category share percent helper missing" unless source.include?("private func categorySharePercent(for seconds: Int) -> Int") && source.include?("Double(categoryShareTotalSeconds)") && source.include?(".rounded()")
  raise "analytics category share visible percent missing" unless source.include?("Text(\"\\(categorySharePercent(for: item.seconds))%\")") && source.include?(".monospacedDigit()")
  raise "analytics category share progress total missing" unless source.include?("total: Double(categoryShareTotalSeconds)")
  raise "analytics category share accessibility label missing" unless source.include?("private func categoryShareAccessibilityLabel(for item: CategoryFocus) -> String") && source.include?("占分类投入 \\(categorySharePercent(for: item.seconds))%") && source.include?(".accessibilityLabel(categoryShareAccessibilityLabel(for: item))")
  raise "analytics category share Voice Control labels missing" unless source.include?(".accessibilityElement(children: .ignore)") && source.include?("Text(\"\\(item.category)分类投入\")") && source.include?(".accessibilityInputLabels([")
end
puts "Analytics category share accessibility contracts verified."

assert_slice_contains(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "MacTaskListPanelView(",
  ".onChange(of: selectedCategory)",
  /MacTaskListPanelView\([\s\S]*?selectedCategory:\s*\$selectedCategory,[\s\S]*?onAddTaskInCategory:\s*prepareQuickAdd/,
  "Mac task list panel must pass quick add category action"
)

assert_slice_contains(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "private func addTask()",
  "private func prepareQuickAdd(_ category: String)",
  /let submittedCategory = category[\s\S]*?let submittedAccentHex = accentHex[\s\S]*?category = selectedCategory \?\? task\.category[\s\S]*?accentHex = TaskCategoryPreset\.matching\(category\)\?\.accentHex \?\? task\.accentHex[\s\S]*?category = selectedCategory \?\? submittedCategory[\s\S]*?accentHex = TaskCategoryPreset\.matching\(category\)\?\.accentHex \?\? submittedAccentHex/,
  "Mac quick add must retain submitted category after add"
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
assert_calendar_day_accessibility("ChronoFocus/Views/ScheduleView.swift", "CalendarDayButton", "private struct TaskCategoryFilterBar")
assert_calendar_day_accessibility("ChronoFocusMac/Views/MacScheduleDetailView.swift", "MacCalendarDayCell", "private struct MacCalendarSyncPanelView")
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
ruby -e 'source = File.read("ChronoFocusMac/Views/MacTimerDetailView.swift"); row = source[/struct MacTaskRowView: View[\s\S]*?struct MacPageHeaderView: View/]; raise "MacTaskRowView missing" unless row; raise "Mac task row category preset missing" unless row.include?("private var categoryPreset") && row.include?("TaskCategoryPreset.matching(task.category)"); raise "Mac task row category preset color fallback missing" unless row.include?("Color(hex: categoryPreset?.accentHex ?? task.accentHex)"); raise "Mac task row category symbol missing" unless row.include?("private var categorySymbolName") && row.include?("categoryPreset?.symbolName ?? \"tag.fill\""); raise "Mac task row category badge missing" unless row.include?("Label(task.category, systemImage: categorySymbolName)"); raise "Mac task row category accessibility label missing" unless row.include?(".accessibilityLabel(\"\\(task.category)分类\")"); raise "Mac task row category Voice Control input labels missing" unless row.include?(".accessibilityInputLabels([Text(task.category), Text(\"\\(task.category)分类\")])"); raise "Mac task row must not replace category with due date" if row.include?("task.dueDate?.scheduleTimeText ?? task.category"); raise "Mac task row must keep due date as secondary metadata" unless row.include?("if let dueDate = task.dueDate") && row.include?("dueDate.scheduleTimeText")'
ruby -e 'source = File.read("ChronoFocusMac/Views/MacMiniTimerView.swift"); badge = source[/private struct MacMiniTaskCategoryBadgeView: View[\s\S]*?private struct MacMiniQuickPanelView: View/]; raise "MacMiniTaskCategoryBadgeView missing" unless badge; raise "Mac mini task badge category preset missing" unless badge.include?("private var categoryPreset") && badge.include?("TaskCategoryPreset.matching(task.category)"); raise "Mac mini task badge preset color fallback missing" unless badge.include?("Color(hex: categoryPreset?.accentHex ?? task.accentHex)"); raise "Mac mini task badge symbol fallback missing" unless badge.include?("categoryPreset?.symbolName ?? \"tag.fill\""); raise "Mac mini task badge accessibility label missing" unless badge.include?(".accessibilityLabel(\"\\(task.category)分类\")"); raise "Mac mini task badge Voice Control input labels missing" unless badge.include?(".accessibilityInputLabels([Text(task.category), Text(\"\\(task.category)分类\")])")'
ruby -e 'source = File.read("ChronoFocus/Views/TimerView.swift"); row = source[/private struct TaskRow: View[\s\S]*?private struct TimerTaskCategoryFilterBar: View/]; raise "Timer TaskRow missing" unless row; raise "Timer TaskRow selected state text missing" unless row.include?("已选中当前待办") && row.include?("未选中"); raise "Timer TaskRow selection hint missing" unless row.include?("这是当前番茄钟待办") && row.include?("选择此待办作为当前番茄钟任务"); raise "Timer TaskRow selected trait missing" unless row.include?("selectionAccessibilityTraits") && row.include?(".accessibilityAddTraits(selectionAccessibilityTraits)"); raise "Timer TaskRow accessibility label missing" unless row.include?(".accessibilityLabel(\"\\(task.title)，\\(task.category)分类，\\(selectionStateText)\")")'
ruby -e 'source = File.read("ChronoFocusMac/Views/MacTimerDetailView.swift"); row = source[/struct MacTaskRowView: View[\s\S]*?struct MacPageHeaderView: View/]; raise "MacTaskRowView missing" unless row; raise "Mac task row selected state text missing" unless row.include?("已选中当前待办") && row.include?("未选中"); raise "Mac task row selection hint missing" unless row.include?("这是当前番茄钟待办") && row.include?("选择此待办作为当前番茄钟任务"); raise "Mac task row selected trait missing" unless row.include?("selectionAccessibilityTraits") && row.include?(".accessibilityAddTraits(selectionAccessibilityTraits)"); raise "Mac task row selection accessibility label missing" unless row.include?(".accessibilityLabel(\"\\(task.title)，\\(task.category)分类，\\(selectionStateText)\")")'
ruby -e 'source = File.read("ChronoFocusMac/Views/MacMiniTimerView.swift"); picker = source[/private struct MacMiniTaskPickerView: View[\s\S]*?private struct MacMiniTaskCategoryBadgeView: View/]; raise "MacMiniTaskPickerView missing" unless picker; raise "Mac mini task selected state text missing" unless picker.include?("private func selectionStateText") && picker.include?("selectionStateText(isSelected: isSelected)") && picker.include?("已选中当前待办") && picker.include?("未选中"); raise "Mac mini task selection hint missing" unless picker.include?("private func selectionHintText") && picker.include?("selectionHintText(isSelected: isSelected)") && picker.include?("这是当前番茄钟待办") && picker.include?("选择此待办作为当前番茄钟任务"); raise "Mac mini task selected trait missing" unless picker.include?("private func selectionAccessibilityTraits") && picker.include?(".accessibilityAddTraits(selectionAccessibilityTraits(isSelected: isSelected))"); raise "Mac mini task selection accessibility label missing" unless picker.include?(".accessibilityLabel(\"\\(task.title)，\\(task.category)分类，\\(selectionStateText(isSelected: isSelected))\")")'
ruby -e 'source = File.read("ChronoFocus/Views/TimerView.swift"); row = source[/private struct TaskRow: View[\s\S]*?private struct TimerTaskCategoryFilterBar: View/]; raise "Timer TaskRow missing" unless row; raise "Timer TaskRow running state missing" unless row.include?("let isTimerRunning: Bool") && source.include?("isTimerRunning: engine.isRunning"); raise "Timer TaskRow running disabled hint missing" unless row.include?("计时运行中不可切换当前待办"); raise "Timer TaskRow Voice Control input labels missing" unless row.include?("private var selectionInputLabels: [Text]") && row.include?("Text(task.title)") && row.include?("Text(\"\\(task.title)待办\")") && row.include?("Text(\"\\(task.category)分类待办\")") && row.include?(".accessibilityInputLabels(selectionInputLabels)")'
ruby -e 'source = File.read("ChronoFocusMac/Views/MacTimerDetailView.swift"); row = source[/struct MacTaskRowView: View[\s\S]*?struct MacPageHeaderView: View/]; raise "MacTaskRowView missing" unless row; raise "Mac task row running state missing" unless row.include?("var isTimerRunning = false") && source.include?("isTimerRunning: engine.isRunning"); raise "Mac task row running disabled hint missing" unless row.include?("计时运行中不可切换当前待办"); raise "Mac task row Voice Control input labels missing" unless row.include?("private var selectionInputLabels: [Text]") && row.include?("Text(task.title)") && row.include?("Text(\"\\(task.title)待办\")") && row.include?("Text(\"\\(task.category)分类待办\")") && row.include?(".accessibilityInputLabels(selectionInputLabels)")'
ruby -e 'source = File.read("ChronoFocusMac/Views/MacMiniTimerView.swift"); picker = source[/private struct MacMiniTaskPickerView: View[\s\S]*?private struct MacMiniTaskCategoryBadgeView: View/]; raise "MacMiniTaskPickerView missing" unless picker; raise "Mac mini task running disabled hint missing" unless picker.include?("engine.isRunning && !isSelected") && picker.include?("计时运行中不可切换当前待办"); raise "Mac mini task Voice Control input labels missing" unless picker.include?("private func selectionInputLabels(for task: FocusTask) -> [Text]") && picker.include?("Text(task.title)") && picker.include?("Text(\"\\(task.title)待办\")") && picker.include?("Text(\"\\(task.category)分类待办\")") && picker.include?(".accessibilityInputLabels(selectionInputLabels(for: task))")'
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
grep -q "EXPECTED_CI_PROCESS_VERSION = \"v0.10\"" scripts/validate_ci_artifact.rb
grep -q "ci process version" scripts/validate_ci_artifact.rb
grep -q "missingRequiredCount" scripts/validate_ci_artifact.rb
grep -q "require \"find\"" scripts/validate_ci_artifact.rb
grep -q "Mac core tests passed." scripts/validate_ci_artifact.rb
grep -q "Project structure verified." scripts/validate_ci_artifact.rb
grep -q "Category chip accessibility contracts verified." scripts/validate_ci_artifact.rb
grep -q "Category summary action contracts verified." scripts/validate_ci_artifact.rb
grep -q "Schedule task action accessibility contracts verified." scripts/validate_ci_artifact.rb
grep -q "Plan start action accessibility contracts verified." scripts/validate_ci_artifact.rb
grep -q "Plan category badge contracts verified." scripts/validate_ci_artifact.rb
grep -q "Mac plan category context contracts verified." scripts/validate_ci_artifact.rb
grep -q "Plan panel action accessibility contracts verified." scripts/validate_ci_artifact.rb
grep -q "Schedule toolbar add category context contracts verified." scripts/validate_ci_artifact.rb
grep -q "Mac quick add action accessibility contracts verified." scripts/validate_ci_artifact.rb
grep -q "Category input context contracts verified." scripts/validate_ci_artifact.rb
grep -q "Mac mini quick panel accessibility contracts verified." scripts/validate_ci_artifact.rb
grep -q "Analytics category share accessibility contracts verified." scripts/validate_ci_artifact.rb
grep -q "BUILD SUCCEEDED" scripts/validate_ci_artifact.rb
grep -q "EXPECTED_SNAPSHOTS" scripts/validate_ci_artifact.rb
grep -q "EXPECTED_INDEX_ENTRIES" scripts/validate_ci_artifact.rb
grep -q "EXPECTED_SUMMARY_ENTRIES" scripts/validate_ci_artifact.rb
grep -q "EXPECTED_STATIC_CHECK_MARKERS" scripts/validate_ci_artifact.rb
grep -q "EXPECTED_ARTIFACT_ROOT_ENTRIES" scripts/validate_ci_artifact.rb
grep -q "EXPECTED_JUNIT_TESTCASES" scripts/validate_ci_artifact.rb
grep -q "EXPECTED_JUNIT_OUTCOMES" scripts/validate_ci_artifact.rb
grep -q "EXPECTED_RUN_CONTEXT_KEYS" scripts/validate_ci_artifact.rb
grep -q "ci-run-context.txt" scripts/validate_ci_artifact.rb
grep -q "xcode version log" scripts/validate_ci_artifact.rb
grep -q "run context exact keys" scripts/validate_ci_artifact.rb
grep -q "run context identity" scripts/validate_ci_artifact.rb
grep -q "run context artifact name" scripts/validate_ci_artifact.rb
grep -q "manifest artifact name" scripts/validate_ci_artifact.rb
grep -q "index artifact name" scripts/validate_ci_artifact.rb
grep -q "negative_junit_fixture" scripts/verify_project.sh
grep -q "negative_junit_errors_fixture" scripts/verify_project.sh
grep -q "stale_process_version_fixture" scripts/verify_project.sh
grep -q "negative_junit_metadata_fixture" scripts/verify_project.sh
grep -q "negative_junit_failure_element_fixture" scripts/verify_project.sh
grep -q "negative_summary_marker_fixture" scripts/verify_project.sh
grep -q "negative_task_action_marker_fixture" scripts/verify_project.sh
grep -q "negative_plan_start_marker_fixture" scripts/verify_project.sh
grep -q "negative_plan_category_badge_marker_fixture" scripts/verify_project.sh
grep -q "negative_mac_plan_category_marker_fixture" scripts/verify_project.sh
grep -q "negative_plan_panel_action_marker_fixture" scripts/verify_project.sh
grep -q "negative_schedule_toolbar_add_marker_fixture" scripts/verify_project.sh
grep -q "negative_mac_quick_add_action_marker_fixture" scripts/verify_project.sh
grep -q "negative_category_input_context_marker_fixture" scripts/verify_project.sh
grep -q "negative_mac_mini_quick_panel_marker_fixture" scripts/verify_project.sh
grep -q "negative_analytics_category_share_marker_fixture" scripts/verify_project.sh
grep -q "negative_artifact_fixture" scripts/verify_project.sh
grep -q "negative_run_context_extra_key_fixture" scripts/verify_project.sh
grep -q "negative_manifest_artifact_name_fixture" scripts/verify_project.sh
grep -q "negative_index_artifact_name_fixture" scripts/verify_project.sh
grep -q "negative_manifest_metadata_fixture" scripts/verify_project.sh
grep -q "negative_index_fixture" scripts/verify_project.sh
grep -q "corrupt_index_totals_fixture" scripts/verify_project.sh
grep -q "unexpected_index_entry_fixture" scripts/verify_project.sh
grep -q "unexpected_local_artifact_fixture" scripts/verify_project.sh
grep -q "missing_local_artifact_fixture" scripts/verify_project.sh
grep -q "mismatched_local_artifact_fixture" scripts/verify_project.sh
grep -q "FAIL junit errors" scripts/verify_project.sh
grep -q "FAIL junit testcase outcomes" scripts/verify_project.sh
grep -q "FAIL junit failure elements" scripts/verify_project.sh
grep -q "FAIL ci process version" scripts/verify_project.sh
grep -q "FAIL junit metadata" scripts/verify_project.sh
grep -q "FAIL verify_project category summary action contracts" scripts/verify_project.sh
grep -q "FAIL verify_project schedule task action accessibility contracts" scripts/verify_project.sh
grep -q "FAIL verify_project plan start action accessibility contracts" scripts/verify_project.sh
grep -q "FAIL verify_project plan category badge contracts" scripts/verify_project.sh
grep -q "FAIL verify_project mac plan category context contracts" scripts/verify_project.sh
grep -q "FAIL verify_project plan panel action accessibility contracts" scripts/verify_project.sh
grep -q "FAIL verify_project schedule toolbar add category context contracts" scripts/verify_project.sh
grep -q "FAIL verify_project mac quick add action accessibility contracts" scripts/verify_project.sh
grep -q "FAIL verify_project category input context contracts" scripts/verify_project.sh
grep -q "FAIL verify_project mac mini quick panel accessibility contracts" scripts/verify_project.sh
grep -q "FAIL verify_project analytics category share accessibility contracts" scripts/verify_project.sh
grep -q "FAIL run context exact keys" scripts/verify_project.sh
grep -q "FAIL run context artifact name" scripts/verify_project.sh
grep -q "FAIL manifest artifact name" scripts/verify_project.sh
grep -q "FAIL index artifact name" scripts/verify_project.sh
grep -q "FAIL manifest metadata" scripts/verify_project.sh
grep -q "FAIL index commit" scripts/verify_project.sh
grep -q "FAIL index totals consistency" scripts/verify_project.sh
grep -q "FAIL index unexpected entries" scripts/verify_project.sh
grep -q "FAIL unexpected local artifacts" scripts/verify_project.sh
grep -q "FAIL index required local artifacts" scripts/verify_project.sh
grep -q "FAIL snapshot manifest generated at" scripts/verify_project.sh
grep -q "FAIL snapshot byte counts" scripts/verify_project.sh
grep -q "manifest paths" scripts/validate_ci_artifact.rb
grep -q "manifest short sha" scripts/validate_ci_artifact.rb
grep -q "manifest metadata" scripts/validate_ci_artifact.rb
grep -q "manifest created at" scripts/validate_ci_artifact.rb
grep -q "manifest project reports" scripts/validate_ci_artifact.rb
grep -q "index version" scripts/validate_ci_artifact.rb
grep -q "index created at" scripts/validate_ci_artifact.rb
grep -q "index required paths" scripts/validate_ci_artifact.rb
grep -q "index required local artifacts" scripts/validate_ci_artifact.rb
grep -q "index required local metadata" scripts/validate_ci_artifact.rb
grep -q "index totals consistency" scripts/validate_ci_artifact.rb
grep -q "index unexpected entries" scripts/validate_ci_artifact.rb
grep -q "unexpected local artifacts" scripts/validate_ci_artifact.rb
grep -q "failure summary log entries" scripts/validate_ci_artifact.rb
grep -q "failure summary identity" scripts/validate_ci_artifact.rb
grep -q "failure summary outcomes" scripts/validate_ci_artifact.rb
grep -q "junit metadata" scripts/validate_ci_artifact.rb
grep -q "junit testcase names" scripts/validate_ci_artifact.rb
grep -q "junit errors" scripts/validate_ci_artifact.rb
grep -q "junit testcase outcomes" scripts/validate_ci_artifact.rb
grep -q "junit failure elements" scripts/validate_ci_artifact.rb
grep -q "snapshot manifest generated at" scripts/validate_ci_artifact.rb
grep -q "snapshot byte counts" scripts/validate_ci_artifact.rb
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
    "verify_project.log": "Mac core tests passed.\nCategory summary action contracts verified.\nCategory chip accessibility contracts verified.\nSchedule task action accessibility contracts verified.\nPlan start action accessibility contracts verified.\nPlan category badge contracts verified.\nMac plan category context contracts verified.\nPlan panel action accessibility contracts verified.\nSchedule toolbar add category context contracts verified.\nMac quick add action accessibility contracts verified.\nCategory input context contracts verified.\nMac mini quick panel accessibility contracts verified.\nAnalytics category share accessibility contracts verified.\nProject structure verified.\n",
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
suite = ET.Element("testsuite", name="ChronoFocus CI Results", tests="4", failures="0", errors="0")
for name, log_path in tests:
    case = ET.SubElement(suite, "testcase", name=name, classname="ChronoFocusCI")
    ET.SubElement(case, "system-out").text = f"outcome=success; log={log_path}"
ET.ElementTree(suite).write(root / "junit.xml", encoding="utf-8", xml_declaration=True)

manifest = {
    "version": "v0.10",
    "artifactName": f"chronofocus-ci-v0.10-main-fixture-run{run_id}-attempt{attempt}",
    "branch": "main",
    "commitSha": commit,
    "shortSha": commit[:7],
    "runId": run_id,
    "runAttempt": attempt,
    "workflowName": "ChronoFocus CI Results",
    "createdAt": "2026-07-04T00:00:00Z",
    "projectName": "ChronoFocus",
    "scheme": "ChronoFocusMac",
    "destination": "generic/platform=macOS",
    "macScheme": "ChronoFocusMac",
    "macDestination": "generic/platform=macOS",
    "iosScheme": "ChronoFocus",
    "iosDestination": "generic/platform=iOS",
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
    "projectSpecificReports": [
        {
            "name": "artifact_index",
            "path": "ci-results/ci-artifact-index.json",
            "description": "Structured index of required CI artifact files and directories with existence and size metadata.",
        },
        {
            "name": "verify_project_log",
            "path": "ci-results/verify_project.log",
            "description": "Project structure, Mac core tests, and Mac UI snapshot verification log.",
        },
        {
            "name": "mac_snapshots",
            "path": "ci-results/project-reports/mac-snapshots",
            "description": "Mac mini timer and detail view snapshots generated by scripts/render_mac_snapshots.swift.",
        },
        {
            "name": "mac_snapshot_manifest",
            "path": "ci-results/project-reports/mac-snapshots/manifest.json",
            "description": "Structured manifest for Mac snapshot file names, dimensions, byte counts, and generation time.",
        },
        {
            "name": "ios_xcodebuild_log",
            "path": "ci-results/ios-xcodebuild.log",
            "description": "iOS ChronoFocus scheme generic build log.",
        },
        {
            "name": "ios_xcode_result",
            "path": "ci-results/ChronoFocus-iOS.xcresult",
            "description": "Native result bundle from the iOS ChronoFocus scheme generic build.",
        },
        {
            "name": "xcode_version",
            "path": "ci-results/xcode-version.log",
            "description": "Xcode version selected by the runner.",
        },
    ],
}
(root / "ci-artifact-manifest.json").write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
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

index_path = root / "ci-artifact-index.json"
index_path.write_text("{}\n", encoding="utf-8")
last_size = None
for _ in range(5):
    index = {
        "version": "v0.10",
        "artifactName": f"chronofocus-ci-v0.10-main-fixture-run{run_id}-attempt{attempt}",
        "branch": "main",
        "commitSha": commit,
        "runId": run_id,
        "runAttempt": attempt,
        "createdAt": "2026-07-04T00:00:00Z",
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
    index_path.write_text(
        json.dumps(index, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    new_size = index_path.stat().st_size
    if new_size == last_size:
        break
    last_size = new_size
PY
ruby scripts/validate_ci_artifact.rb "$artifact_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >/dev/null
stale_process_version_fixture="$(mktemp -d)"
stale_process_version_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$stale_process_version_fixture"/
python3 - "$stale_process_version_fixture" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])

manifest_path = root / "ci-artifact-manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
manifest["version"] = "v0.09"
manifest_path.write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

index_path = root / "ci-artifact-index.json"
index = json.loads(index_path.read_text(encoding="utf-8"))
index["version"] = "v0.09"
index_path.write_text(
    json.dumps(index, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

summary_path = root / "ci-failure-summary.md"
summary_path.write_text(
    summary_path.read_text(encoding="utf-8").replace(
        "Version: `v0.10`",
        "Version: `v0.09`",
    ),
    encoding="utf-8",
)

context_path = root / "ci-run-context.txt"
context_path.write_text(
    context_path.read_text(encoding="utf-8").replace(
        "chronofocus-ci-v0.10-main-fixture-run12345-attempt1",
        "chronofocus-ci-v0.09-main-fixture-run12345-attempt1",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$stale_process_version_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$stale_process_version_output" 2>&1; then
  echo "Expected stale process version fixture to fail validation" >&2
  cat "$stale_process_version_output" >&2
  exit 1
fi
grep -q "FAIL ci process version" "$stale_process_version_output"
rm -rf "$stale_process_version_fixture"
rm -f "$stale_process_version_output"
negative_summary_marker_fixture="$(mktemp -d)"
negative_summary_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_summary_marker_fixture"/
python3 - "$negative_summary_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Category summary action contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_summary_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_summary_marker_output" 2>&1; then
  echo "Expected negative summary marker fixture to fail validation" >&2
  cat "$negative_summary_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project category summary action contracts" "$negative_summary_marker_output"
rm -rf "$negative_summary_marker_fixture"
rm -f "$negative_summary_marker_output"
negative_task_action_marker_fixture="$(mktemp -d)"
negative_task_action_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_task_action_marker_fixture"/
python3 - "$negative_task_action_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Schedule task action accessibility contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_task_action_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_task_action_marker_output" 2>&1; then
  echo "Expected negative task action marker fixture to fail validation" >&2
  cat "$negative_task_action_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project schedule task action accessibility contracts" "$negative_task_action_marker_output"
rm -rf "$negative_task_action_marker_fixture"
rm -f "$negative_task_action_marker_output"
negative_plan_start_marker_fixture="$(mktemp -d)"
negative_plan_start_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_plan_start_marker_fixture"/
python3 - "$negative_plan_start_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Plan start action accessibility contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_plan_start_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_plan_start_marker_output" 2>&1; then
  echo "Expected negative plan start marker fixture to fail validation" >&2
  cat "$negative_plan_start_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project plan start action accessibility contracts" "$negative_plan_start_marker_output"
rm -rf "$negative_plan_start_marker_fixture"
rm -f "$negative_plan_start_marker_output"
negative_plan_category_badge_marker_fixture="$(mktemp -d)"
negative_plan_category_badge_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_plan_category_badge_marker_fixture"/
python3 - "$negative_plan_category_badge_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Plan category badge contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_plan_category_badge_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_plan_category_badge_marker_output" 2>&1; then
  echo "Expected negative plan category badge marker fixture to fail validation" >&2
  cat "$negative_plan_category_badge_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project plan category badge contracts" "$negative_plan_category_badge_marker_output"
rm -rf "$negative_plan_category_badge_marker_fixture"
rm -f "$negative_plan_category_badge_marker_output"
negative_mac_plan_category_marker_fixture="$(mktemp -d)"
negative_mac_plan_category_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_mac_plan_category_marker_fixture"/
python3 - "$negative_mac_plan_category_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Mac plan category context contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_mac_plan_category_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_mac_plan_category_marker_output" 2>&1; then
  echo "Expected negative Mac plan category marker fixture to fail validation" >&2
  cat "$negative_mac_plan_category_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project mac plan category context contracts" "$negative_mac_plan_category_marker_output"
rm -rf "$negative_mac_plan_category_marker_fixture"
rm -f "$negative_mac_plan_category_marker_output"
negative_plan_panel_action_marker_fixture="$(mktemp -d)"
negative_plan_panel_action_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_plan_panel_action_marker_fixture"/
python3 - "$negative_plan_panel_action_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Plan panel action accessibility contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_plan_panel_action_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_plan_panel_action_marker_output" 2>&1; then
  echo "Expected negative plan panel action marker fixture to fail validation" >&2
  cat "$negative_plan_panel_action_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project plan panel action accessibility contracts" "$negative_plan_panel_action_marker_output"
rm -rf "$negative_plan_panel_action_marker_fixture"
rm -f "$negative_plan_panel_action_marker_output"
negative_schedule_toolbar_add_marker_fixture="$(mktemp -d)"
negative_schedule_toolbar_add_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_schedule_toolbar_add_marker_fixture"/
python3 - "$negative_schedule_toolbar_add_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Schedule toolbar add category context contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_schedule_toolbar_add_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_schedule_toolbar_add_marker_output" 2>&1; then
  echo "Expected negative schedule toolbar add marker fixture to fail validation" >&2
  cat "$negative_schedule_toolbar_add_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project schedule toolbar add category context contracts" "$negative_schedule_toolbar_add_marker_output"
rm -rf "$negative_schedule_toolbar_add_marker_fixture"
rm -f "$negative_schedule_toolbar_add_marker_output"
negative_mac_quick_add_action_marker_fixture="$(mktemp -d)"
negative_mac_quick_add_action_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_mac_quick_add_action_marker_fixture"/
python3 - "$negative_mac_quick_add_action_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Mac quick add action accessibility contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_mac_quick_add_action_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_mac_quick_add_action_marker_output" 2>&1; then
  echo "Expected negative Mac quick add action marker fixture to fail validation" >&2
  cat "$negative_mac_quick_add_action_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project mac quick add action accessibility contracts" "$negative_mac_quick_add_action_marker_output"
rm -rf "$negative_mac_quick_add_action_marker_fixture"
rm -f "$negative_mac_quick_add_action_marker_output"
negative_category_input_context_marker_fixture="$(mktemp -d)"
negative_category_input_context_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_category_input_context_marker_fixture"/
python3 - "$negative_category_input_context_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Category input context contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_category_input_context_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_category_input_context_marker_output" 2>&1; then
  echo "Expected negative category input context marker fixture to fail validation" >&2
  cat "$negative_category_input_context_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project category input context contracts" "$negative_category_input_context_marker_output"
rm -rf "$negative_category_input_context_marker_fixture"
rm -f "$negative_category_input_context_marker_output"
negative_mac_mini_quick_panel_marker_fixture="$(mktemp -d)"
negative_mac_mini_quick_panel_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_mac_mini_quick_panel_marker_fixture"/
python3 - "$negative_mac_mini_quick_panel_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Mac mini quick panel accessibility contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_mac_mini_quick_panel_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_mac_mini_quick_panel_marker_output" 2>&1; then
  echo "Expected negative Mac mini quick panel marker fixture to fail validation" >&2
  cat "$negative_mac_mini_quick_panel_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project mac mini quick panel accessibility contracts" "$negative_mac_mini_quick_panel_marker_output"
rm -rf "$negative_mac_mini_quick_panel_marker_fixture"
rm -f "$negative_mac_mini_quick_panel_marker_output"
negative_analytics_category_share_marker_fixture="$(mktemp -d)"
negative_analytics_category_share_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_analytics_category_share_marker_fixture"/
python3 - "$negative_analytics_category_share_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Analytics category share accessibility contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_analytics_category_share_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_analytics_category_share_marker_output" 2>&1; then
  echo "Expected negative analytics category share marker fixture to fail validation" >&2
  cat "$negative_analytics_category_share_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project analytics category share accessibility contracts" "$negative_analytics_category_share_marker_output"
rm -rf "$negative_analytics_category_share_marker_fixture"
rm -f "$negative_analytics_category_share_marker_output"
negative_junit_metadata_fixture="$(mktemp -d)"
negative_junit_metadata_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_junit_metadata_fixture"/
python3 - "$negative_junit_metadata_fixture" <<'PY'
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path(sys.argv[1])
junit_path = root / "junit.xml"
tree = ET.parse(junit_path)
root_element = tree.getroot()
root_element.set("name", "Wrong CI Results")
for testcase in root_element.findall("testcase"):
    if testcase.get("name") == "projectVerification":
        testcase.set("classname", "WrongCI")
        break
tree.write(junit_path, encoding="utf-8", xml_declaration=True)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_junit_metadata_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_junit_metadata_output" 2>&1; then
  echo "Expected negative JUnit metadata fixture to fail validation" >&2
  cat "$negative_junit_metadata_output" >&2
  exit 1
fi
grep -q "FAIL junit metadata" "$negative_junit_metadata_output"
rm -rf "$negative_junit_metadata_fixture"
rm -f "$negative_junit_metadata_output"
negative_junit_errors_fixture="$(mktemp -d)"
negative_junit_errors_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_junit_errors_fixture"/
python3 - "$negative_junit_errors_fixture" <<'PY'
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path(sys.argv[1])
junit_path = root / "junit.xml"
tree = ET.parse(junit_path)
tree.getroot().set("errors", "1")
tree.write(junit_path, encoding="utf-8", xml_declaration=True)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_junit_errors_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_junit_errors_output" 2>&1; then
  echo "Expected negative JUnit errors fixture to fail validation" >&2
  cat "$negative_junit_errors_output" >&2
  exit 1
fi
grep -q "FAIL junit errors" "$negative_junit_errors_output"
rm -rf "$negative_junit_errors_fixture"
rm -f "$negative_junit_errors_output"
negative_junit_fixture="$(mktemp -d)"
negative_junit_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_junit_fixture"/
python3 - "$negative_junit_fixture" <<'PY'
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path(sys.argv[1])
junit_path = root / "junit.xml"
tree = ET.parse(junit_path)
for testcase in tree.getroot().findall("testcase"):
    if testcase.get("name") == "staticChecks":
        testcase.find("system-out").text = "outcome=failure; log=ci-results/static-checks.log"
        break
tree.write(junit_path, encoding="utf-8", xml_declaration=True)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_junit_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_junit_output" 2>&1; then
  echo "Expected negative JUnit fixture to fail validation" >&2
  cat "$negative_junit_output" >&2
  exit 1
fi
grep -q "FAIL junit testcase outcomes" "$negative_junit_output"
rm -rf "$negative_junit_fixture"
rm -f "$negative_junit_output"
negative_junit_failure_element_fixture="$(mktemp -d)"
negative_junit_failure_element_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_junit_failure_element_fixture"/
python3 - "$negative_junit_failure_element_fixture" <<'PY'
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path(sys.argv[1])
junit_path = root / "junit.xml"
tree = ET.parse(junit_path)
for testcase in tree.getroot().findall("testcase"):
    if testcase.get("name") == "projectVerification":
        ET.SubElement(testcase, "failure", message="projectVerification failure").text = "unexpected failure element"
        break
tree.write(junit_path, encoding="utf-8", xml_declaration=True)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_junit_failure_element_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_junit_failure_element_output" 2>&1; then
  echo "Expected negative JUnit failure element fixture to fail validation" >&2
  cat "$negative_junit_failure_element_output" >&2
  exit 1
fi
grep -q "FAIL junit failure elements" "$negative_junit_failure_element_output"
rm -rf "$negative_junit_failure_element_fixture"
rm -f "$negative_junit_failure_element_output"
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
negative_run_context_extra_key_fixture="$(mktemp -d)"
negative_run_context_extra_key_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_run_context_extra_key_fixture"/
python3 - "$negative_run_context_extra_key_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
context_path = root / "ci-run-context.txt"
context_path.write_text(
    context_path.read_text(encoding="utf-8") + "source=stale\n",
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_run_context_extra_key_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_run_context_extra_key_output" 2>&1; then
  echo "Expected negative run context extra key fixture to fail validation" >&2
  cat "$negative_run_context_extra_key_output" >&2
  exit 1
fi
grep -q "FAIL run context exact keys" "$negative_run_context_extra_key_output"
rm -rf "$negative_run_context_extra_key_fixture"
rm -f "$negative_run_context_extra_key_output"
negative_manifest_artifact_name_fixture="$(mktemp -d)"
negative_manifest_artifact_name_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_manifest_artifact_name_fixture"/
python3 - "$negative_manifest_artifact_name_fixture" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
manifest_path = root / "ci-artifact-manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
manifest["artifactName"] = "chronofocus-ci-v0.10-main-wrong-run12345-attempt1"
manifest_path.write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_manifest_artifact_name_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_manifest_artifact_name_output" 2>&1; then
  echo "Expected negative manifest artifact name fixture to fail validation" >&2
  cat "$negative_manifest_artifact_name_output" >&2
  exit 1
fi
grep -q "FAIL manifest artifact name" "$negative_manifest_artifact_name_output"
rm -rf "$negative_manifest_artifact_name_fixture"
rm -f "$negative_manifest_artifact_name_output"
negative_index_artifact_name_fixture="$(mktemp -d)"
negative_index_artifact_name_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_index_artifact_name_fixture"/
python3 - "$negative_index_artifact_name_fixture" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
index_path = root / "ci-artifact-index.json"
index = json.loads(index_path.read_text(encoding="utf-8"))
index["artifactName"] = "chronofocus-ci-v0.10-main-wrong-run12345-attempt1"
index_path.write_text(
    json.dumps(index, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_index_artifact_name_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_index_artifact_name_output" 2>&1; then
  echo "Expected negative index artifact name fixture to fail validation" >&2
  cat "$negative_index_artifact_name_output" >&2
  exit 1
fi
grep -q "FAIL index artifact name" "$negative_index_artifact_name_output"
rm -rf "$negative_index_artifact_name_fixture"
rm -f "$negative_index_artifact_name_output"
negative_manifest_metadata_fixture="$(mktemp -d)"
negative_manifest_metadata_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_manifest_metadata_fixture"/
python3 - "$negative_manifest_metadata_fixture" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
manifest_path = root / "ci-artifact-manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
manifest["projectName"] = "WrongProject"
manifest_path.write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_manifest_metadata_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_manifest_metadata_output" 2>&1; then
  echo "Expected negative manifest metadata fixture to fail validation" >&2
  cat "$negative_manifest_metadata_output" >&2
  exit 1
fi
grep -q "FAIL manifest metadata" "$negative_manifest_metadata_output"
rm -rf "$negative_manifest_metadata_fixture"
rm -f "$negative_manifest_metadata_output"
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
unexpected_index_entry_fixture="$(mktemp -d)"
unexpected_index_entry_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$unexpected_index_entry_fixture"/
python3 - "$unexpected_index_entry_fixture" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
index_path = root / "ci-artifact-index.json"
index = json.loads(index_path.read_text(encoding="utf-8"))
index["entries"].append({
    "path": "ci-results/unexpected-index-only.log",
    "required": False,
    "exists": False,
    "kind": "missing",
})
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
index_path.write_text(
    json.dumps(index, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$unexpected_index_entry_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$unexpected_index_entry_output" 2>&1; then
  echo "Expected unexpected index entry fixture to fail validation" >&2
  cat "$unexpected_index_entry_output" >&2
  exit 1
fi
grep -q "FAIL index unexpected entries" "$unexpected_index_entry_output"
rm -rf "$unexpected_index_entry_fixture"
rm -f "$unexpected_index_entry_output"
unexpected_local_artifact_fixture="$(mktemp -d)"
unexpected_local_artifact_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$unexpected_local_artifact_fixture"/
printf "extra\n" > "$unexpected_local_artifact_fixture/unexpected-root.log"
if ruby scripts/validate_ci_artifact.rb "$unexpected_local_artifact_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$unexpected_local_artifact_output" 2>&1; then
  echo "Expected unexpected local artifact fixture to fail validation" >&2
  cat "$unexpected_local_artifact_output" >&2
  exit 1
fi
grep -q "FAIL unexpected local artifacts" "$unexpected_local_artifact_output"
rm -rf "$unexpected_local_artifact_fixture"
rm -f "$unexpected_local_artifact_output"
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
mismatched_local_artifact_fixture="$(mktemp -d)"
mismatched_local_artifact_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$mismatched_local_artifact_fixture"/
printf "tampered\n" >> "$mismatched_local_artifact_fixture/static-checks.log"
printf "extra\n" > "$mismatched_local_artifact_fixture/project-reports/mac-snapshots/extra-local-file.txt"
if ruby scripts/validate_ci_artifact.rb "$mismatched_local_artifact_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$mismatched_local_artifact_output" 2>&1; then
  echo "Expected mismatched local artifact fixture to fail validation" >&2
  cat "$mismatched_local_artifact_output" >&2
  exit 1
fi
grep -q "FAIL index required local metadata" "$mismatched_local_artifact_output"
rm -rf "$mismatched_local_artifact_fixture"
rm -f "$mismatched_local_artifact_output"
invalid_snapshot_generated_at_fixture="$(mktemp -d)"
invalid_snapshot_generated_at_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$invalid_snapshot_generated_at_fixture"/
python3 - "$invalid_snapshot_generated_at_fixture" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
manifest_path = root / "project-reports" / "mac-snapshots" / "manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
manifest["generatedAt"] = "not-a-timestamp"
manifest_path.write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$invalid_snapshot_generated_at_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$invalid_snapshot_generated_at_output" 2>&1; then
  echo "Expected invalid snapshot generatedAt fixture to fail validation" >&2
  cat "$invalid_snapshot_generated_at_output" >&2
  exit 1
fi
grep -q "FAIL snapshot manifest generated at" "$invalid_snapshot_generated_at_output"
rm -rf "$invalid_snapshot_generated_at_fixture"
rm -f "$invalid_snapshot_generated_at_output"
mismatched_snapshot_manifest_fixture="$(mktemp -d)"
mismatched_snapshot_manifest_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$mismatched_snapshot_manifest_fixture"/
python3 - "$mismatched_snapshot_manifest_fixture" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
manifest_path = root / "project-reports" / "mac-snapshots" / "manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
manifest["snapshots"][0]["byteCount"] += 1
manifest_path.write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$mismatched_snapshot_manifest_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$mismatched_snapshot_manifest_output" 2>&1; then
  echo "Expected mismatched snapshot manifest fixture to fail validation" >&2
  cat "$mismatched_snapshot_manifest_output" >&2
  exit 1
fi
grep -q "FAIL snapshot byte counts" "$mismatched_snapshot_manifest_output"
rm -rf "$mismatched_snapshot_manifest_fixture"
rm -f "$mismatched_snapshot_manifest_output"
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
ruby -e 'source = File.read(".github/workflows/ci-results.yml"); index_source = source[/index = \{[\s\S]*?"entries": entries,/]; raise "workflow artifact index source missing" unless index_source; raise "workflow artifact index artifactName missing" unless index_source.include?("\"artifactName\": os.environ[\"ARTIFACT_NAME\"]")'
grep -q "errors=\"0\"" .github/workflows/ci-results.yml
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
