#!/usr/bin/env bash
set -euo pipefail

trap 'status=$?; printf "verify_project failed at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2; exit "$status"' ERR

if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

project="ChronoFocus.xcodeproj/project.pbxproj"

verify_ci_action_versions() {
  local workflow_path="$1"
  local checkout_count
  local upload_count

  checkout_count="$(grep -Ec '^[[:space:]]*uses:[[:space:]]*actions/checkout@' "$workflow_path" || true)"
  upload_count="$(grep -Ec '^[[:space:]]*uses:[[:space:]]*actions/upload-artifact@' "$workflow_path" || true)"

  if [[ "$checkout_count" != "1" ]] || ! grep -Eq '^[[:space:]]*uses:[[:space:]]*actions/checkout@v5[[:space:]]*$' "$workflow_path"; then
    echo "Expected exactly one actions/checkout@v5 declaration in $workflow_path" >&2
    return 1
  fi
  if [[ "$upload_count" != "1" ]] || ! grep -Eq '^[[:space:]]*uses:[[:space:]]*actions/upload-artifact@v6[[:space:]]*$' "$workflow_path"; then
    echo "Expected exactly one actions/upload-artifact@v6 declaration in $workflow_path" >&2
    return 1
  fi
}

verify_ci_failure_summary_output() {
  local workflow_path="$1"

  ruby - "$workflow_path" <<'RUBY'
path = ARGV.fetch(0)
source = File.read(path)
final_heading = "      - name: Final CI status\n"
upload_heading = "      - name: Upload Agent C result package\n"

raise "Expected exactly one Final CI status step in #{path}" unless source.scan(final_heading).length == 1
raise "Expected exactly one Agent C artifact upload step in #{path}" unless source.scan(upload_heading).length == 1

final_start = source.index(final_heading)
upload_start = source.index(upload_heading)
raise "Agent C artifact upload must precede Final CI status" unless upload_start < final_start

upload_step = source[upload_start...final_start]
final_step = source[final_start..]
tee_line = 'tee -a "$GITHUB_STEP_SUMMARY" < ci-results/ci-failure-summary.md'
legacy_cat_line = 'cat ci-results/ci-failure-summary.md >> "$GITHUB_STEP_SUMMARY"'
failure_condition = 'if [[ "$STATIC_OUTCOME" != "success" || "$PROJECT_VERIFY_OUTCOME" != "success" || "$BUILD_OUTCOME" != "success" || "$IOS_BUILD_OUTCOME" != "success" ]]; then'

raise "Final CI status must keep if: always()" unless final_step.match?(/^        if: always\(\)$/)
raise "Final CI status must keep shell: bash" unless final_step.match?(/^        shell: bash$/)
raise "Final CI status must keep strict shell options" unless final_step.match?(/^          set -euo pipefail$/)
raise "Final CI status must tee failure summary to stdout and GITHUB_STEP_SUMMARY" unless final_step.scan(tee_line).length == 1
raise "Final CI status must not use the legacy cat-only summary output" if source.include?(legacy_cat_line)

tee_index = final_step.index(tee_line)
condition_index = final_step.index(failure_condition)
exit_index = final_step.index("            exit 1\n")
raise "Final CI status must preserve the four-stage failure condition" unless condition_index
raise "Final CI status must preserve exit 1" unless exit_index
raise "Final CI status must output the failure summary before outcome evaluation" unless tee_index < condition_index && condition_index < exit_index

expected_env = {
  "STATIC_OUTCOME" => "${{ steps.static_checks.outcome }}",
  "PROJECT_VERIFY_OUTCOME" => "${{ steps.project_verification.outcome }}",
  "BUILD_OUTCOME" => "${{ steps.mac_build.outcome }}",
  "IOS_BUILD_OUTCOME" => "${{ steps.ios_build.outcome }}"
}
expected_env.each do |name, expression|
  raise "Final CI status missing #{name} outcome mapping" unless final_step.include?("          #{name}: #{expression}")
end

raise "Agent C artifact upload must keep if: always()" unless upload_step.match?(/^        if: always\(\)$/)
raise "Agent C artifact upload must keep actions\/upload-artifact@v6" unless upload_step.match?(/^        uses: actions\/upload-artifact@v6$/)
raise "Agent C artifact upload must keep the ci-results root path" unless upload_step.scan(/^          path: ci-results$/).length == 1
raise "Failure summary must keep exactly one artifact file writer" unless source.scan('(result_dir / "ci-failure-summary.md").write_text').length == 1
RUBY
}

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
grep -Fq 'Text("\(filteredCount)/\(totalCount) 项")' ChronoFocus/Views/TimerView.swift
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

def function_slices_matching(source, name_pattern)
  slices = []
  source.to_enum(:scan, /\bfunc\s+\w*#{name_pattern}\w*\s*\([^)]*\)[^{]*\{/i).each do
    match = Regexp.last_match
    depth = 0
    ending = nil
    source[match.begin(0)..].each_char.with_index(match.begin(0)) do |character, index|
      depth += 1 if character == "{"
      depth -= 1 if character == "}"
      if depth.zero? && index >= match.end(0)
        ending = index + 1
        break
      end
    end
    slices << source[match.begin(0)...ending] if ending
  end
  slices
end

def assert_slice_contains(path, earlier, later, pattern, message)
  segment = source_slice(path, earlier, later, message)
  matched = pattern.is_a?(Regexp) ? segment.match?(pattern) : segment.include?(pattern)
  raise message unless matched
end

def assert_chip_accessibility(path, chip_name, later)
  segment = source_slice(path, "struct #{chip_name}", later, "#{chip_name} slice missing")
  raise "#{chip_name} must expose selected state text" unless segment.include?("accessibilityStateText") && segment.include?("已选中")
  raise "#{chip_name} must expose filter hint text" unless segment.include?("accessibilityHintText") && segment.include?("筛选\\(title)分类")
  raise "#{chip_name} must expose selected clear hint" unless segment.include?("再次点击清除筛选")
  raise "#{chip_name} must attach accessibility hint" unless segment.include?(".accessibilityHint(accessibilityHintText)")
  raise "#{chip_name} must include selected state in label" unless segment.include?("accessibilityStateText)")
  raise "#{chip_name} must expose selected accessibility trait" unless segment.include?("accessibilityTraits: AccessibilityTraits") && segment.include?(".isSelected") && segment.include?(".accessibilityAddTraits(accessibilityTraits)")
  raise "#{chip_name} must expose Voice Control input labels" unless segment.include?("voiceControlInputLabels: [Text]") && segment.include?("Text(\"\\(title)分类\")") && segment.include?(".accessibilityInputLabels(voiceControlInputLabels)")
end

def assert_preset_picker_accessibility(path, picker_name, later)
  segment = source_slice(path, "struct #{picker_name}", later, "#{picker_name} slice missing")
  raise "#{picker_name} must expose selected state text" unless segment.include?("accessibilityStateText(for preset: TaskCategoryPreset)") && segment.include?("已选中")
  raise "#{picker_name} must expose preset choice hint" unless segment.include?("accessibilityHintText(for preset: TaskCategoryPreset)") && segment.include?("选择\\(preset.title)分类")
  raise "#{picker_name} must attach accessibility hint" unless segment.include?(".accessibilityHint(accessibilityHintText(for: preset))")
  raise "#{picker_name} must include selected state in label" unless segment.include?("accessibilityStateText(for: preset)")
  raise "#{picker_name} must expose selected accessibility trait" unless segment.include?("accessibilityTraits(for preset: TaskCategoryPreset)") && segment.include?(".isSelected") && segment.include?(".accessibilityAddTraits(accessibilityTraits(for: preset))")
  raise "#{picker_name} must expose Voice Control input labels" unless segment.include?("voiceControlInputLabels(for preset: TaskCategoryPreset)") && segment.include?("Text(\"\\(preset.title)分类\")") && segment.include?(".accessibilityInputLabels(voiceControlInputLabels(for: preset))")
end

def assert_calendar_day_accessibility(path, day_name, later)
  segment = source_slice(path, "struct #{day_name}", later, "#{day_name} slice missing")
  raise "#{day_name} must expose date text" unless segment.include?("accessibilityDateText") && segment.include?("M月d日 E")
  raise "#{day_name} must expose selected and muted state text" unless segment.include?("accessibilityStateText") && segment.include?("已选中") && segment.include?("非本月")
  raise "#{day_name} must expose date choice hint" unless segment.include?("accessibilityHintText") && segment.include?("当前正在查看此日期的待办") && segment.include?("选择此日期查看待办")
  raise "#{day_name} must expose selected trait" unless segment.include?("accessibilityTraits: AccessibilityTraits") && segment.include?(".isSelected") && segment.include?(".accessibilityAddTraits(accessibilityTraits)")
  raise "#{day_name} must expose Voice Control input labels" unless segment.include?("voiceControlInputLabels: [Text]") && segment.include?("Text(accessibilityDateText)") && segment.include?("Text(\"选择\\(accessibilityDateText)\")") && segment.include?("Text(\"\\(dayText)日\")") && segment.include?(".accessibilityInputLabels(voiceControlInputLabels)")
  raise "#{day_name} must include date, count, and state in label" unless segment.include?(".accessibilityLabel(\"\\(accessibilityDateText)，\\(taskCount)项待办\\(accessibilityStateText)\")")
  raise "#{day_name} must attach accessibility hint" unless segment.include?(".accessibilityHint(accessibilityHintText)")
end

schedule_category_context_source = source_slice(
  "ChronoFocus/Views/ScheduleView.swift",
  "TaskCategoryFilterBar(",
  "if visibleTasks.isEmpty",
  "Schedule category summary context missing"
)
raise "Schedule category summary must require a selected category and nonempty visible tasks" unless schedule_category_context_source.match?(/if\s+let\s+selectedCategoryName\s*=\s*selectedCategory\s*,\s*!visibleTasks\.isEmpty\s*\{[\s\S]*?SelectedCategorySummaryView\(/)
raise "Schedule category summary must wire add and clear actions" unless schedule_category_context_source.match?(/SelectedCategorySummaryView\([\s\S]*?onAddTask:\s*\{\s*showingEditor = true\s*\}[\s\S]*?onClear:\s*\{\s*selectedCategory = nil\s*\}/)

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
  "private var clearButton: some View",
  "private struct ScheduleCategoryEmptyStateView",
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

schedule_empty_source = source_slice(
  "ChronoFocus/Views/ScheduleView.swift",
  "private struct ScheduleCategoryEmptyStateView",
  "private struct CalendarDayButton",
  "Schedule category empty state source missing"
)
raise "Schedule category empty state must use ContentUnavailableView" unless schedule_empty_source.include?("ContentUnavailableView")
raise "Schedule category empty state title missing category" unless schedule_empty_source.include?("Label(\"暂无\\(category)分类待办\", systemImage: symbolName)")
raise "Schedule category empty state description missing actions" unless schedule_empty_source.include?("可新增此分类待办，或清除筛选查看全部。")
schedule_empty_add_button = segment_slice(
  schedule_empty_source,
  "Button(\"新增此分类\", systemImage: \"plus.circle.fill\", action: onAddTask)",
  "Button(\"清除筛选\", systemImage: \"xmark.circle.fill\", action: onClear)",
  "Schedule category empty state add button source missing"
)
raise "Schedule category empty state add button tap target missing" unless schedule_empty_add_button.include?(".frame(maxWidth: .infinity)") && schedule_empty_add_button.include?(".frame(minHeight: 44)")
raise "Schedule category empty state add accessibility label missing" unless schedule_empty_add_button.include?(".accessibilityLabel(\"新增\\(category)分类待办\")")
raise "Schedule category empty state add Voice Control labels missing" unless schedule_empty_source.include?("Text(\"新增此分类\")") && schedule_empty_source.include?("Text(\"新增\\(category)分类待办\")") && schedule_empty_source.include?("Text(\"新增\\(category)分类\")") && schedule_empty_add_button.include?(".accessibilityInputLabels(addButtonInputLabels)")
schedule_empty_clear_button = segment_slice(
  schedule_empty_source,
  "Button(\"清除筛选\", systemImage: \"xmark.circle.fill\", action: onClear)",
  ".accessibilityLabel(\"\\(category)分类暂无待办，可新增此分类待办或清除筛选\")",
  "Schedule category empty state clear button source missing"
)
raise "Schedule category empty state clear button tap target missing" unless schedule_empty_clear_button.include?(".frame(maxWidth: .infinity)") && schedule_empty_clear_button.include?(".frame(minHeight: 44)")
raise "Schedule category empty state clear accessibility label missing" unless schedule_empty_clear_button.include?(".accessibilityLabel(\"清除\\(category)分类筛选\")")
raise "Schedule category empty state clear Voice Control labels missing" unless schedule_empty_source.include?("Text(\"清除筛选\")") && schedule_empty_source.include?("Text(\"清除\\(category)分类\")") && schedule_empty_source.include?("Text(\"查看全部分类\")") && schedule_empty_clear_button.include?(".accessibilityInputLabels(clearButtonInputLabels)")
raise "Schedule category empty state accessibility summary missing" unless schedule_empty_source.include?(".accessibilityLabel(\"\\(category)分类暂无待办，可新增此分类待办或清除筛选\")")
schedule_task_list_empty_source = source_slice(
  "ChronoFocus/Views/ScheduleView.swift",
  "if visibleTasks.isEmpty",
  "VStack(spacing: 10)",
  "Schedule task empty branch source missing"
)
raise "Schedule category empty state must render only with selected category" unless schedule_task_list_empty_source.include?("if let selectedCategory") && schedule_task_list_empty_source.include?("ScheduleCategoryEmptyStateView(")
raise "Schedule category empty state must wire category and actions" unless schedule_task_list_empty_source.include?("category: selectedCategory") && schedule_task_list_empty_source.include?("showingEditor = true") && schedule_task_list_empty_source.include?("self.selectedCategory = nil")
puts "Schedule category empty state action contracts verified."

mac_schedule_empty_source = source_slice(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "private struct MacScheduleCategoryEmptyStateView",
  "private struct MacSelectedCategorySummaryView",
  "Mac schedule category empty state source missing"
)
raise "Mac schedule category empty state title missing category" unless mac_schedule_empty_source.include?("Label(\"暂无\\(category)分类待办\", systemImage: symbolName)")
raise "Mac schedule category empty state description missing actions" unless mac_schedule_empty_source.include?("可在左侧快速新增此分类待办，或清除筛选查看全部。")
raise "Mac schedule category empty state static actions missing" unless mac_schedule_empty_source.include?("MacSummaryStaticActionView(title: \"新增此分类\"") && mac_schedule_empty_source.include?("MacSummaryStaticActionView(title: \"清除筛选\"")
mac_schedule_empty_add_button = segment_slice(
  mac_schedule_empty_source,
  "Button(\"新增此分类\", systemImage: \"plus.circle.fill\", action: onAddTask)",
  "Button(\"清除筛选\", systemImage: \"xmark.circle.fill\", action: onClear)",
  "Mac schedule category empty state add button source missing"
)
raise "Mac schedule category empty state add button tap target missing" unless mac_schedule_empty_add_button.include?(".frame(minWidth: 104, minHeight: 36)")
raise "Mac schedule category empty state add accessibility label missing" unless mac_schedule_empty_add_button.include?(".accessibilityLabel(\"新增\\(category)分类待办\")")
raise "Mac schedule category empty state add Voice Control labels missing" unless mac_schedule_empty_source.include?("Text(\"新增此分类\")") && mac_schedule_empty_source.include?("Text(\"新增\\(category)分类待办\")") && mac_schedule_empty_source.include?("Text(\"新增\\(category)分类\")") && mac_schedule_empty_add_button.include?(".accessibilityInputLabels(addButtonInputLabels)")
mac_schedule_empty_clear_button = segment_slice(
  mac_schedule_empty_source,
  "Button(\"清除筛选\", systemImage: \"xmark.circle.fill\", action: onClear)",
  ".accessibilityLabel(\"\\(category)分类暂无待办，可新增此分类待办或清除筛选\")",
  "Mac schedule category empty state clear button source missing"
)
raise "Mac schedule category empty state clear button tap target missing" unless mac_schedule_empty_clear_button.include?(".frame(minWidth: 88, minHeight: 36)")
raise "Mac schedule category empty state clear accessibility label missing" unless mac_schedule_empty_clear_button.include?(".accessibilityLabel(\"清除\\(category)分类筛选\")")
raise "Mac schedule category empty state clear Voice Control labels missing" unless mac_schedule_empty_source.include?("Text(\"清除筛选\")") && mac_schedule_empty_source.include?("Text(\"清除\\(category)分类\")") && mac_schedule_empty_source.include?("Text(\"查看全部分类\")") && mac_schedule_empty_clear_button.include?(".accessibilityInputLabels(clearButtonInputLabels)")
raise "Mac schedule category empty state accessibility summary missing" unless mac_schedule_empty_source.include?(".accessibilityLabel(\"\\(category)分类暂无待办，可新增此分类待办或清除筛选\")")
mac_task_list_empty_source = source_slice(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "private struct MacTaskListPanelView",
  "private struct MacScheduleCategoryEmptyStateView",
  "Mac task empty branch source missing"
)
raise "Mac schedule category empty state must render only with selected category" unless mac_task_list_empty_source.include?("if let selectedCategoryName = selectedCategory") && mac_task_list_empty_source.include?("MacScheduleCategoryEmptyStateView(")
raise "Mac schedule category empty state must wire category and actions" unless mac_task_list_empty_source.include?("category: selectedCategoryName") && mac_task_list_empty_source.include?("onAddTaskInCategory(selectedCategoryName)") && mac_task_list_empty_source.include?("selectedCategory = nil")
puts "Mac schedule category empty state action contracts verified."

mac_calendar_root_source = source_slice(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "struct MacScheduleDetailView: View",
  "private struct MacQuickAddCategoryContextView",
  "Mac schedule root source missing"
)
raise "Mac calendar panel must wire selected date quick add" unless mac_calendar_root_source.include?("MacCalendarPanelView(onAddTaskAtDate: prepareQuickAdd(at:))")
mac_calendar_quick_add_source = source_slice(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "private func prepareQuickAdd(at date: Date)",
  "private struct MacQuickAddCategoryContextView",
  "Mac calendar quick add date helper missing"
)
raise "Mac calendar quick add must preserve hour and minute" unless mac_calendar_quick_add_source.include?("calendar.dateComponents([.hour, .minute], from: dueDate)") && mac_calendar_quick_add_source.include?("calendar.dateComponents([.year, .month, .day], from: date)") && mac_calendar_quick_add_source.include?("dateComponents.hour = timeComponents.hour") && mac_calendar_quick_add_source.include?("dateComponents.minute = timeComponents.minute")
raise "Mac calendar quick add must update due date and focus title" unless mac_calendar_quick_add_source.include?("dueDate = calendar.date(from: dateComponents) ?? date") && mac_calendar_quick_add_source.include?("isTaskTitleFocused = true")
mac_calendar_panel_source = source_slice(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "private struct MacCalendarPanelView",
  "private struct MacCalendarRangeEmptyStateView",
  "Mac calendar panel source missing"
)
raise "Mac calendar panel quick add closure missing" unless mac_calendar_panel_source.include?("let onAddTaskAtDate: (Date) -> Void")
raise "Mac calendar empty branch missing actionable view" unless mac_calendar_panel_source.include?("if visibleTasks.isEmpty") && mac_calendar_panel_source.include?("MacCalendarRangeEmptyStateView(")
raise "Mac calendar empty branch must pass selected date" unless mac_calendar_panel_source.include?("selectedDate: selectedDate") && mac_calendar_panel_source.include?("onAddTaskAtDate(selectedDate)")
mac_calendar_empty_source = source_slice(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "private struct MacCalendarRangeEmptyStateView",
  "private struct MacCalendarDayCell",
  "Mac calendar range empty state source missing"
)
raise "Mac calendar range empty state title missing" unless mac_calendar_empty_source.include?("Label(\"当前范围暂无待办\", systemImage: \"calendar.badge.plus\")")
raise "Mac calendar range empty state date formatting missing" unless mac_calendar_empty_source.include?("formatter.dateFormat = \"M月d日 E\"")
raise "Mac calendar range empty state description missing selected date" unless mac_calendar_empty_source.include?("可直接为\\(selectedDateText)准备快速新增。")
raise "Mac calendar range empty state snapshot action missing" unless mac_calendar_empty_source.include?("MacStaticScheduleActionChipView(") && mac_calendar_empty_source.include?("title: \"新增到此日期\"") && mac_calendar_empty_source.include?("accessibilityLabelText: \"新增\\(selectedDateText)待办\"")
mac_calendar_empty_button = segment_slice(
  mac_calendar_empty_source,
  "Button(\"新增到此日期\", systemImage: \"plus.circle.fill\", action: onAddTask)",
  ".accessibilityElement(children: .contain)",
  "Mac calendar range empty state button source missing"
)
raise "Mac calendar range empty state button tap target missing" unless mac_calendar_empty_button.include?(".frame(minWidth: 132, minHeight: 36)")
raise "Mac calendar range empty state accessibility label missing" unless mac_calendar_empty_button.include?(".accessibilityLabel(\"新增\\(selectedDateText)待办\")")
raise "Mac calendar range empty state accessibility hint missing" unless mac_calendar_empty_button.include?("将左侧快速新增截止日期设为\\(selectedDateText)，并聚焦任务名称")
raise "Mac calendar range empty state Voice Control labels missing" unless mac_calendar_empty_source.include?("Text(\"新增到此日期\")") && mac_calendar_empty_source.include?("Text(\"新增\\(selectedDateText)待办\")") && mac_calendar_empty_source.include?("Text(\"\\(selectedDateText)新增待办\")") && mac_calendar_empty_button.include?(".accessibilityInputLabels(addButtonInputLabels)")
raise "Mac calendar range empty state accessibility summary missing" unless mac_calendar_empty_source.include?(".accessibilityLabel(\"当前范围暂无待办，可新增到\\(selectedDateText)\")")
puts "Mac calendar range empty state quick add contracts verified."

schedule_task_cell = source_slice(
  "ChronoFocus/Views/ScheduleView.swift",
  "private struct ScheduleTaskCell",
  "struct TaskEditorView",
  "Schedule task cell source missing"
)
schedule_task_list_source = source_slice(
  "ChronoFocus/Views/ScheduleView.swift",
  "private var taskList: some View",
  "private struct TaskCategoryFilterBar",
  "Schedule task list source missing"
)
raise "Schedule task cell category preset missing" unless schedule_task_cell.include?("TaskCategoryPreset.matching(task.category)")
raise "Schedule task cell category symbol missing" unless schedule_task_cell.include?("private var categorySymbolName")
raise "Schedule task cell category badge missing" unless schedule_task_cell.include?("Label(task.category, systemImage: categorySymbolName)")
raise "Schedule task cell category accessibility label missing" unless schedule_task_cell.include?(".accessibilityLabel(\"\\(task.category)分类\")")
raise "Schedule task cell category Voice Control input labels missing" unless schedule_task_cell.include?(".accessibilityInputLabels([Text(task.category), Text(\"\\(task.category)分类\")])")
raise "Schedule task cell must keep due date as secondary metadata" unless schedule_task_cell.include?("if let dueDate = task.dueDate") && schedule_task_cell.include?("dueDate.scheduleTimeText")
raise "Schedule task completion action accessibility label missing category" unless schedule_task_cell.include?("task.isDone ? \"标记\\(task.title)待办未完成，\\(task.category)分类\" : \"完成\\(task.title)待办，\\(task.category)分类\"")
raise "Schedule task completion action Voice Control labels missing category" unless schedule_task_cell.include?("Text(task.isDone ? \"标记\\(task.category)分类\\(task.title)未完成\" : \"完成\\(task.category)分类\\(task.title)\")") && schedule_task_cell.include?("Text(task.isDone ? \"\\(task.category)分类\\(task.title)未完成\" : \"\\(task.category)分类\\(task.title)完成\")")
raise "Schedule task enable action accessibility label missing category" unless schedule_task_cell.include?("task.isEnabled ? \"停用\\(task.title)待办，\\(task.category)分类\" : \"启用\\(task.title)待办，\\(task.category)分类\"")
raise "Schedule task enable action Voice Control labels missing category" unless schedule_task_cell.include?("Text(task.isEnabled ? \"停用\\(task.category)分类\\(task.title)\" : \"启用\\(task.category)分类\\(task.title)\")") && schedule_task_cell.include?("Text(task.isEnabled ? \"\\(task.category)分类\\(task.title)停用\" : \"\\(task.category)分类\\(task.title)启用\")")
raise "Schedule task edit action accessibility label missing category" unless schedule_task_cell.include?("\"编辑\\(task.title)待办，\\(task.category)分类\"")
raise "Schedule task edit action Voice Control labels missing category" unless schedule_task_cell.include?("Text(\"编辑\\(task.category)分类\\(task.title)\")") && schedule_task_cell.include?("Text(\"\\(task.category)分类\\(task.title)编辑\")")
raise "Schedule task swipe edit accessibility label missing category" unless schedule_task_list_source.include?(".accessibilityLabel(\"编辑\\(task.title)待办，\\(task.category)分类\")")
raise "Schedule task swipe edit Voice Control labels missing category" unless schedule_task_list_source.include?("Text(\"编辑\\(task.category)分类\\(task.title)\")") && schedule_task_list_source.include?("Text(\"\\(task.category)分类\\(task.title)编辑\")")
raise "Schedule task swipe delete accessibility label missing category" unless schedule_task_list_source.include?(".accessibilityLabel(\"删除\\(task.title)待办，\\(task.category)分类\")")
raise "Schedule task swipe delete Voice Control labels missing category" unless schedule_task_list_source.include?("Text(\"删除\\(task.category)分类\\(task.title)\")") && schedule_task_list_source.include?("Text(\"\\(task.category)分类\\(task.title)删除\")")

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

timer_picker_source = source_slice(
  "ChronoFocus/Views/TimerView.swift",
  "private var taskPicker",
  "private var todayStrip",
  "Timer task picker source missing"
)
summary_nonempty_branch_start =
  if timer_picker_source.include?("if let selectedTaskCategory, !filteredUpcomingTasks.isEmpty")
    "if let selectedTaskCategory, !filteredUpcomingTasks.isEmpty"
  elsif timer_picker_source.include?("if !filteredUpcomingTasks.isEmpty, let selectedTaskCategory")
    "if !filteredUpcomingTasks.isEmpty, let selectedTaskCategory"
  end
raise "Timer category summary must render only for a nonempty selected category" unless summary_nonempty_branch_start
timer_summary_nonempty_branch = segment_slice(
  timer_picker_source,
  summary_nonempty_branch_start,
  "if filteredUpcomingTasks.isEmpty, let selectedTaskCategory",
  "Timer category nonempty summary branch source missing"
)
raise "Timer category nonempty branch must contain the summary" unless timer_summary_nonempty_branch.match?(/TimerSelectedTaskCategorySummaryView\([\s\S]*?filteredCount: filteredUpcomingTasks\.count[\s\S]*?totalCount: upcomingTasks\.count[\s\S]*?showingCategoryEditor = true[\s\S]*?onClear: clearTaskCategoryFilter/)
raise "Timer task picker must render the category summary exactly once" unless timer_picker_source.scan("TimerSelectedTaskCategorySummaryView(").length == 1
timer_empty_branch_source = segment_slice(
  timer_picker_source,
  "if filteredUpcomingTasks.isEmpty, let selectedTaskCategory",
  "VStack(spacing: 10)",
  "Timer category empty branch source missing"
)
raise "Timer category empty branch must not contain the nonempty summary" if timer_empty_branch_source.include?("TimerSelectedTaskCategorySummaryView(")
category_empty_branch_offset = timer_picker_source.index("if filteredUpcomingTasks.isEmpty, let selectedTaskCategory")
global_empty_branch_offset = timer_picker_source.index("else if upcomingTasks.isEmpty")
raise "Timer selected category empty state must take priority over the global empty state" unless category_empty_branch_offset && global_empty_branch_offset && category_empty_branch_offset < global_empty_branch_offset
raise "Timer filtered task rows must hide only the repeated visual category badge" unless timer_picker_source.include?("showsCategoryBadge: selectedTaskCategory == nil")

timer_summary_source = source_slice(
  "ChronoFocus/Views/TimerView.swift",
  "private struct TimerSelectedTaskCategorySummaryView",
  "private struct TimerTaskCategoryEmptyView",
  "Timer category summary source missing"
)
raise "Timer category summary must accept total count and add action" unless timer_summary_source.include?("let totalCount: Int") && timer_summary_source.include?("let onAddTask: () -> Void")
timer_summary_content_source = source_slice(
  "ChronoFocus/Views/TimerView.swift",
  "private struct TimerSelectedTaskCategorySummaryContent",
  "private struct TimerTaskCategoryEmptyView",
  "Timer category summary content source missing"
)
raise "Timer category summary content must visibly expose filtered and total counts" unless timer_summary_content_source.include?('Text("\(filteredCount)/\(totalCount) 项")')
raise "Timer category summary adaptive layout missing" unless timer_summary_source.include?("ViewThatFits(in: .horizontal)") && timer_summary_source.include?("axis: .horizontal") && timer_summary_source.include?("axis: .vertical")
raise "Timer category summary accessibility label must announce add and clear actions" unless timer_summary_source.include?("可新增此分类待办或清除筛选")
raise "Timer category summary add button missing" unless timer_summary_source.include?("Button(\"新增此分类\", systemImage: \"plus.circle.fill\", action: onAddTask)")
raise "Timer category summary clear button missing" unless timer_summary_source.include?("Button(\"清除筛选\", systemImage: \"xmark.circle.fill\", action: onClear)")
raise "Timer category summary action tap targets missing" unless timer_summary_source.scan(".frame(minHeight: 44)").length >= 2
raise "Timer category summary add accessibility label missing" unless timer_summary_source.include?(".accessibilityLabel(\"新增\\(category)分类待办\")")
raise "Timer category summary add Voice Control input labels missing" unless timer_summary_source.include?("Text(\"新增此分类\")") && timer_summary_source.include?("Text(\"新增\\(category)分类待办\")")
raise "Timer category summary clear accessibility label missing" unless timer_summary_source.include?(".accessibilityLabel(\"清除\\(category)分类筛选\")")
raise "Timer category summary clear Voice Control input labels missing" unless timer_summary_source.include?("Text(\"清除筛选\")") && timer_summary_source.include?("Text(\"清除\\(category)分类\")")

timer_empty_source = source_slice(
  "ChronoFocus/Views/TimerView.swift",
  "private struct TimerTaskCategoryEmptyView",
  "private struct TimerTaskCategoryBadge",
  "Timer category empty view source missing"
)
raise "Timer category empty view preset missing" unless timer_empty_source.include?("TaskCategoryPreset.matching(category)")
raise "Timer category empty description missing actions" unless timer_empty_source.include?("可新增此分类待办，或清除筛选查看全部。")
timer_empty_add_button = segment_slice(
  timer_empty_source,
  "Button(\"新增此分类\", systemImage: \"plus.circle.fill\", action: onAddTask)",
  "Button(\"清除\", systemImage: \"xmark.circle.fill\", action: onClear)",
  "Timer category empty add button source missing"
)
raise "Timer category empty add button tap target missing" unless timer_empty_add_button.include?(".frame(maxWidth: .infinity)") && timer_empty_add_button.include?(".frame(minHeight: 44)")
raise "Timer category empty add accessibility label missing" unless timer_empty_add_button.include?(".accessibilityLabel(\"新增\\(category)分类待办\")")
raise "Timer category empty add Voice Control labels missing" unless timer_empty_source.include?("Text(\"新增此分类\")") && timer_empty_source.include?("Text(\"新增\\(category)分类待办\")") && timer_empty_source.include?("Text(\"新增\\(category)分类\")") && timer_empty_add_button.include?(".accessibilityInputLabels(addButtonInputLabels)")
timer_empty_clear_button = segment_slice(
  timer_empty_source,
  "Button(\"清除\", systemImage: \"xmark.circle.fill\", action: onClear)",
  ".fixedSize(horizontal: axis == .horizontal, vertical: false)",
  "Timer category empty clear button source missing"
)
raise "Timer category empty clear button tap target missing" unless timer_empty_clear_button.include?(".frame(minWidth: 72)") && timer_empty_clear_button.include?(".frame(minHeight: 44)")
raise "Timer category empty clear accessibility label missing" unless timer_empty_clear_button.include?(".accessibilityLabel(\"清除\\(category)分类筛选\")")
raise "Timer category empty clear Voice Control labels missing" unless timer_empty_source.include?("Text(\"清除筛选\")") && timer_empty_source.include?("Text(\"清除\\(category)分类\")") && timer_empty_source.include?("Text(\"查看全部分类\")") && timer_empty_clear_button.include?(".accessibilityInputLabels(clearButtonInputLabels)")
raise "Timer category empty state accessibility label missing" unless timer_empty_source.include?(".accessibilityLabel(\"\\(category)分类暂无可启动待办，可新增此分类待办或清除筛选\")")
raise "Timer category empty actions adaptive layout missing" unless timer_empty_source.include?("ViewThatFits(in: .horizontal)") && timer_empty_source.include?("axis: .horizontal") && timer_empty_source.include?("axis: .vertical")
raise "Timer category empty branch must render only with selected category" unless timer_empty_branch_source.include?("TimerTaskCategoryEmptyView(") && timer_empty_branch_source.include?("category: selectedTaskCategory")
raise "Timer category empty branch must wire add and clear actions" unless timer_empty_branch_source.include?("showingCategoryEditor = true") && timer_empty_branch_source.include?("onClear: clearTaskCategoryFilter")
raise "Timer category empty sheet must open TaskEditorView with selected category" unless File.read("ChronoFocus/Views/TimerView.swift").include?(".sheet(isPresented: $showingCategoryEditor)") && File.read("ChronoFocus/Views/TimerView.swift").include?("TaskEditorView(") && File.read("ChronoFocus/Views/TimerView.swift").include?("initialCategory: selectedTaskCategory")
summary_add_action_source = segment_slice(
  timer_picker_source,
  "onAddTask: {",
  "onClear: clearTaskCategoryFilter",
  "Timer category summary add action source missing"
)
raise "Timer category summary add action must preserve selected filter" unless summary_add_action_source.include?("showingCategoryEditor = true") && !summary_add_action_source.include?("selectedTaskCategory = nil")

timer_task_row_source = source_slice(
  "ChronoFocus/Views/TimerView.swift",
  "private struct TaskRow",
  "private struct TimerTaskCategoryFilterBar",
  "Timer task row source missing"
)
raise "Timer TaskRow visual category badge option must default to true" unless timer_task_row_source.match?(/(?:let|var)\s+showsCategoryBadge(?:\s*:\s*Bool)?\s*=\s*true/)
raise "Timer TaskRow category badge must be conditionally visual" unless timer_task_row_source.match?(/if\s+showsCategoryBadge\s*\{[\s\S]*?TimerTaskCategoryBadge\(task:\s*task\)[\s\S]*?\}/)
raise "Timer TaskRow category accessibility semantics must remain independent" unless timer_task_row_source.include?(".accessibilityLabel(\"\\(task.title)，\\(task.category)分类，\\(selectionStateText)\")") && timer_task_row_source.include?(".accessibilityHint(selectionHintText)") && timer_task_row_source.include?(".accessibilityInputLabels(selectionInputLabels)") && timer_task_row_source.include?(".accessibilityAddTraits(selectionAccessibilityTraits)")
raise "Timer TaskRow running-state accessibility must remain available" unless timer_task_row_source.include?("计时运行中不可切换当前待办") && timer_task_row_source.include?("Text(\"\\(task.category)分类待办\")")
puts "Timer category empty state action contracts verified."

timer_root_source = source_slice(
  "ChronoFocus/Views/TimerView.swift",
  "struct TimerView: View",
  "private struct MetricPill",
  "TimerView declaration source missing"
)
timer_queue_limit_source = segment_slice(
  timer_root_source,
  "private let collapsedTaskLimit",
  "private var currentTint",
  "Timer task queue collapsed limit declaration missing"
)
raise "Timer task queue collapsed limit must remain 4" unless timer_queue_limit_source.match?(/private\s+let\s+collapsedTaskLimit\s*=\s*4/)
timer_visible_tasks_source = segment_slice(
  timer_root_source,
  "private var visibleUpcomingTasks",
  "private var hiddenTaskCount",
  "Timer visible upcoming tasks declaration missing"
)
raise "Timer expanded queue must expose the full filtered task list" unless timer_visible_tasks_source.include?("isTaskQueueExpanded") && timer_visible_tasks_source.include?("? filteredUpcomingTasks")
raise "Timer collapsed queue must use the shared limit" unless timer_visible_tasks_source.include?("Array(filteredUpcomingTasks.prefix(collapsedTaskLimit))")
timer_hidden_count_source = segment_slice(
  timer_root_source,
  "private var hiddenTaskCount",
  "private var taskQueueToggleTitle",
  "Timer hidden task count declaration missing"
)
raise "Timer hidden task count must derive from filtered count and shared limit" unless timer_hidden_count_source.include?("max(filteredUpcomingTasks.count - collapsedTaskLimit, 0)")
timer_queue_accessibility_source = segment_slice(
  timer_root_source,
  "private var taskQueueToggleTitle",
  "private var taskPickerCountText",
  "Timer task queue accessibility declarations missing"
)
raise "Timer queue toggle visible titles missing" unless timer_queue_accessibility_source.include?('isTaskQueueExpanded ? "收起" : "显示其余 \(hiddenTaskCount) 项"')
raise "Timer queue toggle VoiceOver labels missing" unless timer_queue_accessibility_source.include?('isTaskQueueExpanded ? "收起待办列表" : "显示其余\(hiddenTaskCount)项待办"')
raise "Timer queue toggle VoiceOver expanded value missing" unless timer_queue_accessibility_source.include?('已展开，显示全部 \(filteredUpcomingTasks.count) 项')
raise "Timer queue toggle VoiceOver collapsed value missing" unless timer_queue_accessibility_source.include?('已收起，显示 \(collapsedTaskLimit) 项，共 \(filteredUpcomingTasks.count) 项')
raise "Timer queue toggle VoiceOver expanded hint missing" unless timer_queue_accessibility_source.include?('收起后仅显示前 \(collapsedTaskLimit) 项待办')
raise "Timer queue toggle VoiceOver collapsed hint missing" unless timer_queue_accessibility_source.include?('展开后可查看其余 \(hiddenTaskCount) 项待办') && timer_queue_accessibility_source.include?("计时运行中待办仍不可切换")
raise "Timer queue toggle Voice Control labels must lead with visible title in both states" unless timer_queue_accessibility_source.scan(/return\s*\[\s*Text\(taskQueueToggleTitle\)/).length == 2
raise "Timer queue expanded Voice Control labels missing" unless timer_queue_accessibility_source.include?('Text("收起待办")') && timer_queue_accessibility_source.include?('Text("收起待办列表")')
raise "Timer queue collapsed Voice Control labels missing" unless timer_queue_accessibility_source.include?('Text("显示更多待办")') && timer_queue_accessibility_source.include?('Text("显示更多")') && timer_queue_accessibility_source.include?('Text("展开待办")')
timer_queue_rows_source = segment_slice(
  timer_picker_source,
  "ForEach(visibleUpcomingTasks)",
  "if filteredUpcomingTasks.count > collapsedTaskLimit",
  "Timer task queue row declaration missing"
)
raise "Timer task queue rows must remain disabled while running" unless timer_queue_rows_source.include?(".disabled(engine.isRunning)")
timer_queue_toggle_source = segment_slice(
  timer_picker_source,
  "if filteredUpcomingTasks.count > collapsedTaskLimit",
  ".onChange(of: selectedTaskCategory)",
  "Timer task queue toggle declaration missing"
)
raise "Timer queue toggle must only render above the collapsed limit" unless timer_queue_toggle_source.match?(/if\s+filteredUpcomingTasks\.count\s*>\s*collapsedTaskLimit\s*\{/)
raise "Timer queue toggle action missing" unless timer_queue_toggle_source.include?("isTaskQueueExpanded.toggle()")
raise "Timer queue toggle title and chevrons missing" unless timer_queue_toggle_source.include?("taskQueueToggleTitle") && timer_queue_toggle_source.include?('isTaskQueueExpanded ? "chevron.up" : "chevron.down"')
raise "Timer queue toggle 44pt tap target missing" unless timer_queue_toggle_source.include?(".frame(maxWidth: .infinity, minHeight: 44)")
raise "Timer queue toggle VoiceOver modifiers missing" unless timer_queue_toggle_source.include?(".accessibilityLabel(taskQueueToggleAccessibilityLabel)") && timer_queue_toggle_source.include?(".accessibilityValue(taskQueueToggleAccessibilityValue)") && timer_queue_toggle_source.include?(".accessibilityHint(taskQueueToggleAccessibilityHint)")
raise "Timer queue toggle Voice Control modifier missing" unless timer_queue_toggle_source.include?(".accessibilityInputLabels(taskQueueToggleInputLabels)")
raise "Timer queue toggle must remain available while running" if timer_queue_toggle_source.include?(".disabled(engine.isRunning)")
raise "Timer queue must collapse when category changes" unless timer_picker_source.match?(/\.onChange\(of:\s*selectedTaskCategory\)\s*\{[^}]*isTaskQueueExpanded\s*=\s*false[^}]*\}/m)
raise "Timer queue must collapse when filtered task count changes" unless timer_picker_source.match?(/\.onChange\(of:\s*filteredUpcomingTasks\.count\)\s*\{[^}]*isTaskQueueExpanded\s*=\s*false[^}]*\}/m)
puts "Timer task queue expansion contracts verified."

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

mac_schedule_category_context_source = source_slice(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "MacCategoryFilterBar(",
  "if visibleTasks.isEmpty",
  "Mac category summary context missing"
)
raise "Mac category summary must require a selected category and nonempty visible tasks" unless mac_schedule_category_context_source.match?(/if\s+let\s+selectedCategoryName\s*=\s*selectedCategory\s*,\s*!visibleTasks\.isEmpty\s*\{[\s\S]*?MacSelectedCategorySummaryView\(/)
raise "Mac category summary must wire add and clear actions" unless mac_schedule_category_context_source.match?(/MacSelectedCategorySummaryView\([\s\S]*?onAddTask:\s*\{\s*onAddTaskInCategory\(selectedCategoryName\)\s*\}[\s\S]*?\)\s*\{\s*selectedCategory = nil\s*\}/)

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
  ".frame(maxWidth: axis == .vertical ? .infinity : nil, alignment: .leading)",
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
raise "Mac task completion static accessibility label missing category" unless mac_task_list_source.include?("title: task.isDone ? \"标记\\(task.title)待办未完成，\\(task.category)分类\" : \"完成\\(task.title)待办，\\(task.category)分类\"")
raise "Mac task completion action accessibility label missing category" unless mac_task_list_source.include?(".accessibilityLabel(task.isDone ? \"标记\\(task.title)待办未完成，\\(task.category)分类\" : \"完成\\(task.title)待办，\\(task.category)分类\")")
raise "Mac task completion action Voice Control labels missing category" unless mac_task_list_source.include?("Text(task.isDone ? \"标记\\(task.category)分类\\(task.title)未完成\" : \"完成\\(task.category)分类\\(task.title)\")") && mac_task_list_source.include?("Text(task.isDone ? \"\\(task.category)分类\\(task.title)未完成\" : \"\\(task.category)分类\\(task.title)完成\")")
raise "Mac task enable static accessibility label missing category" unless mac_task_list_source.include?("MacStaticTaskEnablePillView(isEnabled: task.isEnabled, taskTitle: task.title, taskCategory: task.category)")
raise "Mac task enable action accessibility label missing category" unless mac_task_list_source.include?(".accessibilityLabel(task.isEnabled ? \"停用\\(task.title)待办，\\(task.category)分类\" : \"启用\\(task.title)待办，\\(task.category)分类\")")
raise "Mac task enable action Voice Control labels missing category" unless mac_task_list_source.include?("Text(task.isEnabled ? \"停用\\(task.category)分类\\(task.title)\" : \"启用\\(task.category)分类\\(task.title)\")") && mac_task_list_source.include?("Text(task.isEnabled ? \"\\(task.category)分类\\(task.title)停用\" : \"\\(task.category)分类\\(task.title)启用\")")
raise "Mac task delete static accessibility label missing category" unless mac_task_list_source.include?("MacStaticScheduleActionChipView(title: \"删除\\(task.title)待办，\\(task.category)分类\"")
raise "Mac task delete action accessibility label missing category" unless mac_task_list_source.include?(".accessibilityLabel(\"删除\\(task.title)待办，\\(task.category)分类\")")
raise "Mac task delete action Voice Control labels missing category" unless mac_task_list_source.include?("Text(\"删除\\(task.category)分类\\(task.title)\")") && mac_task_list_source.include?("Text(\"\\(task.category)分类\\(task.title)删除\")")
mac_static_enable_source = source_slice(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "private struct MacStaticTaskEnablePillView",
  "private struct MacCalendarPanelView",
  "Mac static task enable pill source missing"
)
raise "Mac static task enable pill category semantics missing" unless mac_static_enable_source.include?("var taskTitle: String?") && mac_static_enable_source.include?("var taskCategory: String?") && mac_static_enable_source.include?("return \"\\(statusText)，\\(taskCategory)分类\"")
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
raise "Mac quick add title field accessibility label missing category context" unless mac_quick_add_source.include?("private var quickAddTitleAccessibilityLabel: String") && mac_quick_add_source.include?("\"任务名称，当前将新增到\\(quickAddCategoryName)分类\"")
raise "Mac quick add title field Voice Control labels missing category context" unless mac_quick_add_source.include?("private var quickAddTitleInputLabels: [Text]") && mac_quick_add_source.include?("Text(\"任务名称\")") && mac_quick_add_source.include?("Text(\"新增\\(quickAddCategoryName)分类待办\")") && mac_quick_add_source.include?("Text(\"\\(quickAddCategoryName)分类任务名称\")")
raise "Mac quick add title text field accessibility missing" unless mac_quick_add_source.include?("TextField(\"任务名称\", text: $taskTitle)") && mac_quick_add_source.include?(".accessibilityLabel(quickAddTitleAccessibilityLabel)") && mac_quick_add_source.include?(".accessibilityHint(\"输入待办标题，保存后会归入当前分类\")") && mac_quick_add_source.include?(".accessibilityInputLabels(quickAddTitleInputLabels)")
puts "Mac quick add title field category context contracts verified."

task_editor_category_source = source_slice(
  "ChronoFocus/Views/ScheduleView.swift",
  "struct TaskEditorView",
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
raise "Task editor save title fallback missing" unless task_editor_category_source.include?("private var taskTitleDisplayName: String") && task_editor_category_source.include?("return trimmedTitle.isEmpty ? \"未命名\" : trimmedTitle")
raise "Task editor save action helper missing" unless task_editor_category_source.include?("private var saveActionText: String") && task_editor_category_source.include?("task == nil ? \"新增\" : \"保存\"")
raise "Task editor save plan helper missing" unless task_editor_category_source.include?("private var savePlanDescription: String") && task_editor_category_source.include?("startMode == .plannedRounds ? \"预计 \\(estimatedRounds) 轮\" : \"只设开始\"")
raise "Task editor save accessibility label missing" unless task_editor_category_source.include?("private var saveButtonAccessibilityLabel: String") && task_editor_category_source.include?("\\(saveActionText)\\(taskTitleDisplayName)待办，\\(categoryDisplayName)分类，\\(savePlanDescription)") && task_editor_category_source.include?(".accessibilityLabel(saveButtonAccessibilityLabel)")
raise "Task editor save Voice Control labels missing" unless task_editor_category_source.include?("private var saveButtonInputLabels: [Text]") && task_editor_category_source.include?("Text(taskTitleDisplayName)") && task_editor_category_source.include?("Text(categoryDisplayName)") && task_editor_category_source.include?("Text(\"\\(categoryDisplayName)分类\")") && task_editor_category_source.include?("Text(\"\\(categoryDisplayName)分类保存\")") && task_editor_category_source.include?(".accessibilityInputLabels(saveButtonInputLabels)")
puts "Task editor save category accessibility contracts verified."
raise "Task editor cancel action helper missing" unless task_editor_category_source.include?("private var cancelActionText: String") && task_editor_category_source.include?("task == nil ? \"取消新增\" : \"取消编辑\"")
raise "Task editor cancel accessibility label missing" unless task_editor_category_source.include?("private var cancelButtonAccessibilityLabel: String") && task_editor_category_source.include?("\\(cancelActionText)\\(taskTitleDisplayName)待办，\\(categoryDisplayName)分类") && task_editor_category_source.include?(".accessibilityLabel(cancelButtonAccessibilityLabel)")
raise "Task editor cancel Voice Control labels missing" unless task_editor_category_source.include?("private var cancelButtonInputLabels: [Text]") && task_editor_category_source.include?("Text(cancelActionText)") && task_editor_category_source.include?("Text(taskTitleDisplayName)") && task_editor_category_source.include?("Text(categoryDisplayName)") && task_editor_category_source.include?("Text(\"\\(categoryDisplayName)分类\")") && task_editor_category_source.include?("Text(\"\\(categoryDisplayName)分类取消\")") && task_editor_category_source.include?(".accessibilityInputLabels(cancelButtonInputLabels)")
puts "Task editor cancel category accessibility contracts verified."

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

ios_existing_category_source = source_slice(
  "ChronoFocus/Views/ScheduleView.swift",
  "struct TaskEditorView",
  "private struct TaskCategoryPresetPicker",
  "iOS existing category source missing"
)
mac_existing_category_source = source_slice(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "struct MacScheduleDetailView",
  "private struct MacStaticScheduleActionChipView",
  "Mac existing category source missing"
)
raise "iOS existing categories must come from store.taskCategories" unless ios_existing_category_source.include?("return store.taskCategories.compactMap")
raise "Mac existing categories must come from store.taskCategories" unless mac_existing_category_source.include?("macExistingCategoryOptions(categories: store.taskCategories, tasks: store.tasks)")
raise "iOS existing categories must preserve free text and preset controls" unless ios_existing_category_source.include?("TextField(\"分类\", text: $category)") && ios_existing_category_source.include?("TaskCategoryPresetPicker(category: $category, accentHex: $accentHex)")
raise "Mac existing categories must preserve free text and preset controls" unless mac_existing_category_source.include?("TextField(\"分类\", text: $category)") && mac_existing_category_source.include?("MacCategoryPresetPicker(category: $category, accentHex: $accentHex)")
preset_source = source_slice("ChronoFocus/Models/AppModels.swift", "struct TaskCategoryPreset", "struct FocusTask", "Task category preset source missing")
raise "Existing category controls must retain exactly five presets" unless preset_source.scan("TaskCategoryPreset(title:").length == 5
raise "iOS preset exclusion must use normalized preset keys" unless ios_existing_category_source.include?("let presetKeys = Set(TaskCategoryPreset.defaults.map { categoryComparisonKey(for: $0.title) })") && ios_existing_category_source.include?("!presetKeys.contains(comparisonKey)")
raise "Mac preset exclusion must use normalized preset keys" unless mac_existing_category_source.include?("let presetKeys = Set(TaskCategoryPreset.defaults.map { macCategoryComparisonKey($0.title) })") && mac_existing_category_source.include?("!presetKeys.contains(comparisonKey)")
folding_options = "options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]"
raise "iOS category comparison must use POSIX folding" unless ios_existing_category_source.include?(folding_options) && ios_existing_category_source.include?("Locale(identifier: \"en_US_POSIX\")")
raise "Mac category comparison must use POSIX folding" unless mac_existing_category_source.include?(folding_options) && mac_existing_category_source.include?("Locale(identifier: \"en_US_POSIX\")")
raise "iOS existing categories must preserve stable first occurrence order" unless ios_existing_category_source.include?("return store.taskCategories.compactMap") && ios_existing_category_source.include?("seenKeys.insert(comparisonKey).inserted")
raise "Mac existing categories must preserve stable first occurrence order" unless mac_existing_category_source.include?("for category in categories") && mac_existing_category_source.include?("seenKeys.insert(comparisonKey).inserted") && mac_existing_category_source.include?("options.append(")
raise "iOS representative color must use the first matching store task" unless ios_existing_category_source.include?("store.tasks.first { task in") && ios_existing_category_source.include?("accentHex = matchingTask.accentHex")
raise "Mac representative color must use the first matching task" unless mac_existing_category_source.include?("let representativeAccentHex = tasks.first {") && mac_existing_category_source.include?("accentHex = representativeAccentHex")
raise "iOS existing category selection must only update form drafts" unless ios_existing_category_source.include?("category = option.name") && ios_existing_category_source.include?("if let matchingTask = firstTask(matching: option)")
raise "Mac existing category selection must only update form drafts" unless mac_existing_category_source.include?("category = option.displayName") && mac_existing_category_source.include?("if let representativeAccentHex = option.representativeAccentHex")
ios_select_source = segment_slice(ios_existing_category_source, "private func selectExistingCategory", "private func save()", "iOS existing category selection source missing")
mac_select_source = segment_slice(mac_existing_category_source, "private func selectExistingCategory", "private func prepareQuickAdd(at date:", "Mac existing category selection source missing")
for source, platform in [[ios_select_source, "iOS"], [mac_select_source, "Mac"]]
  raise "#{platform} existing category selection must not persist or dismiss" if source.match?(/store\.|save\(|dismiss\(|addTask\(|updateTask\(/)
end
raise "iOS existing category selected state must use normalized identity" unless ios_existing_category_source.include?("categoryComparisonKey(for: category) == option.comparisonKey")
raise "Mac existing category selected state must use normalized identity" unless mac_existing_category_source.include?("macCategoryComparisonKey(selectedCategory) == option.comparisonKey")
repeat_hint = "当前使用该分类，再次点击保持当前分类"
raise "iOS repeated selection must preserve the current category" unless ios_existing_category_source.include?(repeat_hint)
raise "Mac repeated selection must preserve the current category" unless mac_existing_category_source.include?(repeat_hint)
raise "iOS existing category button must preserve 44 point target and dynamic text" unless ios_existing_category_source.include?(".frame(maxWidth: 220, minHeight: 44, alignment: .leading)") && ios_existing_category_source.include?(".fixedSize(horizontal: false, vertical: true)")
raise "iOS existing category selected indicator missing" unless ios_existing_category_source.include?("Image(systemName: \"checkmark.circle.fill\")") && ios_existing_category_source.include?(".accessibilityAddTraits(isSelected ? .isSelected : [])")
raise "Mac existing category selected indicator missing" unless mac_existing_category_source.include?("Image(systemName: \"checkmark\")") && mac_existing_category_source.include?(".accessibilityAddTraits(isSelected ? .isSelected : [])")
raise "iOS existing category VoiceOver label missing" unless ios_existing_category_source.include?("\\(option.name)分类，\\(option.taskCount > 0 ? \"\\(option.taskCount)项任务\" : \"仅历史专注记录\")\\(isSelected ? \"，已选中\" : \"\")")
raise "Mac existing category VoiceOver label missing" unless mac_existing_category_source.scan("\\(option.displayName)分类，\\(option.accessibilityUsageText)\\(isSelected ? \"，已选中\" : \"\")").length >= 2
for source, platform, name_expression in [[ios_existing_category_source, "iOS", "option.name"], [mac_existing_category_source, "Mac", "option.displayName"]]
  raise "#{platform} existing category VoiceOver hint missing" unless source.include?("选择已有\\(#{name_expression})分类") && source.include?(repeat_hint)
  raise "#{platform} existing category Voice Control labels missing" unless source.include?("Text(\\(#{name_expression}))") || (source.include?("Text(#{name_expression})") && source.include?("Text(\"选择\\(#{name_expression})分类\")"))
end
raise "Mac existing category snapshot branch missing" unless mac_existing_category_source.include?("if isSnapshotRendering") && mac_existing_category_source.include?("MacStaticExistingCategoryStrip(")
raise "Mac snapshot and live paths must share existing category options" unless mac_existing_category_source.scan("options: filteredExistingCategoryOptions").length >= 2
raise "Mac existing category snapshot must avoid native button placeholders" unless mac_existing_category_source.include?("private struct MacStaticExistingCategoryStrip") && !segment_slice(mac_existing_category_source, "private struct MacStaticExistingCategoryStrip", "private struct MacExistingCategoryChipContent", "Mac static existing category source missing").include?("Button")
mac_snapshot_source = File.read("scripts/render_mac_snapshots.swift")
raise "Mac schedule snapshot must seed a non-preset existing category" unless mac_snapshot_source.include?("AnyView(MacScheduleDetailView(") && mac_snapshot_source.include?("category: \"产品\"")
puts "Existing category reuse contracts verified."

raise "iOS existing category option task count missing" unless ios_existing_category_source.include?("let taskCount: Int")
raise "Mac existing category option task count missing" unless mac_existing_category_source.include?("let taskCount: Int")
raise "iOS existing category task counts must derive from store tasks by normalized key" unless ios_existing_category_source.include?("let taskCounts = store.tasks.reduce(into: [String: Int]())") && ios_existing_category_source.include?("counts[categoryComparisonKey(for: task.category), default: 0] += 1") && ios_existing_category_source.include?("taskCount: taskCounts[comparisonKey, default: 0]")
raise "Mac existing category task counts must derive from tasks by normalized key" unless mac_existing_category_source.include?("let taskCount = tasks.count {") && mac_existing_category_source.include?("macCategoryComparisonKey($0.category) == comparisonKey") && mac_existing_category_source.include?("taskCount: taskCount")
raise "iOS existing category usage must preserve source order" unless ios_existing_category_source.index("return store.taskCategories.compactMap") < ios_existing_category_source.index("taskCount: taskCounts[comparisonKey, default: 0]") && !ios_existing_category_source.match?(/sorted\s*\{[^}]*taskCount/m)
raise "Mac existing category usage must preserve source order" unless mac_existing_category_source.index("for category in categories") < mac_existing_category_source.index("taskCount: taskCount") && !mac_existing_category_source.match?(/sorted\s*\{[^}]*taskCount/m)
raise "iOS existing category usage text missing count and history states" unless ios_existing_category_source.include?("Text(option.taskCount > 0 ? \"\\(option.taskCount)\" : \"历史\")") && ios_existing_category_source.include?("\\(option.taskCount)项任务") && ios_existing_category_source.include?("仅历史专注记录")
raise "Mac existing category usage text missing count and history states" unless mac_existing_category_source.include?("taskCount > 0 ? \"\\(taskCount)\" : \"历史\"") && mac_existing_category_source.include?("taskCount > 0 ? \"\\(taskCount)项任务\" : \"仅历史专注记录\"") && mac_existing_category_source.include?("Text(option.usageText)")
raise "iOS existing category usage must remain readable beside selection state" unless ios_existing_category_source.include?(".layoutPriority(1)") && ios_existing_category_source.include?(".fixedSize()") && ios_existing_category_source.include?("Image(systemName: \"checkmark.circle.fill\")")
raise "Mac existing category usage must remain readable beside selection state" unless mac_existing_category_source.include?(".lineLimit(2)") && mac_existing_category_source.include?(".fixedSize(horizontal: false, vertical: true)") && mac_existing_category_source.include?("Text(option.usageText)") && mac_existing_category_source.include?(".fixedSize(horizontal: true, vertical: true)") && mac_existing_category_source.include?("Image(systemName: \"checkmark\")")
raise "iOS existing category usage accessibility missing" unless ios_existing_category_source.include?("\\(option.name)分类，\\(option.taskCount > 0 ? \"\\(option.taskCount)项任务\" : \"仅历史专注记录\")") && ios_existing_category_source.include?(".accessibilityAddTraits(isSelected ? .isSelected : [])")
raise "Mac live and static existing category usage accessibility missing" unless mac_existing_category_source.scan("\\(option.displayName)分类，\\(option.accessibilityUsageText)\\(isSelected ? \"，已选中\" : \"\")").length >= 2 && mac_existing_category_source.scan(".accessibilityAddTraits(isSelected ? .isSelected : [])").length >= 2
raise "Mac live and static existing category paths must share counted options" unless mac_existing_category_source.scan("options: filteredExistingCategoryOptions").length >= 2 && mac_existing_category_source.scan("MacExistingCategoryChipContent(").length >= 2
raise "Mac schedule snapshot must cover task-backed and session-only existing categories" unless mac_snapshot_source.include?("category: \"产品\"") && mac_snapshot_source.include?("category: sessionCategory") && mac_snapshot_source.include?("\"历史归档\"")
puts "Existing category usage context contracts verified."

raise "iOS existing category search state missing" unless ios_existing_category_source.include?("@State private var existingCategorySearch = \"\"")
raise "Mac existing category search state missing" unless mac_existing_category_source.include?("@State private var existingCategorySearchQuery: String") && mac_existing_category_source.include?("initialExistingCategorySearchQuery: String = \"\"")
raise "iOS existing category search threshold must be six" unless ios_existing_category_source.include?("private let existingCategorySearchThreshold = 6") && ios_existing_category_source.include?("existingCategoryOptions.count >= existingCategorySearchThreshold")
raise "Mac existing category search threshold must be six" unless File.read("ChronoFocusMac/Views/MacScheduleDetailView.swift").include?("private let macExistingCategorySearchThreshold = 6") && mac_existing_category_source.include?("existingCategoryOptions.count >= macExistingCategorySearchThreshold")

ios_existing_category_search_key_source = segment_slice(
  ios_existing_category_source,
  "private func existingCategorySearchKey",
  "private func firstTask",
  "iOS existing category search key source missing"
)
mac_existing_category_search_key_source = segment_slice(
  mac_existing_category_source,
  "private func macExistingCategorySearchKey",
  "private func macExistingCategoryOptions",
  "Mac existing category search key source missing"
)
for source, platform in [[ios_existing_category_search_key_source, "iOS"], [mac_existing_category_search_key_source, "Mac"]]
  raise "#{platform} existing category search must trim query whitespace" unless source.include?("trimmingCharacters(in: .whitespacesAndNewlines)")
  raise "#{platform} existing category search must use width-insensitive folding" unless source.include?(folding_options)
  raise "#{platform} existing category search must preserve an empty query" if source.include?("未分类")
end
raise "iOS existing category search must use POSIX locale" unless ios_existing_category_search_key_source.include?("locale: categoryComparisonLocale") && ios_existing_category_source.include?("categoryComparisonLocale = Locale(identifier: \"en_US_POSIX\")")
raise "Mac existing category search must use POSIX locale" unless mac_existing_category_search_key_source.include?("Locale(identifier: \"en_US_POSIX\")")

ios_filtered_existing_category_source = segment_slice(
  ios_existing_category_source,
  "private var filteredExistingCategoryOptions",
  "private var showsExistingCategorySearch",
  "iOS filtered existing category source missing"
)
mac_filtered_existing_category_source = segment_slice(
  mac_existing_category_source,
  "private var filteredExistingCategoryOptions",
  "private var snapshotExistingCategory",
  "Mac filtered existing category source missing"
)
raise "iOS existing category filtered options missing" unless ios_filtered_existing_category_source.include?("existingCategorySearchKey(for: existingCategorySearch)") && ios_filtered_existing_category_source.include?("existingCategoryOptions.filter") && ios_filtered_existing_category_source.include?("option.comparisonKey.contains(queryKey)")
raise "Mac existing category filtered options missing" unless mac_filtered_existing_category_source.include?("macExistingCategorySearchKey(existingCategorySearchQuery)") && mac_filtered_existing_category_source.include?("existingCategoryOptions.filter") && mac_filtered_existing_category_source.include?("$0.comparisonKey.contains(queryKey)")
for source, platform in [[ios_filtered_existing_category_source, "iOS"], [mac_filtered_existing_category_source, "Mac"]]
  raise "#{platform} empty existing category search must restore all options" unless source.include?("queryKey.isEmpty") && source.scan("return existingCategoryOptions").length >= 2
  raise "#{platform} existing category search must preserve source order" if source.match?(/sorted\s*[({]/)
  raise "#{platform} existing category search must match names only" if source.include?("taskCount") || source.include?("usageText") || source.include?("历史")
  raise "#{platform} existing category search must not modify form drafts or persistence" if source.match?(/(?:category|accentHex)\s*=/) || source.include?("store.")
end

raise "iOS existing category search field missing" unless ios_existing_category_source.include?("TextField(\"搜索已有分类\", text: $existingCategorySearch)")
raise "Mac existing category search field missing" unless mac_existing_category_source.include?("TextField(\"搜索已有分类\", text: $searchQuery)") && mac_existing_category_source.include?("searchQuery: $existingCategorySearchQuery")
raise "iOS existing category result count missing" unless ios_existing_category_source.include?("\\(filteredExistingCategoryOptions.count)/\\(existingCategoryOptions.count)") && ios_existing_category_source.include?("显示\\(filteredExistingCategoryOptions.count)个，共\\(existingCategoryOptions.count)个已有分类")
raise "Mac existing category result count missing" unless mac_existing_category_source.include?("Text(\"\\(resultCount)/\\(totalCount)\")") && mac_existing_category_source.include?("显示 \\(resultCount) 个，共 \\(totalCount) 个已有分类")
raise "iOS existing category search clear action missing" unless ios_existing_category_source.include?("Image(systemName: \"xmark.circle.fill\")") && ios_existing_category_source.include?("existingCategorySearch = \"\"") && ios_existing_category_source.include?(".accessibilityLabel(\"清除已有分类搜索\")") && ios_existing_category_source.include?("Text(\"清除已有分类搜索\")")
raise "Mac existing category search clear action missing" unless mac_existing_category_source.include?("Image(systemName: \"xmark.circle.fill\")") && mac_existing_category_source.include?("searchQuery = \"\"") && mac_existing_category_source.include?(".accessibilityLabel(\"清除已有分类搜索\")") && mac_existing_category_source.include?("Text(\"清除已有分类搜索\")")
raise "iOS existing category search clear target must be at least 44 points" unless ios_existing_category_source.match?(/xmark\.circle\.fill[\s\S]{0,400}\.frame\([^\n]*(?:width:\s*44[^\n]*height:\s*44|height:\s*44[^\n]*width:\s*44|minWidth:\s*44[^\n]*minHeight:\s*44|minHeight:\s*44[^\n]*minWidth:\s*44)/)
raise "iOS existing category search accessibility hint missing" unless ios_existing_category_source.include?("缩小已有分类列表")
raise "Mac existing category search accessibility hint missing" unless mac_existing_category_source.include?("缩小已有分类列表")
raise "iOS existing category search empty state missing" unless ios_existing_category_source.include?("没有匹配的已有分类") && ios_existing_category_source.include?("filteredExistingCategoryOptions.isEmpty") && ios_existing_category_source.include?("已有分类搜索结果为空")
raise "Mac existing category search empty state missing" unless mac_existing_category_source.include?("没有匹配的已有分类") && mac_existing_category_source.scan("existingCategoryNoResultsView").length >= 3 && mac_existing_category_source.include?("已有分类搜索结果为空")
raise "iOS existing category results must drive displayed chips" unless ios_existing_category_source.include?("ForEach(filteredExistingCategoryOptions)")
raise "Mac live and static search results must drive displayed chips" unless mac_existing_category_source.scan("options: filteredExistingCategoryOptions").length >= 2 && mac_existing_category_source.scan("ForEach(options)").length >= 2
mac_static_existing_category_search_source = segment_slice(
  mac_existing_category_source,
  "private struct MacStaticExistingCategoryStrip",
  "private func existingCategoryHeader",
  "Mac static existing category search source missing"
)
raise "Mac static existing category results must avoid snapshot ScrollView loss" if mac_static_existing_category_search_source.include?("ScrollView")
raise "Mac static existing category results must use a direct HStack" unless mac_static_existing_category_search_source.include?("HStack(spacing: 8)") && mac_static_existing_category_search_source.include?("ForEach(options)")
raise "iOS selecting an existing category must retain the search query" if ios_select_source.include?("existingCategorySearch")
raise "Mac selecting an existing category must retain the search query" if mac_select_source.include?("existingCategorySearchQuery") || mac_select_source.include?("searchQuery")

mac_selected_category_change_source = segment_slice(
  mac_existing_category_source,
  ".onChange(of: selectedCategory)",
  ".task(id: quickAddRequest?.id)",
  "Mac selected category change source missing"
)
mac_quick_add_prefill_source = segment_slice(
  mac_existing_category_source,
  "private func prepareQuickAdd(_ category: String)",
  "private func selectExistingCategory",
  "Mac quick add prefill source missing"
)
mac_quick_add_request_source = segment_slice(
  mac_existing_category_source,
  ".task(id: quickAddRequest?.id)",
  "private func addTask()",
  "Mac cross-page quick add request source missing"
)
raise "Mac category summary prefill must clear existing category search" unless mac_selected_category_change_source.include?("existingCategorySearchQuery = \"\"")
raise "Mac cross-page quick add request must clear existing category search" unless mac_quick_add_request_source.include?("existingCategorySearchQuery = \"\"") && mac_quick_add_request_source.include?("prepareQuickAdd(quickAddRequest.category)")
raise "Mac quick add prefill must clear existing category search" unless mac_quick_add_prefill_source.include?("existingCategorySearchQuery = \"\"")

mac_static_existing_category_search_source = segment_slice(
  mac_existing_category_source,
  "private struct MacStaticExistingCategorySearchField",
  "private struct MacExistingCategoryChipContent",
  "Mac static existing category search source missing"
)
raise "Mac static existing category search must avoid native control placeholders" if mac_static_existing_category_search_source.include?("Button") || mac_static_existing_category_search_source.include?("TextField")
raise "Mac static existing category search must expose the current query" unless mac_static_existing_category_search_source.include?("let query: String") && mac_static_existing_category_search_source.include?("搜索已有分类，当前查询")

snapshot_seed_source = segment_slice(
  mac_snapshot_source,
  "private static func seedSnapshotData",
  "private static func render",
  "Mac snapshot seed source missing"
)
preset_titles = preset_source.scan(/TaskCategoryPreset\(title:\s*\"([^\"]+)\"/).flatten
snapshot_session_category_source = segment_slice(
  snapshot_seed_source,
  "let sessionCategories = [",
  "for (offset, sessionCategory)",
  "Mac snapshot session category source missing"
)
snapshot_literal_categories = (
  snapshot_seed_source.scan(/category:\s*\"([^\"]+)\"/).flatten +
  snapshot_session_category_source.scan(/\"([^\"]+)\"/).flatten
).uniq - preset_titles
raise "Mac schedule snapshot must seed at least six non-preset existing categories" unless snapshot_literal_categories.length >= 6
raise "Mac schedule snapshot must use a nonempty existing category search query" unless mac_snapshot_source.match?(/MacScheduleDetailView\([\s\S]{0,500}?(?:initialExistingCategorySearchQuery|existingCategorySearchQuery):\s*\"[^\"]+\"/)
puts "Existing category search contracts verified."

dashboard_source = File.read("ChronoFocus/Views/DashboardView.swift")
ios_schedule_handoff_source = File.read("ChronoFocus/Views/ScheduleView.swift")
ios_timer_handoff_source = File.read("ChronoFocus/Views/TimerView.swift")
mac_detail_handoff_source = File.read("ChronoFocusMac/Views/MacDetailView.swift")
mac_schedule_handoff_source = File.read("ChronoFocusMac/Views/MacScheduleDetailView.swift")
mac_timer_handoff_source = File.read("ChronoFocusMac/Views/MacTimerDetailView.swift")

ios_request_source = source_slice(
  "ChronoFocus/Views/DashboardView.swift",
  "struct TimerHandoffRequest",
  "struct DashboardView",
  "iOS timer handoff request source missing"
)
raise "iOS timer handoff request must carry a generated UUID" unless ios_request_source.match?(/let\s+id(?:\s*:\s*UUID)?\s*=\s*UUID\(\)/) || ios_request_source.match?(/init\s*\(\s*id:\s*UUID\s*=\s*UUID\(\)/)
raise "iOS timer handoff request category missing" unless ios_request_source.match?(/let\s+category\s*:\s*String/)
raise "iOS timer handoff preferred task id missing" unless ios_request_source.match?(/let\s+preferredTaskID\s*:\s*UUID\?/)
raise "iOS timer handoff request must remain transient" if ios_request_source.include?("UserDefaults") || ios_request_source.include?("FocusStore")
raise "iOS schedule handoff callback wiring missing" unless dashboard_source.include?("onTimerHandoff:") && ios_schedule_handoff_source.include?("TimerHandoffRequest(")
raise "iOS timer handoff request state missing" unless dashboard_source.match?(/@State\s+private\s+var\s+\w*[Tt]imer[Hh]andoff\w*\s*:\s*TimerHandoffRequest\?/)
ios_navigation_source = function_slices_matching(dashboard_source, "handoff").find { |slice| slice.include?("selectedTab = .timer") }
raise "iOS timer handoff navigation missing" unless ios_navigation_source && ios_navigation_source.include?("timerHandoffRequest = request")
raise "iOS timer handoff request injection missing" unless dashboard_source.match?(/TimerView\([\s\S]{0,500}?(?:timerHandoffRequest|handoffRequest):/)
raise "iOS timer handoff identity task missing" unless ios_timer_handoff_source.match?(/\.task\s*\(\s*id:\s*\w*[Tt]imer[Hh]andoff\w*\?\.id\s*\)/)

ios_consumer_source = function_slices_matching(ios_timer_handoff_source, "handoff").find do |slice|
  slice.include?("engine.selectTask(")
end
raise "iOS timer handoff consumer source missing" unless ios_consumer_source
raise "iOS timer handoff must re-query FocusStore launchable tasks" unless ios_consumer_source.include?("store.startableTasks()") && ios_consumer_source.include?("store.startableTask(for:")
raise "iOS timer handoff must restore category context" unless ios_consumer_source.include?("selectedTaskCategory") && ios_consumer_source.include?("request.category")
raise "iOS timer handoff preferred task validation missing" unless ios_consumer_source.include?("preferredTaskID") && (ios_consumer_source.match?(/\.id\s*==\s*preferredTaskID|preferredTaskID\s*==\s*\w+\.id/) || ios_consumer_source.include?("store.startableTask(for: preferredTaskID)"))
raise "iOS invalid preferred timer handoff must clear stale selection" unless ios_consumer_source.match?(/request\.preferredTaskID\s*!=\s*nil[\s\S]{0,180}?engine\.selectTask\(nil\)/)
raise "iOS timer handoff running-state protection missing" unless ios_consumer_source.include?("engine.isRunning")
raise "iOS timer handoff must select through TimerEngine" unless ios_consumer_source.include?("engine.selectTask(")
raise "iOS timer handoff identity consumption missing" unless ios_consumer_source.match?(/onConsume\w*[Hh]andoff\w*\s*\(\s*request\.id\s*\)/)
raise "iOS timer handoff must not auto-start" if ios_consumer_source.include?("engine.start(")
raise "iOS timer handoff must not write selectedTaskID directly" if ios_consumer_source.match?(/engine\.selectedTaskID\s*=(?!=)/)

raise "iOS category summary timer handoff action missing" unless ios_schedule_handoff_source.include?("转到计时") && ios_schedule_handoff_source.match?(/onTimerHandoff[\s\S]{0,500}?TimerHandoffRequest\(\s*category:\s*selectedCategoryName\s*\)/)
raise "iOS task row timer handoff action missing" unless ios_schedule_handoff_source.match?(/onTimerHandoff[\s\S]{0,700}?preferredTaskID:\s*task\.id/)
raise "iOS timer handoff action eligibility guard missing" unless ios_schedule_handoff_source.include?("task.isDone") && ios_schedule_handoff_source.include?("task.isEnabled")
raise "iOS timer handoff minimum tap target missing" unless ios_schedule_handoff_source.match?(/转到计时[\s\S]{0,700}?\.frame\([^\n]*minHeight:\s*44/)
raise "iOS category timer handoff accessibility label missing" unless ios_schedule_handoff_source.include?("在计时页查看\\(category)分类")
raise "iOS task timer handoff accessibility label missing" unless ios_schedule_handoff_source.include?("将\\(task.title)设为当前计时待办")
raise "iOS running task timer handoff accessibility label missing" unless ios_schedule_handoff_source.include?("在计时页查看\\(task.category)分类，计时运行中不切换到\\(task.title)") && ios_schedule_handoff_source.include?(".accessibilityLabel(timerHandoffAccessibilityLabel)")
raise "iOS running task timer handoff Voice Control labels missing" unless ios_schedule_handoff_source.match?(/timerHandoffInputLabels[\s\S]{0,500}?if\s+isTimerRunning[\s\S]{0,300}?Text\("查看\\\(task\.category\)分类"\)/)
raise "iOS timer handoff Voice Control labels missing" unless ios_schedule_handoff_source.include?("Text(\"转到计时\")") && ios_schedule_handoff_source.include?(".accessibilityInputLabels(")
raise "iOS running-state accessibility guidance missing" unless ios_schedule_handoff_source.include?("计时运行中不可切换当前待办")

mac_request_source = source_slice(
  "ChronoFocusMac/Views/MacDetailView.swift",
  "struct MacTimerHandoffRequest",
  "struct MacDetailView",
  "Mac timer handoff request source missing"
)
raise "Mac timer handoff request must carry a generated UUID" unless mac_request_source.match?(/let\s+id\s*=\s*UUID\(\)/)
raise "Mac timer handoff request category missing" unless mac_request_source.match?(/let\s+category\s*:\s*String/)
raise "Mac timer handoff preferred task id missing" unless mac_request_source.match?(/let\s+preferredTaskID\s*:\s*UUID\?/)
raise "Mac timer handoff request must remain transient" if mac_request_source.include?("UserDefaults") || mac_request_source.include?("FocusStore")
mac_selection_source = source_slice(
  "ChronoFocusMac/Views/MacDetailView.swift",
  "final class MacDetailSelection",
  "struct MacTimerHandoffRequest",
  "Mac timer handoff selection source missing"
)
raise "Mac timer handoff request state missing" unless mac_selection_source.match?(/@Published\s+private\(set\)\s+var\s+\w*[Tt]imer[Hh]andoff\w*\s*:\s*MacTimerHandoffRequest\?/)
raise "Mac timer handoff request creation missing" unless mac_selection_source.include?("MacTimerHandoffRequest(")
raise "Mac timer handoff navigation missing" unless mac_selection_source.match?(/MacTimerHandoffRequest\([\s\S]{0,500}?selectedSection\s*=\s*\.timer/)
raise "Mac timer handoff identity consumption missing" unless mac_selection_source.match?(/consume\w*[Hh]andoff\w*\s*\(\s*id:\s*UUID\s*\)[\s\S]{0,300}?\?\.id\s*==\s*id[\s\S]{0,300}?=\s*nil/)
raise "Mac schedule timer handoff callback wiring missing" unless mac_detail_handoff_source.include?("requestTimerHandoff") && mac_detail_handoff_source.match?(/MacScheduleDetailView\([\s\S]{0,700}?onTimerHandoff:/)
raise "Mac timer handoff request injection missing" unless mac_detail_handoff_source.match?(/MacTimerDetailView\([\s\S]{0,700}?(?:timerHandoffRequest|handoffRequest):[\s\S]{0,700}?onConsume\w*[Hh]andoff/)
raise "Mac timer handoff identity task missing" unless mac_timer_handoff_source.match?(/\.task\s*\(\s*id:\s*\w*[Tt]imer[Hh]andoff\w*\?\.id\s*\)/)

mac_consumer_source = function_slices_matching(mac_timer_handoff_source, "handoff").find do |slice|
  slice.include?("engine.selectTask(")
end
raise "Mac timer handoff consumer source missing" unless mac_consumer_source
mac_resolver_source = function_slices_matching(mac_timer_handoff_source, "resolveMacTimerHandoffTask").first
raise "Mac timer handoff task resolver source missing" unless mac_resolver_source
raise "Mac timer handoff must re-query FocusStore launchable tasks" unless mac_consumer_source.include?("store.startableTasks()") && mac_consumer_source.include?("store.startableTask(for:")
raise "Mac timer handoff must restore category context" unless mac_consumer_source.include?("selectedCategory") && mac_consumer_source.include?("request.category")
raise "Mac timer handoff preferred task validation missing" unless mac_consumer_source.include?("resolveMacTimerHandoffTask(") && mac_resolver_source.include?("preferredTaskID") && mac_resolver_source.match?(/\.id\s*==\s*preferredTaskID|preferredTaskID\s*==\s*\w+\.id/) && mac_resolver_source.match?(/\.category\s*==\s*request\.category/)
raise "Mac invalid preferred timer handoff must clear stale selection" unless mac_consumer_source.match?(/request\.preferredTaskID\s*!=\s*nil[\s\S]{0,180}?engine\.selectTask\(nil\)/)
raise "Mac timer handoff running-state protection missing" unless mac_consumer_source.include?("engine.isRunning")
raise "Mac timer handoff must select through TimerEngine" unless mac_consumer_source.include?("engine.selectTask(")
raise "Mac timer handoff identity consumption missing in timer queue" unless mac_consumer_source.match?(/onConsume\w*[Hh]andoff\w*\s*\(\s*request\.id\s*\)/)
raise "Mac timer handoff must not auto-start" if mac_consumer_source.include?("engine.start(")
raise "Mac timer handoff must not write selectedTaskID directly" if mac_consumer_source.match?(/engine\.selectedTaskID\s*=(?!=)/)

raise "Mac category summary timer handoff action missing" unless mac_schedule_handoff_source.include?("转到计时") && mac_schedule_handoff_source.match?(/onTimerHandoff\(\s*selectedCategoryName\s*,\s*nil\s*\)/)
raise "Mac task row timer handoff action missing" unless mac_schedule_handoff_source.match?(/onTimerHandoff\(\s*task\.category\s*,\s*task\.id\s*\)/)
raise "Mac timer handoff action eligibility guard missing" unless mac_schedule_handoff_source.include?("task.isDone") && mac_schedule_handoff_source.include?("task.isEnabled")
raise "Mac category timer handoff accessibility label missing" unless mac_schedule_handoff_source.include?("在计时页查看\\(category)分类")
raise "Mac category timer handoff running-state guidance missing" unless mac_schedule_handoff_source.include?("let isTimerRunning: Bool") && mac_schedule_handoff_source.include?("计时运行中不可切换当前待办") && mac_schedule_handoff_source.include?("不会替换当前待办")
raise "Mac task timer handoff accessibility label missing" unless mac_schedule_handoff_source.include?("将\\(task.title)设为当前计时待办")
raise "Mac running task timer handoff accessibility label missing" unless mac_schedule_handoff_source.include?("在计时页查看\\(task.category)分类，计时运行中不切换到\\(task.title)") && mac_schedule_handoff_source.include?(".accessibilityLabel(timerHandoffLabel(for: task))")
raise "Mac running task timer handoff Voice Control labels missing" unless mac_schedule_handoff_source.match?(/timerHandoffInputLabels\(for\s+task:[\s\S]{0,500}?if\s+engine\.isRunning[\s\S]{0,300}?Text\("查看\\\(task\.category\)分类"\)/) && mac_schedule_handoff_source.include?(".accessibilityInputLabels(timerHandoffInputLabels(for: task))")
raise "Mac timer handoff Voice Control labels missing" unless mac_schedule_handoff_source.include?("Text(\"转到计时\")") && mac_schedule_handoff_source.include?(".accessibilityInputLabels(")
raise "Mac running-state accessibility guidance missing" unless mac_schedule_handoff_source.include?("计时运行中不可切换当前待办")
raise "Mac timer handoff snapshot request wiring missing" unless mac_snapshot_source.match?(/let\s+timerHandoffRequest\s*=\s*MacTimerHandoffRequest\([\s\S]{0,300}?preferredTaskID:\s*timerHandoffTask\.id/) && mac_snapshot_source.match?(/MacTimerDetailView\([\s\S]{0,500}?timerHandoffRequest:\s*timerHandoffRequest/)
puts "Schedule to timer handoff contracts verified."

focus_store_startable_source = File.read("ChronoFocus/Services/FocusStore.swift")
timer_engine_startable_source = File.read("ChronoFocus/Services/TimerEngine.swift")
timer_view_startable_source = File.read("ChronoFocus/Views/TimerView.swift")
mac_timer_startable_source = File.read("ChronoFocusMac/Views/MacTimerDetailView.swift")
mac_mini_startable_source = File.read("ChronoFocusMac/Views/MacMiniTimerView.swift")
mac_snapshot_startable_source = File.read("scripts/render_mac_snapshots.swift")
mac_core_startable_source = File.read("scripts/test_mac_core.swift")
raise "FocusStore upcomingTasks API missing" unless focus_store_startable_source.include?("func upcomingTasks()")
raise "FocusStore startableTasks API missing" unless focus_store_startable_source.include?("func startableTasks()")
raise "FocusStore startableTask lookup API missing" unless focus_store_startable_source.include?("func startableTask(for id: UUID?)")
raise "TimerEngine startable boundary missing" unless timer_engine_startable_source.include?("store.startableTask(for: selectedTaskID)") && timer_engine_startable_source.include?("func reconcileIdleSelectedTask()")
raise "TimerEngine task-change reconciliation missing" unless timer_engine_startable_source.include?("observeTaskChanges()") && timer_engine_startable_source.include?("guard !isRunning, !isPaused")
raise "iOS timer queue must use startable tasks" unless timer_view_startable_source.include?("store.startableTasks()") && timer_view_startable_source.include?("store.startableTask(for:")
raise "Mac timer queue must use startable tasks" unless mac_timer_startable_source.include?("store.startableTasks()") && mac_timer_startable_source.include?("store.startableTask(for:")
raise "Mac mini timer queue must use startable tasks" unless mac_mini_startable_source.include?("store.startableTasks()")
raise "Mac snapshot handoff fixture must use startable tasks" unless mac_snapshot_startable_source.include?("store.startableTasks()")
raise "Mac core startable boundary tests missing" unless mac_core_startable_source.include?("runStartableTaskTests") && mac_core_startable_source.include?("runTimerEngineBoundaryTests")
puts "Startable task consistency contracts verified."

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
  raise "analytics category share accessibility label missing" unless source.include?("private func categoryShareAccessibilityLabel(for item: CategoryFocus, rank: Int) -> String") && source.include?("占分类投入 \\(categorySharePercent(for: item.seconds))%") && source.include?(".accessibilityLabel(categoryShareAccessibilityLabel(for: item, rank: rank))")
  raise "analytics category share Voice Control labels missing" unless source.include?(".accessibilityElement(children: .ignore)") && source.include?("Text(\"\\(item.category)分类投入\")") && source.include?(".accessibilityInputLabels([")
end
puts "Analytics category share accessibility contracts verified."

raise "CategoryFocus session count field missing" unless File.read("ChronoFocus/Models/AppModels.swift").include?("var sessionCount: Int")
raise "category breakdown session count aggregation missing" unless File.read("ChronoFocus/Services/FocusStore.swift").include?("sessionCount: sessions.count")
raise "Mac core category session count test missing" unless File.read("scripts/test_mac_core.swift").include?("sessionCount == 1")
[
  File.read("ChronoFocus/Views/AnalyticsView.swift"),
  File.read("ChronoFocusMac/Views/MacAnalyticsDetailView.swift")
].each do |source|
  raise "analytics category share session count helper missing" unless source.include?("private func categoryShareSessionCountText(for item: CategoryFocus) -> String") && source.include?("\\(item.sessionCount) 次专注")
  raise "analytics category share visible session count missing" unless source.include?("Text(categoryShareSessionCountText(for: item))")
  raise "analytics category share accessibility session count missing" unless source.include?("\\(item.sessionCount)次专注，占分类投入")
  raise "analytics category share Voice Control session count missing" unless source.include?("Text(\"\\(item.category)分类\\(item.sessionCount)次专注\")")
end
puts "Analytics category share session count contracts verified."
[
  File.read("ChronoFocus/Views/AnalyticsView.swift"),
  File.read("ChronoFocusMac/Views/MacAnalyticsDetailView.swift")
].each do |source|
  raise "analytics category share ranking enumeration missing" unless source.include?("ForEach(Array(store.categoryBreakdown().enumerated()), id: \\.element.id)") && source.include?("let rank = index + 1")
  raise "analytics category share rank helper missing" unless source.include?("private func categoryShareRankText(for rank: Int) -> String") && source.include?("\"第 \\(rank) 位\"")
  raise "analytics category share visible rank missing" unless source.include?("Text(categoryShareRankText(for: rank))")
  raise "analytics category share ranking accessibility missing" unless source.include?("private func categoryShareAccessibilityLabel(for item: CategoryFocus, rank: Int) -> String") && source.include?("第\\(rank)位") && source.include?(".accessibilityLabel(categoryShareAccessibilityLabel(for: item, rank: rank))")
  raise "analytics category share ranking Voice Control missing" unless source.include?("Text(\"第\\(rank)位分类\")") && source.include?("Text(\"\\(item.category)第\\(rank)位\")")
end
puts "Analytics category share ranking contracts verified."
[
  File.read("ChronoFocus/Views/AnalyticsView.swift"),
  File.read("ChronoFocusMac/Views/MacAnalyticsDetailView.swift")
].each do |source|
  raise "analytics category share sort helper missing" unless source.include?("private func categoryShareSortDescriptionText() -> String") && source.include?("按投入时长排序")
  raise "analytics category share visible sort context missing" unless source.include?("Text(categoryShareSortDescriptionText())")
  raise "analytics category share sort accessibility missing" unless source.include?("按投入时长排序第\\(rank)位")
  raise "analytics category share sort Voice Control missing" unless source.include?("Text(\"按投入时长排序\")") && source.include?("Text(\"\\(item.category)按投入时长排序\")")
end
puts "Analytics category share sort context contracts verified."
[
  File.read("ChronoFocus/Views/AnalyticsView.swift"),
  File.read("ChronoFocusMac/Views/MacAnalyticsDetailView.swift")
].each do |source|
  raise "analytics category share empty branch missing" unless source.include?("if store.categoryBreakdown().isEmpty")
  raise "analytics category share empty ContentUnavailableView missing" unless source.include?("ContentUnavailableView(") && source.include?("categoryShareEmptyTitle()") && source.include?("description: Text(categoryShareEmptyDescriptionText())")
  raise "analytics category share empty helper missing" unless source.include?("private func categoryShareEmptyTitle() -> String") && source.include?("private func categoryShareEmptyDescriptionText() -> String") && source.include?("private func categoryShareEmptyAccessibilityLabel() -> String")
  raise "analytics category share empty copy missing" unless source.include?("暂无分类统计") && source.include?("完成带分类的番茄钟后，会按投入时长生成分类统计。")
  raise "analytics category share empty accessibility missing" unless source.include?(".accessibilityElement(children: .ignore)") && source.include?(".accessibilityLabel(categoryShareEmptyAccessibilityLabel())")
  raise "analytics category share empty Voice Control missing" unless source.include?("Text(\"分类统计\")") && source.include?("Text(\"暂无分类统计\")") && source.include?("Text(\"分类投入空态\")")
end
puts "Analytics category share empty state contracts verified."
[
  File.read("ChronoFocus/Views/AnalyticsView.swift"),
  File.read("ChronoFocusMac/Views/MacAnalyticsDetailView.swift")
].each do |source|
  raise "analytics category share metadata font helper missing" unless source.include?("private func categoryShareMetadataFont() -> Font") && source.include?(".caption")
  raise "analytics category share metadata font not applied" unless source.include?(".font(categoryShareMetadataFont())")
  raise "analytics category share metadata caption2 still used" if source.include?(".font(.caption2.weight(.medium))")
end
puts "Analytics category share metadata readability contracts verified."
[
  File.read("ChronoFocus/Views/AnalyticsView.swift"),
  File.read("ChronoFocusMac/Views/MacAnalyticsDetailView.swift")
].each do |source|
  raise "analytics category share percent font helper missing" unless source.match?(/private func categorySharePercentFont\(\) -> Font\s*\{\s*\.subheadline\.bold\(\)\s*\}/)
  raise "analytics category share percent font not applied" unless source.include?("Text(\"\\(categorySharePercent(for: item.seconds))%\")") && source.include?(".font(categorySharePercentFont())")
  raise "analytics category share percent iOS caption font still used" if source.include?("Text(\"\\(categorySharePercent(for: item.seconds))%\")\n                                    .font(.caption.weight(.bold))")
  raise "analytics category share percent Mac caption font still used" if source.include?("Text(\"\\(categorySharePercent(for: item.seconds))%\")\n                                    .font(.caption.bold())")
end
puts "Analytics category share percent readability contracts verified."

ios_analytics_source = File.read("ChronoFocus/Views/AnalyticsView.swift")
raise "iOS analytics recent session category badge missing" unless ios_analytics_source.include?("RecentSessionCategoryBadge(category: session.category)") && ios_analytics_source.include?("private struct RecentSessionCategoryBadge")
raise "iOS analytics recent session category preset missing" unless ios_analytics_source.include?("TaskCategoryPreset.matching(category)") && ios_analytics_source.include?("categoryPreset?.symbolName ?? \"tag.fill\"") && ios_analytics_source.include?("Color(hex: categoryPreset?.accentHex ?? \"#7C8CF8\")")
raise "iOS analytics recent session accessibility label missing" unless ios_analytics_source.include?("private func recentSessionAccessibilityLabel(for session: FocusSession) -> String") && ios_analytics_source.include?("return \"\\(session.taskTitle)，\\(session.category)分类，\\(session.mode.title)，\\(session.startedAt.scheduleTimeText)，\\(session.actualSeconds.hourMinuteText)，\\(completionText)\"") && ios_analytics_source.include?(".accessibilityLabel(recentSessionAccessibilityLabel(for: session))")
raise "iOS analytics recent session Voice Control labels missing" unless ios_analytics_source.include?(".accessibilityInputLabels([") && ios_analytics_source.include?("Text(session.category)") && ios_analytics_source.include?("Text(\"\\(session.category)分类\")") && ios_analytics_source.include?("Text(\"\\(session.category)分类记录\")")
raise "iOS analytics recent session category badge accessibility missing" unless ios_analytics_source.include?(".accessibilityLabel(\"\\(category)分类\")") && ios_analytics_source.include?(".accessibilityInputLabels([Text(category), Text(\"\\(category)分类\")])")

raise "iOS analytics plan review category badge missing" unless ios_analytics_source.include?("AnalyticsPlanReviewCategoryBadge(item: item)") && ios_analytics_source.include?("private struct AnalyticsPlanReviewCategoryBadge")
raise "iOS analytics plan review category preset missing" unless ios_analytics_source.include?("TaskCategoryPreset.matching(item.category)") && ios_analytics_source.include?("categoryPreset?.symbolName ?? \"tag.fill\"") && ios_analytics_source.include?("Color(hex: categoryPreset?.accentHex ?? item.accentHex)")
raise "iOS analytics plan review category badge visible label missing" unless ios_analytics_source.include?("Label(item.category, systemImage: categorySymbolName)")
raise "iOS analytics plan review accessibility label missing" unless ios_analytics_source.include?("private func planReviewAccessibilityLabel(for item: PomodoroPlanItem) -> String") && ios_analytics_source.include?("\\(item.taskTitle)，\\(item.category)分类，计划开始 \\(item.scheduledStart.scheduleTimeText)，第 \\(item.roundNumber) 轮") && ios_analytics_source.include?(".accessibilityLabel(planReviewAccessibilityLabel(for: item))")
raise "iOS analytics plan review Voice Control labels missing" unless ios_analytics_source.include?("Text(item.taskTitle)") && ios_analytics_source.include?("Text(item.category)") && ios_analytics_source.include?("Text(\"\\(item.category)分类\")") && ios_analytics_source.include?("Text(\"\\(item.category)分类计划\")")
raise "iOS analytics plan review category badge accessibility missing" unless ios_analytics_source.include?(".accessibilityLabel(\"\\(item.category)分类\")") && ios_analytics_source.include?(".accessibilityInputLabels([Text(item.category), Text(\"\\(item.category)分类\")])")
puts "Analytics plan review category accessibility contracts verified."

mac_analytics_source = File.read("ChronoFocusMac/Views/MacAnalyticsDetailView.swift")
raise "Mac analytics recent session category badge missing" unless mac_analytics_source.include?("MacRecentSessionCategoryBadgeView(category: session.category)") && mac_analytics_source.include?("private struct MacRecentSessionCategoryBadgeView")
raise "Mac analytics recent session category preset missing" unless mac_analytics_source.include?("TaskCategoryPreset.matching(category)") && mac_analytics_source.include?("categoryPreset?.symbolName ?? \"tag.fill\"") && mac_analytics_source.include?("Color(hex: categoryPreset?.accentHex ?? \"#7C8CF8\")")
raise "Mac analytics recent session accessibility label missing" unless mac_analytics_source.include?("private func recentSessionAccessibilityLabel(for session: FocusSession) -> String") && mac_analytics_source.include?("return \"\\(session.taskTitle)，\\(session.category)分类，\\(session.mode.title)，\\(session.startedAt.scheduleTimeText)，\\(session.actualSeconds.hourMinuteText)，\\(completionText)\"") && mac_analytics_source.include?(".accessibilityLabel(recentSessionAccessibilityLabel(for: session))")
raise "Mac analytics recent session Voice Control labels missing" unless mac_analytics_source.include?(".accessibilityInputLabels([") && mac_analytics_source.include?("Text(session.category)") && mac_analytics_source.include?("Text(\"\\(session.category)分类\")") && mac_analytics_source.include?("Text(\"\\(session.category)分类记录\")")
raise "Mac analytics recent session category badge accessibility missing" unless mac_analytics_source.include?(".accessibilityLabel(\"\\(category)分类\")") && mac_analytics_source.include?(".accessibilityInputLabels([Text(category), Text(\"\\(category)分类\")])")
puts "Analytics recent session category contracts verified."

assert_slice_contains(
  "ChronoFocusMac/Views/MacScheduleDetailView.swift",
  "private var taskListPanel: some View",
  "private func addTask()",
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
  "struct MacCategoryFilterBar",
  "private struct MacCategoryFilterChip",
  /toggleCategory\(option\.category\)[\s\S]*?private func toggleCategory\(_ category: String\)[\s\S]*?selectedCategory == category \? nil : category/,
  "Mac category filter chip must toggle off the selected category"
)
puts "Category filter toggle contracts verified."

assert_chip_accessibility("ChronoFocus/Views/ScheduleView.swift", "TaskCategoryFilterChip", "struct ScheduleTaskCell")
assert_chip_accessibility("ChronoFocus/Views/TimerView.swift", "TimerTaskCategoryFilterChip", "struct TimerSelectedTaskCategorySummaryView")
assert_chip_accessibility("ChronoFocusMac/Views/MacScheduleDetailView.swift", "MacCategoryFilterChip", "func syncMacTaskReminder")
assert_preset_picker_accessibility("ChronoFocus/Views/ScheduleView.swift", "TaskCategoryPresetPicker", "func syncTaskReminder")
assert_preset_picker_accessibility("ChronoFocusMac/Views/MacScheduleDetailView.swift", "MacCategoryPresetPicker", "struct MacCategoryFilterBar")
assert_calendar_day_accessibility("ChronoFocus/Views/ScheduleView.swift", "CalendarDayButton", "struct TaskCategoryFilterBar")
assert_calendar_day_accessibility("ChronoFocusMac/Views/MacScheduleDetailView.swift", "MacCalendarDayCell", "struct MacCalendarSyncPanelView")
puts "Category chip accessibility contracts verified."

verifier_path = "scripts/verify_project.sh"
chip_helper_source = source_slice(verifier_path, "def assert_chip_accessibility", "def assert_preset_picker_accessibility", "Chip accessibility helper source missing")
preset_helper_source = source_slice(verifier_path, "def assert_preset_picker_accessibility", "def assert_calendar_day_accessibility", "Preset picker accessibility helper source missing")
calendar_helper_source = source_slice(verifier_path, "def assert_calendar_day_accessibility", "assert_slice_contains(", "Calendar day accessibility helper source missing")
accessibility_calls_source = source_slice(verifier_path, "assert_chip_accessibility(\"ChronoFocus/Views/ScheduleView.swift\"", "puts \"Category chip accessibility contracts verified.\"", "Accessibility helper calls source missing")
raise "Chip accessibility helper declaration marker depends on private access" unless chip_helper_source.include?('"struct #{chip_name}"') && !chip_helper_source.include?('"private struct #{chip_name}"')
raise "Preset picker accessibility helper declaration marker depends on private access" unless preset_helper_source.include?('"struct #{picker_name}"') && !preset_helper_source.include?('"private struct #{picker_name}"')
raise "Calendar day accessibility helper declaration marker depends on private access" unless calendar_helper_source.include?('"struct #{day_name}"') && !calendar_helper_source.include?('"private struct #{day_name}"')
raise "Accessibility helper call boundaries depend on private access" if accessibility_calls_source.include?('"private struct ') || accessibility_calls_source.include?('"@MainActor\\nprivate func ')
[
  '"struct ScheduleTaskCell"',
  '"struct TimerSelectedTaskCategorySummaryView"',
  '"func syncMacTaskReminder"',
  '"func syncTaskReminder"',
  '"struct MacCategoryFilterBar"',
  '"struct TaskCategoryFilterBar"',
  '"struct MacCalendarSyncPanelView"'
].each do |marker|
  raise "Accessibility helper call boundary missing #{marker}" unless accessibility_calls_source.include?(marker)
end
puts "Declaration boundary resilience contracts verified."

mac_detail_source = File.read("ChronoFocusMac/Views/MacDetailView.swift")
mac_timer_source = File.read("ChronoFocusMac/Views/MacTimerDetailView.swift")
mac_schedule_source = File.read("ChronoFocusMac/Views/MacScheduleDetailView.swift")
mac_selection_source = segment_slice(mac_detail_source, "class MacDetailSelection", "struct MacDetailView", "MacDetailSelection source missing")
mac_detail_content_source = segment_slice(mac_detail_source, "struct MacDetailContentView", "enum MacDetailSection", "MacDetailContentView source missing")
mac_timer_view_source = segment_slice(mac_timer_source, "struct MacTimerDetailView", "struct MacModePickerView", "MacTimerDetailView source missing")
mac_task_queue_source = segment_slice(mac_timer_source, "struct MacTaskQueueView", "struct MacMetricView", "MacTaskQueueView source missing")
mac_timer_category_context_source = segment_slice(mac_timer_source, "struct MacTimerCategoryContextView", "struct MacTimerCategoryEmptyStateView", "MacTimerCategoryContextView source missing")
mac_task_row_source = segment_slice(mac_timer_source, "struct MacTaskRowView", "struct MacPageHeaderView", "MacTaskRowView source missing")
mac_schedule_view_source = segment_slice(mac_schedule_source, "struct MacScheduleDetailView", "struct MacQuickAddCategoryContextView", "MacScheduleDetailView source missing")
raise "Mac detail quick-add request state missing" unless mac_selection_source.include?("quickAddRequest")
raise "Mac detail requestQuickAdd action missing" unless mac_selection_source.match?(/func\s+requestQuickAdd\s*\([^)]*category:/)
raise "Mac detail quick-add request must switch to schedule" unless mac_selection_source.include?("selectedSection = .schedule")
raise "Mac detail consumeQuickAddRequest action missing" unless mac_selection_source.match?(/func\s+consumeQuickAddRequest\s*\(/) && mac_selection_source.match?(/quickAddRequest\s*=\s*nil/)
raise "Mac detail quick-add request identity guard missing" unless mac_selection_source.include?("quickAddRequest?.id == id")
raise "Mac timer quick-add request wiring missing" unless mac_detail_content_source.include?("MacTimerDetailView(") && mac_detail_content_source.include?("selection.requestQuickAdd")
raise "Mac schedule quick-add request wiring missing" unless mac_detail_content_source.include?("MacScheduleDetailView(") && mac_detail_content_source.include?("selection.quickAddRequest") && mac_detail_content_source.include?("selection.consumeQuickAddRequest")
raise "Mac timer snapshot-compatible default action missing" unless mac_timer_view_source.match?(/init\s*\(\s*onAddTaskInCategory:\s*@escaping\s*\(String\)\s*->\s*Void\s*=\s*\{\s*_\s+in\s*\}/)
raise "Mac timer snapshot category injection missing" unless mac_timer_view_source.include?("initialTaskCategory: String? = nil") && mac_timer_view_source.include?("initialTaskCategory: initialTaskCategory")
raise "Mac timer category queue action wiring missing" unless mac_timer_view_source.include?("MacTaskQueueView(") && mac_timer_view_source.include?("onAddTaskInCategory: onAddTaskInCategory")
raise "Mac timer category filter state missing" unless mac_task_queue_source.include?("selectedCategory") && mac_task_queue_source.include?("visibleTasks") && mac_task_queue_source.include?("startableTasks")
raise "Mac timer category filter bar missing" unless mac_task_queue_source.include?("MacCategoryFilterBar(")
raise "Mac timer category count must expose filtered and total counts" unless mac_task_queue_source.match?(/\\\(visibleTasks\.count\)\/\\\(startableTasks\.count\)/) && mac_task_queue_source.include?("Text(taskQueueCountText)")
raise "Mac timer category empty state missing" unless mac_task_queue_source.include?("MacTimerCategoryEmptyStateView(") && mac_timer_source.include?("struct MacTimerCategoryEmptyStateView")
raise "Mac timer category empty state add action missing" unless mac_task_queue_source.include?("onAddTaskInCategory") && mac_timer_source.include?("新增此分类")
raise "Mac timer category empty state clear action missing" unless mac_task_queue_source.match?(/selectedCategory\s*=\s*nil/) && mac_timer_source.include?("清除筛选")
raise "Mac timer non-empty category context view missing" unless mac_timer_source.include?("struct MacTimerCategoryContextView") && mac_task_queue_source.include?("MacTimerCategoryContextView(")
raise "Mac timer non-empty category context must remain exclusive from empty state" unless mac_task_queue_source.match?(/else\s+if\s+visibleTasks\.isEmpty,\s*let\s+selectedCategory\s*\{[\s\S]*?MacTimerCategoryEmptyStateView\([\s\S]*?\}\s+else\s+\{\s*if\s+let\s+selectedCategory\s*\{\s*MacTimerCategoryContextView\(/) && mac_task_queue_source.scan(/MacTimerCategoryContextView\(/).length == 1
raise "Mac timer non-empty category context counts missing" unless mac_task_queue_source.match?(/MacTimerCategoryContextView\([\s\S]*?filteredCount:\s*visibleTasks\.count,[\s\S]*?totalCount:\s*startableTasks\.count/)
raise "Mac timer non-empty category context add action missing" unless mac_task_queue_source.include?("onAddTaskInCategory(selectedCategory)")
raise "Mac timer non-empty category context clear action missing" unless mac_task_queue_source.match?(/MacTimerCategoryContextView\([\s\S]*?self\.selectedCategory\s*=\s*nil/)
raise "Mac timer category context adaptive action layout missing" unless mac_timer_category_context_source.include?("ViewThatFits(in: .horizontal)")
raise "Mac timer category context stable action target missing" unless mac_timer_category_context_source.match?(/\.frame\(minWidth:[^\n]*minHeight:\s*36\)/)
raise "Mac timer category context accessibility labels missing" unless mac_timer_category_context_source.match?(/\.accessibilityLabel\([^\n]*category/) && mac_timer_category_context_source.include?(".accessibilityHint(") && mac_timer_category_context_source.include?(".accessibilityInputLabels(")
raise "Mac task row category badge compatibility default missing" unless mac_task_row_source.match?(/var\s+showsCategoryBadge\s*=\s*true/)
raise "Mac task row visual category badge condition missing" unless mac_task_row_source.match?(/if\s+showsCategoryBadge\s*\{[\s\S]*?Label\(task\.category,/)
raise "Mac timer filtered task rows must hide repeated category badges" unless mac_task_queue_source.include?("showsCategoryBadge: selectedCategory == nil")
raise "Mac task row accessibility category semantics missing" unless mac_task_row_source.include?("\\(task.title)，\\(task.category)分类") && mac_task_row_source.include?("Text(\"\\(task.category)分类待办\")") && mac_task_row_source.include?(".accessibilityHint(selectionHintText)") && mac_task_row_source.include?(".accessibilityAddTraits(selectionAccessibilityTraits)")
raise "Mac timer category filter must use prioritized options" unless mac_schedule_source.include?("TaskCategoryPreset.prioritizedFilterOptions")
raise "Mac schedule snapshot-compatible request default missing" unless mac_schedule_view_source.match?(/quickAddRequest:[^\n=]*\?\s*=\s*nil/)
raise "Mac schedule snapshot-compatible consume default missing" unless mac_schedule_view_source.match?(/onConsumeQuickAddRequest:\s*@escaping\s*\(UUID\)\s*->\s*Void\s*=\s*\{\s*_\s+in\s*\}/)
raise "Mac schedule quick-add request identity consumption missing" unless mac_schedule_view_source.include?(".task(id: quickAddRequest?.id)")
raise "Mac schedule quick-add category preparation missing" unless mac_schedule_view_source.match?(/prepareQuickAdd\s*\(\s*quickAddRequest\.category\s*\)/)
raise "Mac schedule quick-add request consumption missing" unless mac_schedule_view_source.include?("onConsumeQuickAddRequest(quickAddRequest.id)")
mac_snapshot_source = File.read("scripts/render_mac_snapshots.swift")
mac_timer_category_context_narrow_snapshot_source = segment_slice(
  mac_snapshot_source,
  "let timerCategoryContextNarrowURL",
  "print(timerCategoryFilteredURL.path)",
  "Mac timer category context narrow snapshot source missing"
)
raise "Mac timer normal queue snapshot coverage missing" unless mac_snapshot_source.include?("chronofocus-mac-timer-normal-queue.png") && mac_snapshot_source.include?("content: AnyView(MacTimerDetailView())")
raise "Mac timer handoff snapshot coverage missing" unless mac_snapshot_source.match?(/"detail-timer\.png",\s*\.timer,\s*AnyView\(MacTimerDetailView\([\s\S]{0,500}?initialTaskCategory:\s*"产品",[\s\S]{0,500}?timerHandoffRequest:\s*timerHandoffRequest/) && mac_snapshot_source.include?("resolveMacTimerHandoffTask(")
raise "Mac timer category empty snapshot fixture missing" unless mac_snapshot_source.include?("MacTimerDetailView(initialTaskCategory: \"工作\")") && mac_snapshot_source.include?("allSatisfy({ $0.category != \"工作\" })")
raise "Mac timer category empty narrow snapshot fixture missing" unless mac_snapshot_source.include?("MacTimerCategoryEmptyStateView(") && mac_snapshot_source.include?(".frame(width: 220)")
raise "Mac timer non-empty category snapshot fixture missing" unless mac_snapshot_source.match?(/timerCategoryFilteredView[\s\S]{0,500}?MacTimerDetailView\(initialTaskCategory:\s*"产品"\)/) && mac_snapshot_source.include?("chronofocus-mac-timer-category-filtered.png")
raise "Mac timer category context narrow snapshot fixture missing" unless mac_timer_category_context_narrow_snapshot_source.include?("MacTimerCategoryContextView(") && mac_timer_category_context_narrow_snapshot_source.include?("chronofocus-mac-timer-category-context-narrow.png") && mac_timer_category_context_narrow_snapshot_source.include?(".frame(width: 220)")
raise "Mac timer category context narrow snapshot long category fixture missing" unless mac_timer_category_context_narrow_snapshot_source.include?("category: \"跨团队产品体验优化\"")
raise "Mac timer category context narrow snapshot minimum pixel size assertion missing" unless mac_timer_category_context_narrow_snapshot_source.include?("try assertMinimumPixelSize(") && mac_timer_category_context_narrow_snapshot_source.include?("at: timerCategoryContextNarrowURL") && mac_timer_category_context_narrow_snapshot_source.include?("width: 400") && mac_timer_category_context_narrow_snapshot_source.include?("height: 220")
puts "Mac timer category queue contracts verified."
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
echo "Current task selection accessibility contracts verified."
ruby <<'RUBY'
def require_timer_action_contract(path, start_marker, end_marker, name)
  source = File.read(path, encoding: "UTF-8")
  pattern = /#{Regexp.escape(start_marker)}[\s\S]*?#{Regexp.escape(end_marker)}/
  source = source[pattern]
  raise "#{name} source missing" unless source
  raise "#{name} task helper missing" unless source.include?("private var timerActionTask: FocusTask?") && source.include?("store.task(for: engine.selectedTaskID)")
  raise "#{name} context missing task and category" unless source.include?("return \"\\(task.title)，\\(task.category)分类\"") && source.include?("return engine.currentTaskTitle")
  raise "#{name} primary label missing context" unless source.include?("开始\\(timerActionContext)计时") && source.include?("继续\\(timerActionContext)计时") && source.include?("暂停\\(timerActionContext)计时")
  raise "#{name} stop label missing context" unless source.include?(".accessibilityLabel(\"停止\\(timerActionContext)计时\")")
  raise "#{name} skip label missing context" unless source.include?(".accessibilityLabel(\"跳过\\(timerActionContext)当前轮\")")
  raise "#{name} Voice Control labels missing category" unless source.include?("Text(\"\\(action)\\(task.category)分类\")") && source.include?("Text(\"\\(task.category)分类\\(action)\")") && source.include?(".accessibilityInputLabels(timerActionInputLabels")
end

require_timer_action_contract(
  "ChronoFocus/Views/TimerView.swift",
  "struct TimerView: View",
  "private var timerControlPanel",
  "iOS timer action"
)
ios_source = File.read("ChronoFocus/Views/TimerView.swift", encoding: "UTF-8")
raise "iOS open ended finish action missing task context" unless ios_source.include?(".accessibilityLabel(\"完成\\(timerActionContext)待办\")") && ios_source.include?(".accessibilityInputLabels(timerActionInputLabels(\"完成\"))")

require_timer_action_contract(
  "ChronoFocusMac/Views/MacTimerDetailView.swift",
  "private struct MacTimerActionRowView",
  "private struct MacTodaySummaryView",
  "Mac timer action"
)
mac_source = File.read("ChronoFocusMac/Views/MacTimerDetailView.swift", encoding: "UTF-8")
raise "Mac static timer action labels missing context" unless mac_source.include?("private struct MacStaticTimerActionRowView") && mac_source.include?("accessibilityLabel: \"停止\\(timerActionContext)计时\"") && mac_source.include?("accessibilityLabel: primaryTimerActionLabel") && mac_source.include?(".accessibilityInputLabels(inputLabels)")

require_timer_action_contract(
  "ChronoFocusMac/Views/MacMiniTimerView.swift",
  "private struct MacMiniControlsView",
  "private struct MacMiniTaskPickerView",
  "Mac mini timer action"
)
puts "Timer action accessibility contracts verified."
RUBY
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
grep -q "require \"digest\"" scripts/validate_ci_artifact.rb
grep -q "require \"open3\"" scripts/validate_ci_artifact.rb
grep -q "require \"tmpdir\"" scripts/validate_ci_artifact.rb
grep -q "require \"zlib\"" scripts/validate_ci_artifact.rb
grep -q -- "--archive ZIP" scripts/validate_ci_artifact.rb
grep -q -- "--archive-size BYTES" scripts/validate_ci_artifact.rb
grep -q -- "--archive-digest DIGEST" scripts/validate_ci_artifact.rb
grep -q -- "--artifact-metadata JSON" scripts/validate_ci_artifact.rb
grep -q -- "--run-metadata JSON" scripts/validate_ci_artifact.rb
grep -q "MAX_ARTIFACT_METADATA_BYTES = 1_048_576" scripts/validate_ci_artifact.rb
grep -q "MAX_RUN_METADATA_BYTES = MAX_ARTIFACT_METADATA_BYTES" scripts/validate_ci_artifact.rb
grep -q "EXPECTED_WORKFLOW_RUN_NAME = \"ChronoFocus CI Results\"" scripts/validate_ci_artifact.rb
grep -q "EXPECTED_WORKFLOW_RUN_PATH = \".github/workflows/ci-results.yml\"" scripts/validate_ci_artifact.rb
grep -q "EXPECTED_WORKFLOW_RUN_REPOSITORY = \"Altman-sam114/114\"" scripts/validate_ci_artifact.rb
grep -q "Archive arguments must be provided together" scripts/validate_ci_artifact.rb
grep -q -- "--artifact-metadata requires --archive, --archive-size, and --archive-digest" scripts/validate_ci_artifact.rb
grep -q -- "--run-metadata requires --archive, --archive-size, --archive-digest, and --artifact-metadata" scripts/validate_ci_artifact.rb
grep -q "validate_external_metadata_path" scripts/validate_ci_artifact.rb
grep -q "File.lstat(path)" scripts/validate_ci_artifact.rb
grep -q "metadata_stat.symlink?" scripts/validate_ci_artifact.rb
grep -q "Open3.capture3(\*\[\"unzip\", \"-t\", archive_path\])" scripts/validate_ci_artifact.rb
grep -q "artifact archive byte count" scripts/validate_ci_artifact.rb
grep -q "artifact archive sha256 digest" scripts/validate_ci_artifact.rb
grep -q "artifact archive zip integrity" scripts/validate_ci_artifact.rb
grep -q "artifact archive extracted directory binding" scripts/validate_ci_artifact.rb
grep -q "zip_parse_archive" scripts/validate_ci_artifact.rb
grep -q "archive_directory_snapshot" scripts/validate_ci_artifact.rb
grep -q "archive_compare_directory_snapshots" scripts/validate_ci_artifact.rb
grep -q "artifact metadata response shape" scripts/validate_ci_artifact.rb
grep -q "artifact metadata unique artifact" scripts/validate_ci_artifact.rb
grep -q "artifact metadata id" scripts/validate_ci_artifact.rb
grep -q "artifact metadata name" scripts/validate_ci_artifact.rb
grep -q "artifact metadata byte count" scripts/validate_ci_artifact.rb
grep -q "artifact metadata sha256 digest" scripts/validate_ci_artifact.rb
grep -q "artifact metadata not expired" scripts/validate_ci_artifact.rb
grep -q "artifact metadata workflow run" scripts/validate_ci_artifact.rb
grep -q "workflow run metadata response shape" scripts/validate_ci_artifact.rb
grep -q "workflow run metadata id" scripts/validate_ci_artifact.rb
grep -q "workflow run metadata run attempt" scripts/validate_ci_artifact.rb
grep -q "workflow run metadata head sha" scripts/validate_ci_artifact.rb
grep -q "workflow run metadata head branch" scripts/validate_ci_artifact.rb
grep -q "workflow run metadata name" scripts/validate_ci_artifact.rb
grep -q "workflow run metadata path" scripts/validate_ci_artifact.rb
grep -q "workflow run metadata status" scripts/validate_ci_artifact.rb
grep -q "workflow run metadata conclusion" scripts/validate_ci_artifact.rb
grep -q "workflow run metadata repository" scripts/validate_ci_artifact.rb
grep -q "workflow run metadata event" scripts/validate_ci_artifact.rb
grep -q "workflow run metadata actor" scripts/validate_ci_artifact.rb
grep -q "workflow run metadata triggering actor" scripts/validate_ci_artifact.rb
grep -q "workflow run metadata head repository" scripts/validate_ci_artifact.rb
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
grep -q "Schedule category empty state action contracts verified." scripts/validate_ci_artifact.rb
grep -q "Mac schedule category empty state action contracts verified." scripts/validate_ci_artifact.rb
grep -q "Mac calendar range empty state quick add contracts verified." scripts/validate_ci_artifact.rb
grep -q "Timer category empty state action contracts verified." scripts/validate_ci_artifact.rb
grep -q "Timer task queue expansion contracts verified." scripts/validate_ci_artifact.rb
grep -q "Declaration boundary resilience contracts verified." scripts/validate_ci_artifact.rb
grep -q "Mac timer category queue contracts verified." scripts/validate_ci_artifact.rb
grep -q "CI action Node.js 24 contracts verified." scripts/validate_ci_artifact.rb
grep -q "CI failure summary output contracts verified." scripts/validate_ci_artifact.rb
grep -q "CI artifact archive integrity contracts verified." scripts/validate_ci_artifact.rb
grep -q "CI artifact API metadata contracts verified." scripts/validate_ci_artifact.rb
grep -q "Existing category reuse contracts verified." scripts/validate_ci_artifact.rb
grep -q "Existing category usage context contracts verified." scripts/validate_ci_artifact.rb
grep -q "Existing category search contracts verified." scripts/validate_ci_artifact.rb
grep -q "Schedule to timer handoff contracts verified." scripts/validate_ci_artifact.rb
grep -q "Startable task consistency contracts verified." scripts/validate_ci_artifact.rb
grep -q "CI workflow run API metadata contracts verified." scripts/validate_ci_artifact.rb
grep -q "CI workflow run provenance contracts verified." scripts/validate_ci_artifact.rb
grep -q "verify_ci_failure_summary_output()" scripts/verify_project.sh
grep -q "CI failure summary output contracts verified." scripts/verify_project.sh
grep -q "Mac quick add action accessibility contracts verified." scripts/validate_ci_artifact.rb
grep -q "Mac quick add title field category context contracts verified." scripts/validate_ci_artifact.rb
grep -q "Category input context contracts verified." scripts/validate_ci_artifact.rb
grep -q "Task editor save category accessibility contracts verified." scripts/validate_ci_artifact.rb
grep -q "Task editor cancel category accessibility contracts verified." scripts/validate_ci_artifact.rb
grep -q "Mac mini quick panel accessibility contracts verified." scripts/validate_ci_artifact.rb
grep -q "Analytics category share accessibility contracts verified." scripts/validate_ci_artifact.rb
grep -q "Analytics category share session count contracts verified." scripts/validate_ci_artifact.rb
grep -q "Analytics category share ranking contracts verified." scripts/validate_ci_artifact.rb
grep -q "Analytics category share sort context contracts verified." scripts/validate_ci_artifact.rb
grep -q "Analytics category share empty state contracts verified." scripts/validate_ci_artifact.rb
grep -q "Analytics category share metadata readability contracts verified." scripts/validate_ci_artifact.rb
grep -q "Analytics category share percent readability contracts verified." scripts/validate_ci_artifact.rb
grep -q "Analytics recent session category contracts verified." scripts/validate_ci_artifact.rb
grep -q "Analytics plan review category accessibility contracts verified." scripts/validate_ci_artifact.rb
grep -q "Category filter toggle contracts verified." scripts/validate_ci_artifact.rb
grep -q "Current task selection accessibility contracts verified." scripts/validate_ci_artifact.rb
grep -q "Timer action accessibility contracts verified." scripts/validate_ci_artifact.rb
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
grep -q "negative_schedule_category_empty_state_marker_fixture" scripts/verify_project.sh
grep -q "negative_mac_schedule_category_empty_state_marker_fixture" scripts/verify_project.sh
grep -q "negative_mac_calendar_range_empty_state_marker_fixture" scripts/verify_project.sh
grep -q "negative_timer_category_empty_state_marker_fixture" scripts/verify_project.sh
grep -q "negative_timer_task_queue_expansion_marker_fixture" scripts/verify_project.sh
grep -q "negative_startable_task_consistency_marker_fixture" scripts/verify_project.sh
grep -q "negative_declaration_boundary_resilience_marker_fixture" scripts/verify_project.sh
grep -q "negative_mac_timer_category_queue_marker_fixture" scripts/verify_project.sh
grep -q "negative_ci_action_node24_marker_fixture" scripts/verify_project.sh
grep -q "ci_failure_summary_cat_workflow_fixture" scripts/verify_project.sh
grep -q "negative_ci_failure_summary_output_marker_fixture" scripts/verify_project.sh
grep -q "checkout_v4_workflow_fixture" scripts/verify_project.sh
grep -q "upload_v4_workflow_fixture" scripts/verify_project.sh
grep -q "negative_mac_quick_add_action_marker_fixture" scripts/verify_project.sh
grep -q "negative_mac_quick_add_title_context_marker_fixture" scripts/verify_project.sh
grep -q "negative_category_input_context_marker_fixture" scripts/verify_project.sh
grep -q "negative_task_editor_save_marker_fixture" scripts/verify_project.sh
grep -q "negative_task_editor_cancel_marker_fixture" scripts/verify_project.sh
grep -q "negative_mac_mini_quick_panel_marker_fixture" scripts/verify_project.sh
grep -q "negative_analytics_category_share_marker_fixture" scripts/verify_project.sh
grep -q "negative_analytics_category_share_ranking_marker_fixture" scripts/verify_project.sh
grep -q "negative_analytics_category_share_sort_context_marker_fixture" scripts/verify_project.sh
grep -q "negative_analytics_category_share_empty_state_marker_fixture" scripts/verify_project.sh
grep -q "negative_analytics_category_share_metadata_readability_marker_fixture" scripts/verify_project.sh
grep -q "negative_analytics_category_share_percent_readability_marker_fixture" scripts/verify_project.sh
grep -q "negative_analytics_recent_session_marker_fixture" scripts/verify_project.sh
grep -q "negative_analytics_plan_review_marker_fixture" scripts/verify_project.sh
grep -q "negative_category_filter_toggle_marker_fixture" scripts/verify_project.sh
grep -q "negative_current_task_selection_marker_fixture" scripts/verify_project.sh
grep -q "negative_timer_action_marker_fixture" scripts/verify_project.sh
grep -q "negative_artifact_archive_digest_fixture" scripts/verify_project.sh
grep -q "negative_artifact_archive_size_fixture" scripts/verify_project.sh
grep -q "negative_artifact_archive_zip_fixture" scripts/verify_project.sh
grep -q "artifact_archive_directory_mismatch_fixture" scripts/verify_project.sh
grep -q "negative_archive_traversal_fixture" scripts/verify_project.sh
grep -q "negative_archive_duplicate_path_fixture" scripts/verify_project.sh
grep -q "negative_archive_special_file_fixture" scripts/verify_project.sh
grep -q "artifact_metadata_fixture" scripts/verify_project.sh
grep -q "negative_artifact_metadata_symlink_fixture" scripts/verify_project.sh
grep -q "negative_artifact_metadata_digest_fixture" scripts/verify_project.sh
grep -q "negative_artifact_metadata_workflow_branch_fixture" scripts/verify_project.sh
grep -q "negative_ci_artifact_archive_integrity_marker_fixture" scripts/verify_project.sh
grep -q "negative_ci_artifact_api_metadata_marker_fixture" scripts/verify_project.sh
grep -q "negative_existing_category_reuse_marker_fixture" scripts/verify_project.sh
grep -q "negative_existing_category_search_marker_fixture" scripts/verify_project.sh
grep -q "negative_ci_workflow_run_api_metadata_marker_fixture" scripts/verify_project.sh
grep -q "negative_ci_workflow_run_provenance_marker_fixture" scripts/verify_project.sh
grep -q "run_metadata_fixture" scripts/verify_project.sh
grep -q "negative_run_metadata_symlink_fixture" scripts/verify_project.sh
grep -q "negative_run_metadata_repository_full_name_fixture" scripts/verify_project.sh
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
grep -q "FAIL verify_project schedule category empty state action contracts" scripts/verify_project.sh
grep -q "FAIL verify_project mac schedule category empty state action contracts" scripts/verify_project.sh
grep -q "FAIL verify_project mac calendar range empty state quick add contracts" scripts/verify_project.sh
grep -q "FAIL verify_project timer category empty state action contracts" scripts/verify_project.sh
grep -q "FAIL verify_project timer task queue expansion contracts" scripts/verify_project.sh
grep -q "FAIL verify_project startable task consistency contracts" scripts/verify_project.sh
grep -q "FAIL verify_project declaration boundary resilience contracts" scripts/verify_project.sh
grep -q "FAIL verify_project mac timer category queue contracts" scripts/verify_project.sh
grep -q "FAIL verify_project ci action Node.js 24 contracts" scripts/verify_project.sh
grep -q "FAIL verify_project ci failure summary output contracts" scripts/verify_project.sh
grep -q "FAIL artifact archive sha256 digest" scripts/verify_project.sh
grep -q "FAIL artifact archive byte count" scripts/verify_project.sh
grep -q "FAIL artifact archive zip integrity" scripts/verify_project.sh
grep -q "FAIL artifact archive extracted directory binding" scripts/verify_project.sh
grep -q "FAIL artifact metadata response shape" scripts/verify_project.sh
grep -q "FAIL artifact metadata unique artifact" scripts/verify_project.sh
grep -q "FAIL artifact metadata id" scripts/verify_project.sh
grep -q "FAIL artifact metadata name" scripts/verify_project.sh
grep -q "FAIL artifact metadata byte count" scripts/verify_project.sh
grep -q "FAIL artifact metadata sha256 digest" scripts/verify_project.sh
grep -q "FAIL artifact metadata not expired" scripts/verify_project.sh
grep -q "FAIL artifact metadata workflow run" scripts/verify_project.sh
grep -q "FAIL verify_project ci artifact archive integrity contracts" scripts/verify_project.sh
grep -q "FAIL verify_project ci artifact API metadata contracts" scripts/verify_project.sh
grep -q "FAIL verify_project mac quick add action accessibility contracts" scripts/verify_project.sh
grep -q "FAIL verify_project mac quick add title field category context contracts" scripts/verify_project.sh
grep -q "FAIL verify_project category input context contracts" scripts/verify_project.sh
grep -q "FAIL verify_project task editor save category accessibility contracts" scripts/verify_project.sh
grep -q "FAIL verify_project task editor cancel category accessibility contracts" scripts/verify_project.sh
grep -q "FAIL verify_project mac mini quick panel accessibility contracts" scripts/verify_project.sh
grep -q "FAIL verify_project analytics category share accessibility contracts" scripts/verify_project.sh
grep -q "FAIL verify_project analytics category share ranking contracts" scripts/verify_project.sh
grep -q "FAIL verify_project analytics category share sort context contracts" scripts/verify_project.sh
grep -q "FAIL verify_project analytics category share empty state contracts" scripts/verify_project.sh
grep -q "FAIL verify_project analytics category share metadata readability contracts" scripts/verify_project.sh
grep -q "FAIL verify_project analytics category share percent readability contracts" scripts/verify_project.sh
grep -q "FAIL verify_project analytics recent session category contracts" scripts/verify_project.sh
grep -q "FAIL verify_project analytics plan review category accessibility contracts" scripts/verify_project.sh
grep -q "FAIL verify_project category filter toggle contracts" scripts/verify_project.sh
grep -q "FAIL verify_project current task selection accessibility contracts" scripts/verify_project.sh
grep -q "FAIL verify_project timer action accessibility contracts" scripts/verify_project.sh
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
grep -q "manifest overall outcome" scripts/validate_ci_artifact.rb
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
grep -q "FAIL manifest overall outcome" scripts/verify_project.sh
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
    "verify_project.log": "Mac core tests passed.\nCategory summary action contracts verified.\nCategory chip accessibility contracts verified.\nSchedule task action accessibility contracts verified.\nPlan start action accessibility contracts verified.\nPlan category badge contracts verified.\nMac plan category context contracts verified.\nPlan panel action accessibility contracts verified.\nSchedule toolbar add category context contracts verified.\nSchedule category empty state action contracts verified.\nMac schedule category empty state action contracts verified.\nMac calendar range empty state quick add contracts verified.\nMac quick add action accessibility contracts verified.\nMac quick add title field category context contracts verified.\nCategory input context contracts verified.\nExisting category reuse contracts verified.\nExisting category usage context contracts verified.\nExisting category search contracts verified.\nSchedule to timer handoff contracts verified.\nTask editor save category accessibility contracts verified.\nTask editor cancel category accessibility contracts verified.\nMac mini quick panel accessibility contracts verified.\nAnalytics category share accessibility contracts verified.\nAnalytics category share session count contracts verified.\nAnalytics category share ranking contracts verified.\nAnalytics category share sort context contracts verified.\nAnalytics category share empty state contracts verified.\nAnalytics category share metadata readability contracts verified.\nAnalytics category share percent readability contracts verified.\nAnalytics recent session category contracts verified.\nAnalytics plan review category accessibility contracts verified.\nCategory filter toggle contracts verified.\nCurrent task selection accessibility contracts verified.\nTimer action accessibility contracts verified.\nTimer category empty state action contracts verified.\nTimer task queue expansion contracts verified.\nDeclaration boundary resilience contracts verified.\nMac timer category queue contracts verified.\nCI action Node.js 24 contracts verified.\nCI failure summary output contracts verified.\nCI artifact archive integrity contracts verified.\nCI artifact API metadata contracts verified.\nCI workflow run API metadata contracts verified.\nCI workflow run provenance contracts verified.\nProject structure verified.\n",
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
- Overall outcome: `success`
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
    "overallOutcome": "success",
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
printf 'Startable task consistency contracts verified.\n' >> "$artifact_fixture/verify_project.log"
python3 - "$artifact_fixture" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
index_path = root / "ci-artifact-index.json"
index = json.loads(index_path.read_text(encoding="utf-8"))
for entry in index["entries"]:
    relative = entry["path"][len("ci-results/"):] if entry["path"].startswith("ci-results/") else entry["path"]
    path = root / relative
    if entry.get("kind") == "file":
        entry["byteCount"] = path.stat().st_size
    elif entry.get("kind") == "directory":
        files = [child for child in path.rglob("*") if child.is_file()]
        entry["fileCount"] = len(files)
        entry["recursiveByteCount"] = sum(child.stat().st_size for child in files)
index["totals"]["fileByteCount"] = sum(entry.get("byteCount", 0) for entry in index["entries"])
index["totals"]["directoryRecursiveByteCount"] = sum(entry.get("recursiveByteCount", 0) for entry in index["entries"])
index_path.write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
negative_startable_task_consistency_marker_fixture="$(mktemp -d)"
negative_startable_task_consistency_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_startable_task_consistency_marker_fixture"/
python3 - "$negative_startable_task_consistency_marker_fixture" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
marker = "Startable task consistency contracts verified.\n"
content = verify_log_path.read_text(encoding="utf-8")
if content.count(marker) != 1:
    raise SystemExit("startable task consistency marker fixture must contain exactly one marker")
verify_log_path.write_text(content.replace(marker, "", 1), encoding="utf-8")

index_path = root / "ci-artifact-index.json"
index = json.loads(index_path.read_text(encoding="utf-8"))
for entry in index["entries"]:
    relative = entry["path"][len("ci-results/"):] if entry["path"].startswith("ci-results/") else entry["path"]
    path = root / relative
    if entry.get("kind") == "file":
        entry["byteCount"] = path.stat().st_size
    elif entry.get("kind") == "directory":
        files = [child for child in path.rglob("*") if child.is_file()]
        entry["fileCount"] = len(files)
        entry["recursiveByteCount"] = sum(child.stat().st_size for child in files)
index["totals"]["fileByteCount"] = sum(entry.get("byteCount", 0) for entry in index["entries"])
index["totals"]["directoryRecursiveByteCount"] = sum(entry.get("recursiveByteCount", 0) for entry in index["entries"])
index_path.write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
if ruby scripts/validate_ci_artifact.rb "$negative_startable_task_consistency_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_startable_task_consistency_marker_output" 2>&1; then
  echo "Expected negative startable task consistency marker fixture to fail validation" >&2
  cat "$negative_startable_task_consistency_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project startable task consistency contracts" "$negative_startable_task_consistency_marker_output"
if grep -q "PASS verify_project startable task consistency contracts" "$negative_startable_task_consistency_marker_output" || [[ "$(grep -c '^FAIL ' "$negative_startable_task_consistency_marker_output")" -ne 1 ]]; then
  echo "Expected startable task consistency marker fixture to fail only its target contract" >&2
  cat "$negative_startable_task_consistency_marker_output" >&2
  exit 1
fi
rm -rf "$negative_startable_task_consistency_marker_fixture"
rm -f "$negative_startable_task_consistency_marker_output"
directory_only_output="$(mktemp)"
ruby scripts/validate_ci_artifact.rb "$artifact_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$directory_only_output"
if grep -q "PASS artifact archive extracted directory binding" "$directory_only_output"; then
  echo "Directory-only validation must not fabricate an archive binding PASS" >&2
  exit 1
fi
rm -f "$directory_only_output"
artifact_archive_fixture_dir="$(mktemp -d)"
artifact_archive_fixture="$artifact_archive_fixture_dir/chronofocus-ci-fixture.zip"
(
  cd "$artifact_fixture"
  zip -qry "$artifact_archive_fixture" *
)
ruby - "$artifact_archive_fixture" <<'RUBY'
path = ARGV.fetch(0)
data = File.binread(path)
eocd_offset = data.rindex("PK\x05\x06".b)
raise "ZIP end-of-central-directory record missing" unless eocd_offset

existing_comment_length = data.byteslice(eocd_offset + 20, 2)&.unpack1("v").to_i
raise "ZIP fixture end record bounds invalid" unless eocd_offset + 22 + existing_comment_length == data.bytesize

comment = "chronofocus-digest-fixture-comment".b
data[eocd_offset + 20, 2] = [comment.bytesize].pack("v")
data = data.byteslice(0, eocd_offset + 22) + comment
File.binwrite(path, data)
RUBY
artifact_archive_size="$(wc -c < "$artifact_archive_fixture" | tr -d '[:space:]')"
artifact_archive_digest="$(ruby -rdigest -e 'puts "sha256:#{Digest::SHA256.file(ARGV.fetch(0)).hexdigest}"' "$artifact_archive_fixture")"
artifact_archive_success_output="$(mktemp)"
if ! ruby scripts/validate_ci_artifact.rb \
  "$artifact_fixture" \
  --commit fixture-sha \
  --run-id 12345 \
  --attempt 1 \
  --archive "$artifact_archive_fixture" \
  --archive-size "$artifact_archive_size" \
  --archive-digest "$artifact_archive_digest" \
  >"$artifact_archive_success_output" 2>&1; then
  cat "$artifact_archive_success_output"
  exit 1
fi
grep -q "PASS artifact archive byte count" "$artifact_archive_success_output"
grep -q "PASS artifact archive sha256 digest" "$artifact_archive_success_output"
grep -q "PASS artifact archive zip integrity" "$artifact_archive_success_output"
grep -q "PASS artifact archive extracted directory binding" "$artifact_archive_success_output"
grep -q "PASS verify_project ci artifact archive integrity contracts" "$artifact_archive_success_output"
rm -f "$artifact_archive_success_output"

artifact_archive_directory_mismatch_fixture="$(mktemp -d)"
cp -R "$artifact_fixture"/. "$artifact_archive_directory_mismatch_fixture"/
python3 - "$artifact_archive_directory_mismatch_fixture/xcode-version.log" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
content = path.read_bytes()
original = b"Xcode 16.0\n"
replacement = b"Xcode 16.1\n"
if original not in content or len(original) != len(replacement):
    raise SystemExit("equal-length archive binding mismatch fixture replacement failed")
path.write_bytes(content.replace(original, replacement, 1))
PY
artifact_archive_directory_mismatch_output="$(mktemp)"
if ruby scripts/validate_ci_artifact.rb \
  "$artifact_archive_directory_mismatch_fixture" \
  --commit fixture-sha \
  --run-id 12345 \
  --attempt 1 \
  --archive "$artifact_archive_fixture" \
  --archive-size "$artifact_archive_size" \
  --archive-digest "$artifact_archive_digest" \
  >"$artifact_archive_directory_mismatch_output" 2>&1; then
  echo "Expected equal-length extracted directory mismatch to fail validation" >&2
  cat "$artifact_archive_directory_mismatch_output" >&2
  exit 1
fi
grep -q "PASS artifact archive byte count" "$artifact_archive_directory_mismatch_output"
grep -q "PASS artifact archive sha256 digest" "$artifact_archive_directory_mismatch_output"
grep -q "PASS artifact archive zip integrity" "$artifact_archive_directory_mismatch_output"
grep -q "FAIL artifact archive extracted directory binding" "$artifact_archive_directory_mismatch_output"
if grep -q "PASS artifact archive extracted directory binding" "$artifact_archive_directory_mismatch_output" || [[ "$(grep -c '^FAIL ' "$artifact_archive_directory_mismatch_output")" -ne 1 ]]; then
  echo "Expected the equal-length mismatch fixture to fail only archive binding" >&2
  cat "$artifact_archive_directory_mismatch_output" >&2
  exit 1
fi
rm -rf "$artifact_archive_directory_mismatch_fixture"
rm -f "$artifact_archive_directory_mismatch_output"

negative_archive_traversal_fixture="$artifact_archive_fixture_dir/negative-traversal.zip"
negative_archive_duplicate_path_fixture="$artifact_archive_fixture_dir/negative-duplicate-path.zip"
negative_archive_special_file_fixture="$artifact_archive_fixture_dir/negative-special-file.zip"
python3 - "$negative_archive_traversal_fixture" "$negative_archive_duplicate_path_fixture" "$negative_archive_special_file_fixture" <<'PY'
import stat
import sys
import warnings
import zipfile

traversal_path, duplicate_path, special_path = sys.argv[1:]
with zipfile.ZipFile(traversal_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
    archive.writestr("../escape.txt", b"escape")

warnings.filterwarnings("ignore", message=r"Duplicate name: 'duplicate\.txt'")
with zipfile.ZipFile(duplicate_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
    archive.writestr("duplicate.txt", b"first")
    archive.writestr("duplicate.txt", b"second")

special = zipfile.ZipInfo("special-link")
special.create_system = 3
special.external_attr = (stat.S_IFLNK | 0o777) << 16
special.compress_type = zipfile.ZIP_STORED
with zipfile.ZipFile(special_path, "w") as archive:
    archive.writestr(special, b"target")
PY

run_negative_archive_binding_fixture() {
  local archive_path="$1"
  local description="$2"
  local output_path
  local archive_size
  local archive_digest
  output_path="$(mktemp)"
  archive_size="$(wc -c < "$archive_path" | tr -d '[:space:]')"
  archive_digest="$(ruby -rdigest -e 'puts "sha256:#{Digest::SHA256.file(ARGV.fetch(0)).hexdigest}"' "$archive_path")"
  if ruby scripts/validate_ci_artifact.rb \
    "$artifact_fixture" \
    --commit fixture-sha \
    --run-id 12345 \
    --attempt 1 \
    --archive "$archive_path" \
    --archive-size "$archive_size" \
    --archive-digest "$archive_digest" \
    >"$output_path" 2>&1; then
    echo "Expected $description archive fixture to fail binding validation" >&2
    cat "$output_path" >&2
    exit 1
  fi
  if ! grep -q "PASS artifact archive zip integrity" "$output_path" || \
     ! grep -q "FAIL artifact archive extracted directory binding" "$output_path" || \
     grep -q "PASS artifact archive extracted directory binding" "$output_path"; then
    echo "Unexpected $description archive fixture validation output" >&2
    cat "$output_path" >&2
    exit 1
  fi
  rm -f "$output_path"
}

run_negative_archive_binding_fixture "$negative_archive_traversal_fixture" "traversal"
run_negative_archive_binding_fixture "$negative_archive_duplicate_path_fixture" "duplicate path"
run_negative_archive_binding_fixture "$negative_archive_special_file_fixture" "special file"

require_validator_marker() {
  local output_path="$1"
  local marker="$2"
  if ! grep -Fq -- "$marker" "$output_path"; then
    echo "Missing validator marker: $marker" >&2
    cat "$output_path" >&2
    exit 1
  fi
}

artifact_metadata_fixture="$artifact_archive_fixture_dir/artifacts-api.json"
ruby -rjson - "$artifact_metadata_fixture" "$artifact_archive_size" "$artifact_archive_digest" <<'RUBY'
path, archive_size, archive_digest = ARGV
payload = {
  "total_count" => 1,
  "artifacts" => [
    {
      "id" => 987_654_321,
      "name" => "chronofocus-ci-v0.10-main-fixture-run12345-attempt1",
      "size_in_bytes" => Integer(archive_size, 10),
      "digest" => archive_digest,
      "expired" => false,
      "workflow_run" => {
        "id" => 12_345,
        "head_sha" => "fixture-sha",
        "head_branch" => "main"
      },
      "future_github_field" => "allowed"
    }
  ],
  "future_response_field" => { "allowed" => true }
}
File.write(path, JSON.pretty_generate(payload) + "\n", encoding: "UTF-8")
RUBY
artifact_metadata_success_output="$(mktemp)"
if ! ruby scripts/validate_ci_artifact.rb \
  "$artifact_fixture" \
  --commit fixture-sha \
  --run-id 12345 \
  --attempt 1 \
  --archive "$artifact_archive_fixture" \
  --archive-size "$artifact_archive_size" \
  --archive-digest "$artifact_archive_digest" \
  --artifact-metadata "$artifact_metadata_fixture" \
  >"$artifact_metadata_success_output" 2>&1; then
  echo "Artifact metadata success fixture validator failed" >&2
  cat "$artifact_metadata_success_output" >&2
  exit 1
fi
for marker in \
  "PASS artifact metadata response shape" \
  "PASS artifact metadata unique artifact" \
  "PASS artifact metadata id" \
  "PASS artifact metadata name" \
  "PASS artifact metadata byte count" \
  "PASS artifact metadata sha256 digest" \
  "PASS artifact metadata not expired" \
  "PASS artifact metadata workflow run" \
  "PASS artifact archive byte count" \
  "PASS artifact archive sha256 digest" \
  "PASS artifact archive zip integrity" \
  "PASS artifact archive extracted directory binding" \
  "PASS verify_project ci artifact API metadata contracts"; do
  require_validator_marker "$artifact_metadata_success_output" "$marker"
done
rm -f "$artifact_metadata_success_output"

run_metadata_fixture="$artifact_archive_fixture_dir/run-api.json"
ruby -rjson - "$run_metadata_fixture" <<'RUBY'
path = ARGV.fetch(0)
payload = {
  "id" => 12_345,
  "run_attempt" => 1,
  "head_sha" => "fixture-sha",
  "head_branch" => "main",
  "name" => "ChronoFocus CI Results",
  "path" => ".github/workflows/ci-results.yml",
  "status" => "completed",
  "conclusion" => "success",
  "event" => "push",
  "actor" => {
    "login" => "Altman-sam114",
    "future_actor_field" => "allowed"
  },
  "triggering_actor" => {
    "login" => "Altman-sam114",
    "future_triggering_actor_field" => "allowed"
  },
  "head_repository" => {
    "full_name" => "Altman-sam114/114",
    "future_head_repository_field" => "allowed"
  },
  "repository" => {
    "full_name" => "Altman-sam114/114",
    "future_repository_field" => "allowed"
  },
  "future_run_field" => { "allowed" => true }
}
File.write(path, JSON.pretty_generate(payload) + "\n", encoding: "UTF-8")
RUBY

assert_archive_passes() {
  local output_path="$1"
  require_validator_marker "$output_path" "PASS artifact archive byte count"
  require_validator_marker "$output_path" "PASS artifact archive sha256 digest"
  require_validator_marker "$output_path" "PASS artifact archive zip integrity"
  require_validator_marker "$output_path" "PASS artifact archive extracted directory binding"
}

assert_artifact_metadata_passes() {
  local output_path="$1"
  require_validator_marker "$output_path" "PASS artifact metadata response shape"
  require_validator_marker "$output_path" "PASS artifact metadata unique artifact"
  require_validator_marker "$output_path" "PASS artifact metadata id"
  require_validator_marker "$output_path" "PASS artifact metadata name"
  require_validator_marker "$output_path" "PASS artifact metadata byte count"
  require_validator_marker "$output_path" "PASS artifact metadata sha256 digest"
  require_validator_marker "$output_path" "PASS artifact metadata not expired"
  require_validator_marker "$output_path" "PASS artifact metadata workflow run"
}

assert_run_metadata_passes_except() {
  local output_path="$1"
  local excluded_check="${2:-}"
  local check_name
  for check_name in \
    "response shape" \
    "id" \
    "run attempt" \
    "head sha" \
    "head branch" \
    "name" \
    "path" \
    "status" \
    "conclusion" \
    "repository" \
    "event" \
    "actor" \
    "triggering actor" \
    "head repository"; do
    if [[ "$check_name" != "$excluded_check" ]]; then
      require_validator_marker "$output_path" "PASS workflow run metadata $check_name"
    fi
  done
}

run_metadata_success_output="$(mktemp)"
if ! ruby scripts/validate_ci_artifact.rb \
  "$artifact_fixture" \
  --commit fixture-sha \
  --run-id 12345 \
  --attempt 1 \
  --archive "$artifact_archive_fixture" \
  --archive-size "$artifact_archive_size" \
  --archive-digest "$artifact_archive_digest" \
  --artifact-metadata "$artifact_metadata_fixture" \
  --run-metadata "$run_metadata_fixture" \
  >"$run_metadata_success_output" 2>&1; then
  echo "Run metadata success fixture validator failed" >&2
  cat "$run_metadata_success_output" >&2
  exit 1
fi
assert_archive_passes "$run_metadata_success_output"
assert_artifact_metadata_passes "$run_metadata_success_output"
assert_run_metadata_passes_except "$run_metadata_success_output"
for marker in \
  "PASS verify_project existing category reuse contracts" \
  "PASS verify_project existing category usage context contracts" \
  "PASS verify_project existing category search contracts" \
  "PASS verify_project schedule to timer handoff contracts" \
  "PASS verify_project ci workflow run API metadata contracts" \
  "PASS verify_project ci workflow run provenance contracts"; do
  require_validator_marker "$run_metadata_success_output" "$marker"
done
rm -f "$run_metadata_success_output"

negative_artifact_metadata_argument_group_output="$(mktemp)"
if ruby scripts/validate_ci_artifact.rb "$artifact_fixture" --commit fixture-sha --run-id 12345 --attempt 1 --artifact-metadata "$artifact_metadata_fixture" >"$negative_artifact_metadata_argument_group_output" 2>&1; then
  echo "Expected metadata without archive argument group to fail validation" >&2
  cat "$negative_artifact_metadata_argument_group_output" >&2
  exit 1
fi
grep -q -- "--artifact-metadata requires --archive, --archive-size, and --archive-digest" "$negative_artifact_metadata_argument_group_output"
rm -f "$negative_artifact_metadata_argument_group_output"

expect_artifact_metadata_argument_failure() {
  local metadata_path="$1"
  local expected_message="$2"
  local description="$3"
  local output_path
  output_path="$(mktemp)"

  if ruby scripts/validate_ci_artifact.rb \
    "$artifact_fixture" \
    --commit fixture-sha \
    --run-id 12345 \
    --attempt 1 \
    --archive "$artifact_archive_fixture" \
    --archive-size "$artifact_archive_size" \
    --archive-digest "$artifact_archive_digest" \
    --artifact-metadata "$metadata_path" \
    >"$output_path" 2>&1; then
    echo "Expected $description metadata fixture to fail argument validation" >&2
    cat "$output_path" >&2
    exit 1
  fi
  grep -q -- "$expected_message" "$output_path"
  rm -f "$output_path"
}

run_negative_artifact_metadata_fixture() {
  local metadata_path="$1"
  local expected_failure="$2"
  local description="$3"
  local output_path
  output_path="$(mktemp)"

  if ruby scripts/validate_ci_artifact.rb \
    "$artifact_fixture" \
    --commit fixture-sha \
    --run-id 12345 \
    --attempt 1 \
    --archive "$artifact_archive_fixture" \
    --archive-size "$artifact_archive_size" \
    --archive-digest "$artifact_archive_digest" \
    --artifact-metadata "$metadata_path" \
    >"$output_path" 2>&1; then
    echo "Expected $description metadata fixture to fail validation" >&2
    cat "$output_path" >&2
    exit 1
  fi
  grep -q "$expected_failure" "$output_path"
  grep -q "PASS artifact archive byte count" "$output_path"
  grep -q "PASS artifact archive sha256 digest" "$output_path"
  grep -q "PASS artifact archive zip integrity" "$output_path"
  rm -f "$output_path"
}

negative_artifact_metadata_empty_fixture="$artifact_archive_fixture_dir/negative-empty-metadata.json"
: > "$negative_artifact_metadata_empty_fixture"
expect_artifact_metadata_argument_failure "$negative_artifact_metadata_empty_fixture" "--artifact-metadata must not be empty" "empty"

negative_artifact_metadata_missing_fixture="$artifact_archive_fixture_dir/negative-missing-metadata.json"
expect_artifact_metadata_argument_failure "$negative_artifact_metadata_missing_fixture" "--artifact-metadata must reference an existing regular file" "missing"

negative_artifact_metadata_oversized_fixture="$artifact_archive_fixture_dir/negative-oversized-metadata.json"
ruby -e 'File.binwrite(ARGV.fetch(0), " " * 1_048_577)' "$negative_artifact_metadata_oversized_fixture"
expect_artifact_metadata_argument_failure "$negative_artifact_metadata_oversized_fixture" "--artifact-metadata must not exceed 1048576 bytes" "oversized"

negative_artifact_metadata_directory_fixture="$artifact_archive_fixture_dir/negative-metadata-directory"
mkdir "$negative_artifact_metadata_directory_fixture"
expect_artifact_metadata_argument_failure "$negative_artifact_metadata_directory_fixture" "--artifact-metadata must reference a regular file and must not be a symlink" "non-regular"

negative_artifact_metadata_symlink_fixture="$artifact_archive_fixture_dir/negative-metadata-symlink.json"
ln -s "$artifact_metadata_fixture" "$negative_artifact_metadata_symlink_fixture"
expect_artifact_metadata_argument_failure "$negative_artifact_metadata_symlink_fixture" "--artifact-metadata must reference a regular file and must not be a symlink" "symlink"

ruby -rjson - "$artifact_metadata_fixture" "$artifact_archive_fixture_dir" <<'RUBY'
source_path, output_dir = ARGV
source = JSON.parse(File.read(source_path, encoding: "UTF-8"))

write_fixture = lambda do |name, payload|
  File.write(File.join(output_dir, name), JSON.pretty_generate(payload) + "\n", encoding: "UTF-8")
end
mutate = lambda do |name, &block|
  payload = Marshal.load(Marshal.dump(source))
  block.call(payload)
  write_fixture.call(name, payload)
end

File.write(File.join(output_dir, "negative-invalid-metadata.json"), "{ invalid json\n", encoding: "UTF-8")
write_fixture.call("negative-top-level-array-metadata.json", [])
mutate.call("negative-zero-total-count-metadata.json") { |payload| payload["total_count"] = 0 }
mutate.call("negative-total-count-metadata.json") { |payload| payload["total_count"] = 2 }
mutate.call("negative-empty-artifacts-metadata.json") { |payload| payload["artifacts"] = [] }
mutate.call("negative-two-artifacts-metadata.json") { |payload| payload["artifacts"] << Marshal.load(Marshal.dump(payload["artifacts"].first)) }
mutate.call("negative-id-metadata.json") { |payload| payload["artifacts"][0]["id"] = 0 }
mutate.call("negative-id-below-zero-metadata.json") { |payload| payload["artifacts"][0]["id"] = -1 }
mutate.call("negative-string-id-metadata.json") { |payload| payload["artifacts"][0]["id"] = "987654321" }
mutate.call("negative-name-metadata.json") { |payload| payload["artifacts"][0]["name"] = "wrong-artifact-name" }
mutate.call("negative-size-metadata.json") { |payload| payload["artifacts"][0]["size_in_bytes"] += 1 }
mutate.call("negative-digest-metadata.json") { |payload| payload["artifacts"][0]["digest"] = "sha256:#{"0" * 64}" }
mutate.call("negative-expired-metadata.json") { |payload| payload["artifacts"][0]["expired"] = true }
mutate.call("negative-string-expired-metadata.json") { |payload| payload["artifacts"][0]["expired"] = "false" }
mutate.call("negative-missing-workflow-metadata.json") { |payload| payload["artifacts"][0].delete("workflow_run") }
mutate.call("negative-workflow-type-metadata.json") { |payload| payload["artifacts"][0]["workflow_run"] = [] }
mutate.call("negative-workflow-id-metadata.json") { |payload| payload["artifacts"][0]["workflow_run"]["id"] = 54_321 }
mutate.call("negative-workflow-sha-metadata.json") { |payload| payload["artifacts"][0]["workflow_run"]["head_sha"] = "wrong-sha" }
mutate.call("negative-workflow-branch-metadata.json") { |payload| payload["artifacts"][0]["workflow_run"]["head_branch"] = "wrong-branch" }
RUBY

negative_artifact_metadata_invalid_json_fixture="$artifact_archive_fixture_dir/negative-invalid-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_invalid_json_fixture" "FAIL artifact metadata response shape" "invalid JSON"
negative_artifact_metadata_top_array_fixture="$artifact_archive_fixture_dir/negative-top-level-array-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_top_array_fixture" "FAIL artifact metadata response shape" "top-level array"
negative_artifact_metadata_zero_count_fixture="$artifact_archive_fixture_dir/negative-zero-total-count-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_zero_count_fixture" "FAIL artifact metadata response shape" "zero total count"
negative_artifact_metadata_count_fixture="$artifact_archive_fixture_dir/negative-total-count-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_count_fixture" "FAIL artifact metadata response shape" "total count"
negative_artifact_metadata_empty_artifacts_fixture="$artifact_archive_fixture_dir/negative-empty-artifacts-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_empty_artifacts_fixture" "FAIL artifact metadata unique artifact" "empty artifacts"
negative_artifact_metadata_two_artifacts_fixture="$artifact_archive_fixture_dir/negative-two-artifacts-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_two_artifacts_fixture" "FAIL artifact metadata unique artifact" "multiple artifacts"
negative_artifact_metadata_id_fixture="$artifact_archive_fixture_dir/negative-id-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_id_fixture" "FAIL artifact metadata id" "non-positive id"
negative_artifact_metadata_negative_id_fixture="$artifact_archive_fixture_dir/negative-id-below-zero-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_negative_id_fixture" "FAIL artifact metadata id" "negative id"
negative_artifact_metadata_string_id_fixture="$artifact_archive_fixture_dir/negative-string-id-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_string_id_fixture" "FAIL artifact metadata id" "string id"
negative_artifact_metadata_name_fixture="$artifact_archive_fixture_dir/negative-name-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_name_fixture" "FAIL artifact metadata name" "name mismatch"
negative_artifact_metadata_size_fixture="$artifact_archive_fixture_dir/negative-size-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_size_fixture" "FAIL artifact metadata byte count" "byte count mismatch"
negative_artifact_metadata_digest_fixture="$artifact_archive_fixture_dir/negative-digest-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_digest_fixture" "FAIL artifact metadata sha256 digest" "digest mismatch"
negative_artifact_metadata_expired_fixture="$artifact_archive_fixture_dir/negative-expired-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_expired_fixture" "FAIL artifact metadata not expired" "expired artifact"
negative_artifact_metadata_string_expired_fixture="$artifact_archive_fixture_dir/negative-string-expired-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_string_expired_fixture" "FAIL artifact metadata not expired" "string expired flag"
negative_artifact_metadata_missing_workflow_fixture="$artifact_archive_fixture_dir/negative-missing-workflow-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_missing_workflow_fixture" "FAIL artifact metadata workflow run" "missing workflow run"
negative_artifact_metadata_workflow_type_fixture="$artifact_archive_fixture_dir/negative-workflow-type-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_workflow_type_fixture" "FAIL artifact metadata workflow run" "workflow run type"
negative_artifact_metadata_workflow_id_fixture="$artifact_archive_fixture_dir/negative-workflow-id-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_workflow_id_fixture" "FAIL artifact metadata workflow run" "workflow run id mismatch"
negative_artifact_metadata_workflow_sha_fixture="$artifact_archive_fixture_dir/negative-workflow-sha-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_workflow_sha_fixture" "FAIL artifact metadata workflow run" "workflow head SHA mismatch"
negative_artifact_metadata_workflow_branch_fixture="$artifact_archive_fixture_dir/negative-workflow-branch-metadata.json"
run_negative_artifact_metadata_fixture "$negative_artifact_metadata_workflow_branch_fixture" "FAIL artifact metadata workflow run" "workflow head branch mismatch"

negative_run_metadata_without_prerequisites_output="$(mktemp)"
if ruby scripts/validate_ci_artifact.rb \
  "$artifact_fixture" \
  --commit fixture-sha \
  --run-id 12345 \
  --attempt 1 \
  --run-metadata "$run_metadata_fixture" \
  >"$negative_run_metadata_without_prerequisites_output" 2>&1; then
  echo "Expected run metadata without archive and artifact metadata to fail argument validation" >&2
  cat "$negative_run_metadata_without_prerequisites_output" >&2
  exit 1
fi
grep -q -- "--run-metadata requires --archive, --archive-size, --archive-digest, and --artifact-metadata" "$negative_run_metadata_without_prerequisites_output"
rm -f "$negative_run_metadata_without_prerequisites_output"

negative_run_metadata_without_artifact_metadata_output="$(mktemp)"
if ruby scripts/validate_ci_artifact.rb \
  "$artifact_fixture" \
  --commit fixture-sha \
  --run-id 12345 \
  --attempt 1 \
  --archive "$artifact_archive_fixture" \
  --archive-size "$artifact_archive_size" \
  --archive-digest "$artifact_archive_digest" \
  --run-metadata "$run_metadata_fixture" \
  >"$negative_run_metadata_without_artifact_metadata_output" 2>&1; then
  echo "Expected run metadata without artifact metadata to fail argument validation" >&2
  cat "$negative_run_metadata_without_artifact_metadata_output" >&2
  exit 1
fi
grep -q -- "--run-metadata requires --archive, --archive-size, --archive-digest, and --artifact-metadata" "$negative_run_metadata_without_artifact_metadata_output"
rm -f "$negative_run_metadata_without_artifact_metadata_output"

negative_run_metadata_without_archive_output="$(mktemp)"
if ruby scripts/validate_ci_artifact.rb \
  "$artifact_fixture" \
  --commit fixture-sha \
  --run-id 12345 \
  --attempt 1 \
  --artifact-metadata "$artifact_metadata_fixture" \
  --run-metadata "$run_metadata_fixture" \
  >"$negative_run_metadata_without_archive_output" 2>&1; then
  echo "Expected run and artifact metadata without archive arguments to fail argument validation" >&2
  cat "$negative_run_metadata_without_archive_output" >&2
  exit 1
fi
grep -q -- "--artifact-metadata requires --archive, --archive-size, and --archive-digest" "$negative_run_metadata_without_archive_output"
rm -f "$negative_run_metadata_without_archive_output"

expect_run_metadata_partial_archive_failure() {
  local missing_option="$1"
  shift
  local output_path
  output_path="$(mktemp)"

  if ruby scripts/validate_ci_artifact.rb \
    "$artifact_fixture" \
    --commit fixture-sha \
    --run-id 12345 \
    --attempt 1 \
    "$@" \
    --artifact-metadata "$artifact_metadata_fixture" \
    --run-metadata "$run_metadata_fixture" \
    >"$output_path" 2>&1; then
    echo "Expected run metadata with missing $missing_option to fail argument validation" >&2
    cat "$output_path" >&2
    exit 1
  fi
  grep -q "Archive arguments must be provided together" "$output_path"
  grep -q -- "$missing_option" "$output_path"
  rm -f "$output_path"
}

expect_run_metadata_partial_archive_failure \
  "--archive" \
  --archive-size "$artifact_archive_size" \
  --archive-digest "$artifact_archive_digest"
expect_run_metadata_partial_archive_failure \
  "--archive-size" \
  --archive "$artifact_archive_fixture" \
  --archive-digest "$artifact_archive_digest"
expect_run_metadata_partial_archive_failure \
  "--archive-digest" \
  --archive "$artifact_archive_fixture" \
  --archive-size "$artifact_archive_size"

negative_run_metadata_empty_argument_output="$(mktemp)"
if ruby scripts/validate_ci_artifact.rb \
  "$artifact_fixture" \
  --commit fixture-sha \
  --run-id 12345 \
  --attempt 1 \
  --archive "$artifact_archive_fixture" \
  --archive-size "$artifact_archive_size" \
  --archive-digest "$artifact_archive_digest" \
  --artifact-metadata "$artifact_metadata_fixture" \
  --run-metadata "" \
  >"$negative_run_metadata_empty_argument_output" 2>&1; then
  echo "Expected empty run metadata argument to fail argument validation" >&2
  cat "$negative_run_metadata_empty_argument_output" >&2
  exit 1
fi
grep -q -- "--run-metadata requires a non-empty JSON file path" "$negative_run_metadata_empty_argument_output"
rm -f "$negative_run_metadata_empty_argument_output"

negative_run_metadata_missing_argument_output="$(mktemp)"
if ruby scripts/validate_ci_artifact.rb \
  "$artifact_fixture" \
  --commit fixture-sha \
  --run-id 12345 \
  --attempt 1 \
  --archive "$artifact_archive_fixture" \
  --archive-size "$artifact_archive_size" \
  --archive-digest "$artifact_archive_digest" \
  --artifact-metadata "$artifact_metadata_fixture" \
  --run-metadata \
  >"$negative_run_metadata_missing_argument_output" 2>&1; then
  echo "Expected missing run metadata argument to fail argument validation" >&2
  cat "$negative_run_metadata_missing_argument_output" >&2
  exit 1
fi
grep -q -- "--run-metadata requires a non-empty JSON file path" "$negative_run_metadata_missing_argument_output"
rm -f "$negative_run_metadata_missing_argument_output"

expect_run_metadata_argument_failure() {
  local metadata_path="$1"
  local expected_message="$2"
  local description="$3"
  local output_path
  output_path="$(mktemp)"

  if ruby scripts/validate_ci_artifact.rb \
    "$artifact_fixture" \
    --commit fixture-sha \
    --run-id 12345 \
    --attempt 1 \
    --archive "$artifact_archive_fixture" \
    --archive-size "$artifact_archive_size" \
    --archive-digest "$artifact_archive_digest" \
    --artifact-metadata "$artifact_metadata_fixture" \
    --run-metadata "$metadata_path" \
    >"$output_path" 2>&1; then
    echo "Expected $description run metadata fixture to fail argument validation" >&2
    cat "$output_path" >&2
    exit 1
  fi
  grep -q -- "$expected_message" "$output_path"
  rm -f "$output_path"
}

run_negative_run_metadata_shape_fixture() {
  local metadata_path="$1"
  local description="$2"
  local output_path
  output_path="$(mktemp)"

  if ruby scripts/validate_ci_artifact.rb \
    "$artifact_fixture" \
    --commit fixture-sha \
    --run-id 12345 \
    --attempt 1 \
    --archive "$artifact_archive_fixture" \
    --archive-size "$artifact_archive_size" \
    --archive-digest "$artifact_archive_digest" \
    --artifact-metadata "$artifact_metadata_fixture" \
    --run-metadata "$metadata_path" \
    >"$output_path" 2>&1; then
    echo "Expected $description run metadata fixture to fail validation" >&2
    cat "$output_path" >&2
    exit 1
  fi
  grep -q "FAIL workflow run metadata response shape" "$output_path"
  assert_archive_passes "$output_path"
  assert_artifact_metadata_passes "$output_path"
  rm -f "$output_path"
}

run_negative_run_metadata_fixture() {
  local metadata_path="$1"
  local failed_check="$2"
  local description="$3"
  local output_path
  output_path="$(mktemp)"

  if ruby scripts/validate_ci_artifact.rb \
    "$artifact_fixture" \
    --commit fixture-sha \
    --run-id 12345 \
    --attempt 1 \
    --archive "$artifact_archive_fixture" \
    --archive-size "$artifact_archive_size" \
    --archive-digest "$artifact_archive_digest" \
    --artifact-metadata "$artifact_metadata_fixture" \
    --run-metadata "$metadata_path" \
    >"$output_path" 2>&1; then
    echo "Expected $description run metadata fixture to fail validation" >&2
    cat "$output_path" >&2
    exit 1
  fi
  grep -q "FAIL workflow run metadata $failed_check" "$output_path"
  assert_archive_passes "$output_path"
  assert_artifact_metadata_passes "$output_path"
  assert_run_metadata_passes_except "$output_path" "$failed_check"
  if [[ "$(grep -c '^FAIL ' "$output_path")" -ne 1 ]]; then
    echo "Expected only workflow run metadata $failed_check to fail for $description" >&2
    cat "$output_path" >&2
    exit 1
  fi
  rm -f "$output_path"
}

negative_run_metadata_missing_fixture="$artifact_archive_fixture_dir/missing-run-api.json"
expect_run_metadata_argument_failure "$negative_run_metadata_missing_fixture" "--run-metadata must reference an existing regular file" "missing file"

negative_run_metadata_empty_fixture="$artifact_archive_fixture_dir/empty-run-api.json"
: > "$negative_run_metadata_empty_fixture"
expect_run_metadata_argument_failure "$negative_run_metadata_empty_fixture" "--run-metadata must not be empty" "empty file"

negative_run_metadata_oversized_fixture="$artifact_archive_fixture_dir/oversized-run-api.json"
ruby -e 'File.binwrite(ARGV.fetch(0), "x" * (1_048_576 + 1))' "$negative_run_metadata_oversized_fixture"
expect_run_metadata_argument_failure "$negative_run_metadata_oversized_fixture" "--run-metadata must not exceed 1048576 bytes" "oversized file"

negative_run_metadata_directory_fixture="$artifact_archive_fixture_dir/run-api-directory"
mkdir "$negative_run_metadata_directory_fixture"
expect_run_metadata_argument_failure "$negative_run_metadata_directory_fixture" "--run-metadata must reference a regular file and must not be a symlink" "directory"

negative_run_metadata_symlink_fixture="$artifact_archive_fixture_dir/run-api-symlink.json"
ln -s "$run_metadata_fixture" "$negative_run_metadata_symlink_fixture"
expect_run_metadata_argument_failure "$negative_run_metadata_symlink_fixture" "--run-metadata must reference a regular file and must not be a symlink" "symlink"

negative_run_metadata_unreadable_fixture="$artifact_archive_fixture_dir/unreadable-run-api.json"
cp "$run_metadata_fixture" "$negative_run_metadata_unreadable_fixture"
chmod 000 "$negative_run_metadata_unreadable_fixture"
expect_run_metadata_argument_failure "$negative_run_metadata_unreadable_fixture" "--run-metadata must reference a readable regular file" "unreadable file"
chmod 600 "$negative_run_metadata_unreadable_fixture"

negative_run_metadata_invalid_json_fixture="$artifact_archive_fixture_dir/invalid-run-api.json"
printf '{"id":' > "$negative_run_metadata_invalid_json_fixture"
run_negative_run_metadata_shape_fixture "$negative_run_metadata_invalid_json_fixture" "invalid JSON"

negative_run_metadata_top_array_fixture="$artifact_archive_fixture_dir/top-array-run-api.json"
printf '[]\n' > "$negative_run_metadata_top_array_fixture"
run_negative_run_metadata_shape_fixture "$negative_run_metadata_top_array_fixture" "top-level array"

negative_run_metadata_top_string_fixture="$artifact_archive_fixture_dir/top-string-run-api.json"
printf '"run"\n' > "$negative_run_metadata_top_string_fixture"
run_negative_run_metadata_shape_fixture "$negative_run_metadata_top_string_fixture" "top-level string"

negative_run_metadata_top_number_fixture="$artifact_archive_fixture_dir/top-number-run-api.json"
printf '12345\n' > "$negative_run_metadata_top_number_fixture"
run_negative_run_metadata_shape_fixture "$negative_run_metadata_top_number_fixture" "top-level number"

negative_run_metadata_top_true_fixture="$artifact_archive_fixture_dir/top-true-run-api.json"
printf 'true\n' > "$negative_run_metadata_top_true_fixture"
run_negative_run_metadata_shape_fixture "$negative_run_metadata_top_true_fixture" "top-level boolean"

negative_run_metadata_top_null_fixture="$artifact_archive_fixture_dir/top-null-run-api.json"
printf 'null\n' > "$negative_run_metadata_top_null_fixture"
run_negative_run_metadata_shape_fixture "$negative_run_metadata_top_null_fixture" "top-level null"

ruby -rjson - "$run_metadata_fixture" "$artifact_archive_fixture_dir" <<'RUBY'
source_path, output_dir = ARGV
source = JSON.parse(File.read(source_path, encoding: "UTF-8"))
mutate = lambda do |name, &block|
  payload = Marshal.load(Marshal.dump(source))
  block.call(payload)
  File.write(File.join(output_dir, name), JSON.pretty_generate(payload) + "\n", encoding: "UTF-8")
end

fields = {
  "id" => ["id", 54_321, "12345"],
  "run-attempt" => ["run_attempt", 2, "1"],
  "head-sha" => ["head_sha", "0000000000000000000000000000000000000000", 12_345],
  "head-branch" => ["head_branch", "wrong-branch", 12_345],
  "name" => ["name", "Wrong Workflow", 12_345],
  "path" => ["path", ".github/workflows/wrong.yml", 12_345],
  "status" => ["status", "in_progress", 12_345],
  "conclusion" => ["conclusion", "failure", 12_345]
}
fields.each do |fixture_name, (field, wrong_value, wrong_type)|
  mutate.call("negative-missing-#{fixture_name}-run-api.json") { |payload| payload.delete(field) }
  mutate.call("negative-value-#{fixture_name}-run-api.json") { |payload| payload[field] = wrong_value }
  mutate.call("negative-type-#{fixture_name}-run-api.json") { |payload| payload[field] = wrong_type }
end
mutate.call("negative-zero-id-run-api.json") { |payload| payload["id"] = 0 }
mutate.call("negative-negative-id-run-api.json") { |payload| payload["id"] = -1 }
mutate.call("negative-zero-run-attempt-run-api.json") { |payload| payload["run_attempt"] = 0 }
mutate.call("negative-negative-run-attempt-run-api.json") { |payload| payload["run_attempt"] = -1 }
mutate.call("negative-short-head-sha-run-api.json") { |payload| payload["head_sha"] = "fixture" }
mutate.call("negative-file-name-path-run-api.json") { |payload| payload["path"] = "ci-results.yml" }
mutate.call("negative-queued-status-run-api.json") { |payload| payload["status"] = "queued" }
mutate.call("negative-uppercase-status-run-api.json") { |payload| payload["status"] = "COMPLETED" }
mutate.call("negative-null-conclusion-run-api.json") { |payload| payload["conclusion"] = nil }
mutate.call("negative-cancelled-conclusion-run-api.json") { |payload| payload["conclusion"] = "cancelled" }
mutate.call("negative-missing-repository-run-api.json") { |payload| payload.delete("repository") }
mutate.call("negative-repository-shape-run-api.json") { |payload| payload["repository"] = [] }
mutate.call("negative-missing-repository-full-name-run-api.json") { |payload| payload["repository"].delete("full_name") }
mutate.call("negative-repository-full-name-run-api.json") { |payload| payload["repository"]["full_name"] = "Other/114" }
mutate.call("negative-repository-name-run-api.json") { |payload| payload["repository"]["full_name"] = "Altman-sam114/other" }
mutate.call("negative-repository-short-name-run-api.json") { |payload| payload["repository"]["full_name"] = "114" }
mutate.call("negative-repository-full-name-type-run-api.json") { |payload| payload["repository"]["full_name"] = 12_345 }
mutate.call("negative-missing-event-run-api.json") { |payload| payload.delete("event") }
mutate.call("negative-value-event-run-api.json") { |payload| payload["event"] = "workflow_dispatch" }
mutate.call("negative-type-event-run-api.json") { |payload| payload["event"] = ["push"] }

[
  ["actor", "actor", "login"],
  ["triggering-actor", "triggering_actor", "login"],
  ["head-repository", "head_repository", "full_name"]
].each do |fixture_name, field, nested_field|
  wrong_value = fixture_name == "head-repository" ? "Other/114" : "unauthorized-user"
  mutate.call("negative-missing-#{fixture_name}-run-api.json") { |payload| payload.delete(field) }
  mutate.call("negative-shape-#{fixture_name}-run-api.json") { |payload| payload[field] = [] }
  mutate.call("negative-missing-#{fixture_name}-#{nested_field.tr("_", "-")}-run-api.json") { |payload| payload[field].delete(nested_field) }
  mutate.call("negative-value-#{fixture_name}-run-api.json") { |payload| payload[field][nested_field] = wrong_value }
  mutate.call("negative-type-#{fixture_name}-run-api.json") { |payload| payload[field][nested_field] = 12_345 }
end
RUBY

for run_field_spec in \
  "id:id" \
  "run-attempt:run attempt" \
  "head-sha:head sha" \
  "head-branch:head branch" \
  "name:name" \
  "path:path" \
  "status:status" \
  "conclusion:conclusion"; do
  run_fixture_name="${run_field_spec%%:*}"
  run_check_name="${run_field_spec#*:}"
  run_negative_run_metadata_fixture \
    "$artifact_archive_fixture_dir/negative-missing-$run_fixture_name-run-api.json" \
    "$run_check_name" \
    "missing $run_check_name"
  run_negative_run_metadata_fixture \
    "$artifact_archive_fixture_dir/negative-value-$run_fixture_name-run-api.json" \
    "$run_check_name" \
    "$run_check_name mismatch"
  run_negative_run_metadata_fixture \
    "$artifact_archive_fixture_dir/negative-type-$run_fixture_name-run-api.json" \
    "$run_check_name" \
    "$run_check_name type"
done
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-zero-id-run-api.json" "id" "zero id"
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-negative-id-run-api.json" "id" "negative id"
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-zero-run-attempt-run-api.json" "run attempt" "zero run attempt"
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-negative-run-attempt-run-api.json" "run attempt" "negative run attempt"
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-short-head-sha-run-api.json" "head sha" "short head SHA"
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-file-name-path-run-api.json" "path" "path file name only"
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-queued-status-run-api.json" "status" "queued status"
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-uppercase-status-run-api.json" "status" "uppercase status"
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-null-conclusion-run-api.json" "conclusion" "null conclusion"
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-cancelled-conclusion-run-api.json" "conclusion" "cancelled conclusion"
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-missing-repository-run-api.json" "repository" "missing repository"
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-repository-shape-run-api.json" "repository" "repository shape"
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-missing-repository-full-name-run-api.json" "repository" "missing repository full_name"
negative_run_metadata_repository_full_name_fixture="$artifact_archive_fixture_dir/negative-repository-full-name-run-api.json"
run_negative_run_metadata_fixture "$negative_run_metadata_repository_full_name_fixture" "repository" "repository owner mismatch"
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-repository-name-run-api.json" "repository" "repository name mismatch"
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-repository-short-name-run-api.json" "repository" "repository short name"
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-repository-full-name-type-run-api.json" "repository" "repository full_name type"
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-missing-event-run-api.json" "event" "missing event"
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-value-event-run-api.json" "event" "event mismatch"
run_negative_run_metadata_fixture "$artifact_archive_fixture_dir/negative-type-event-run-api.json" "event" "event type"

for run_provenance_spec in \
  "actor:actor:login" \
  "triggering-actor:triggering actor:login" \
  "head-repository:head repository:full-name"; do
  run_fixture_name="${run_provenance_spec%%:*}"
  run_provenance_remainder="${run_provenance_spec#*:}"
  run_check_name="${run_provenance_remainder%%:*}"
  run_nested_name="${run_provenance_remainder#*:}"
  run_negative_run_metadata_fixture \
    "$artifact_archive_fixture_dir/negative-missing-$run_fixture_name-run-api.json" \
    "$run_check_name" \
    "missing $run_check_name object"
  run_negative_run_metadata_fixture \
    "$artifact_archive_fixture_dir/negative-shape-$run_fixture_name-run-api.json" \
    "$run_check_name" \
    "$run_check_name object shape"
  run_negative_run_metadata_fixture \
    "$artifact_archive_fixture_dir/negative-missing-$run_fixture_name-$run_nested_name-run-api.json" \
    "$run_check_name" \
    "missing $run_check_name $run_nested_name"
  run_negative_run_metadata_fixture \
    "$artifact_archive_fixture_dir/negative-value-$run_fixture_name-run-api.json" \
    "$run_check_name" \
    "$run_check_name value mismatch"
  run_negative_run_metadata_fixture \
    "$artifact_archive_fixture_dir/negative-type-$run_fixture_name-run-api.json" \
    "$run_check_name" \
    "$run_check_name nested value type"
done

negative_artifact_archive_argument_group_output="$(mktemp)"
if ruby scripts/validate_ci_artifact.rb "$artifact_fixture" --commit fixture-sha --run-id 12345 --attempt 1 --archive "$artifact_archive_fixture" >"$negative_artifact_archive_argument_group_output" 2>&1; then
  echo "Expected partial archive argument group to fail validation" >&2
  cat "$negative_artifact_archive_argument_group_output" >&2
  exit 1
fi
grep -q "Archive arguments must be provided together" "$negative_artifact_archive_argument_group_output"
grep -q -- "--archive-size" "$negative_artifact_archive_argument_group_output"
grep -q -- "--archive-digest" "$negative_artifact_archive_argument_group_output"
rm -f "$negative_artifact_archive_argument_group_output"

negative_artifact_archive_digest_fixture="$artifact_archive_fixture_dir/negative-equal-length-digest.zip"
negative_artifact_archive_digest_output="$(mktemp)"
cp "$artifact_archive_fixture" "$negative_artifact_archive_digest_fixture"
ruby - "$negative_artifact_archive_digest_fixture" <<'RUBY'
path = ARGV.fetch(0)
data = File.binread(path)
eocd_offset = data.rindex("PK\x05\x06".b)
raise "ZIP end-of-central-directory record missing" unless eocd_offset

comment_length = data.byteslice(eocd_offset + 20, 2)&.unpack1("v").to_i
raise "ZIP fixture comment must be nonempty" unless comment_length.positive?

comment_offset = eocd_offset + 22
raise "ZIP fixture comment bounds invalid" unless comment_offset + comment_length == data.bytesize

comment_byte_offset = comment_offset + (comment_length / 2)
data.setbyte(comment_byte_offset, data.getbyte(comment_byte_offset) ^ 0x01)
File.binwrite(path, data)
RUBY
if ruby scripts/validate_ci_artifact.rb "$artifact_fixture" --commit fixture-sha --run-id 12345 --attempt 1 --archive "$negative_artifact_archive_digest_fixture" --archive-size "$artifact_archive_size" --archive-digest "$artifact_archive_digest" >"$negative_artifact_archive_digest_output" 2>&1; then
  echo "Expected equal-length archive digest fixture to fail validation" >&2
  cat "$negative_artifact_archive_digest_output" >&2
  exit 1
fi
grep -q "PASS artifact archive byte count" "$negative_artifact_archive_digest_output"
grep -q "FAIL artifact archive sha256 digest" "$negative_artifact_archive_digest_output"
grep -q "PASS artifact archive zip integrity" "$negative_artifact_archive_digest_output"
rm -f "$negative_artifact_archive_digest_fixture" "$negative_artifact_archive_digest_output"

negative_artifact_archive_size_fixture="$artifact_archive_fixture_dir/negative-truncated-size.zip"
negative_artifact_archive_size_output="$(mktemp)"
cp "$artifact_archive_fixture" "$negative_artifact_archive_size_fixture"
ruby -e 'path = ARGV.fetch(0); File.truncate(path, File.size(path) - 1)' "$negative_artifact_archive_size_fixture"
if ruby scripts/validate_ci_artifact.rb "$artifact_fixture" --commit fixture-sha --run-id 12345 --attempt 1 --archive "$negative_artifact_archive_size_fixture" --archive-size "$artifact_archive_size" --archive-digest "$artifact_archive_digest" >"$negative_artifact_archive_size_output" 2>&1; then
  echo "Expected truncated archive size fixture to fail validation" >&2
  cat "$negative_artifact_archive_size_output" >&2
  exit 1
fi
grep -q "FAIL artifact archive byte count" "$negative_artifact_archive_size_output"
rm -f "$negative_artifact_archive_size_fixture" "$negative_artifact_archive_size_output"

negative_artifact_archive_zip_fixture="$artifact_archive_fixture_dir/negative-matching-digest-not-zip.zip"
negative_artifact_archive_zip_output="$(mktemp)"
printf "this payload is not a zip archive\n" > "$negative_artifact_archive_zip_fixture"
negative_artifact_archive_zip_size="$(wc -c < "$negative_artifact_archive_zip_fixture" | tr -d '[:space:]')"
negative_artifact_archive_zip_digest="$(ruby -rdigest -e 'puts "sha256:#{Digest::SHA256.file(ARGV.fetch(0)).hexdigest}"' "$negative_artifact_archive_zip_fixture")"
if ruby scripts/validate_ci_artifact.rb "$artifact_fixture" --commit fixture-sha --run-id 12345 --attempt 1 --archive "$negative_artifact_archive_zip_fixture" --archive-size "$negative_artifact_archive_zip_size" --archive-digest "$negative_artifact_archive_zip_digest" >"$negative_artifact_archive_zip_output" 2>&1; then
  echo "Expected matching digest non-ZIP fixture to fail validation" >&2
  cat "$negative_artifact_archive_zip_output" >&2
  exit 1
fi
grep -q "PASS artifact archive byte count" "$negative_artifact_archive_zip_output"
grep -q "PASS artifact archive sha256 digest" "$negative_artifact_archive_zip_output"
grep -q "FAIL artifact archive zip integrity" "$negative_artifact_archive_zip_output"
rm -f "$negative_artifact_archive_zip_fixture" "$negative_artifact_archive_zip_output"

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
negative_schedule_category_empty_state_marker_fixture="$(mktemp -d)"
negative_schedule_category_empty_state_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_schedule_category_empty_state_marker_fixture"/
python3 - "$negative_schedule_category_empty_state_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Schedule category empty state action contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_schedule_category_empty_state_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_schedule_category_empty_state_marker_output" 2>&1; then
  echo "Expected negative schedule category empty state marker fixture to fail validation" >&2
  cat "$negative_schedule_category_empty_state_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project schedule category empty state action contracts" "$negative_schedule_category_empty_state_marker_output"
rm -rf "$negative_schedule_category_empty_state_marker_fixture"
rm -f "$negative_schedule_category_empty_state_marker_output"
negative_mac_schedule_category_empty_state_marker_fixture="$(mktemp -d)"
negative_mac_schedule_category_empty_state_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_mac_schedule_category_empty_state_marker_fixture"/
python3 - "$negative_mac_schedule_category_empty_state_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Mac schedule category empty state action contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_mac_schedule_category_empty_state_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_mac_schedule_category_empty_state_marker_output" 2>&1; then
  echo "Expected negative mac schedule category empty state marker fixture to fail validation" >&2
  cat "$negative_mac_schedule_category_empty_state_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project mac schedule category empty state action contracts" "$negative_mac_schedule_category_empty_state_marker_output"
rm -rf "$negative_mac_schedule_category_empty_state_marker_fixture"
rm -f "$negative_mac_schedule_category_empty_state_marker_output"
negative_mac_calendar_range_empty_state_marker_fixture="$(mktemp -d)"
negative_mac_calendar_range_empty_state_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_mac_calendar_range_empty_state_marker_fixture"/
python3 - "$negative_mac_calendar_range_empty_state_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Mac calendar range empty state quick add contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_mac_calendar_range_empty_state_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_mac_calendar_range_empty_state_marker_output" 2>&1; then
  echo "Expected negative Mac calendar range empty state marker fixture to fail validation" >&2
  cat "$negative_mac_calendar_range_empty_state_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project mac calendar range empty state quick add contracts" "$negative_mac_calendar_range_empty_state_marker_output"
rm -rf "$negative_mac_calendar_range_empty_state_marker_fixture"
rm -f "$negative_mac_calendar_range_empty_state_marker_output"
negative_timer_category_empty_state_marker_fixture="$(mktemp -d)"
negative_timer_category_empty_state_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_timer_category_empty_state_marker_fixture"/
python3 - "$negative_timer_category_empty_state_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Timer category empty state action contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_timer_category_empty_state_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_timer_category_empty_state_marker_output" 2>&1; then
  echo "Expected negative timer category empty state marker fixture to fail validation" >&2
  cat "$negative_timer_category_empty_state_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project timer category empty state action contracts" "$negative_timer_category_empty_state_marker_output"
rm -rf "$negative_timer_category_empty_state_marker_fixture"
rm -f "$negative_timer_category_empty_state_marker_output"
negative_timer_task_queue_expansion_marker_fixture="$(mktemp -d)"
negative_timer_task_queue_expansion_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_timer_task_queue_expansion_marker_fixture"/
python3 - "$negative_timer_task_queue_expansion_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Timer task queue expansion contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_timer_task_queue_expansion_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_timer_task_queue_expansion_marker_output" 2>&1; then
  echo "Expected negative timer task queue expansion marker fixture to fail validation" >&2
  cat "$negative_timer_task_queue_expansion_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project timer task queue expansion contracts" "$negative_timer_task_queue_expansion_marker_output"
rm -rf "$negative_timer_task_queue_expansion_marker_fixture"
rm -f "$negative_timer_task_queue_expansion_marker_output"
negative_declaration_boundary_resilience_marker_fixture="$(mktemp -d)"
negative_declaration_boundary_resilience_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_declaration_boundary_resilience_marker_fixture"/
python3 - "$negative_declaration_boundary_resilience_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Declaration boundary resilience contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_declaration_boundary_resilience_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_declaration_boundary_resilience_marker_output" 2>&1; then
  echo "Expected negative declaration boundary marker fixture to fail validation" >&2
  cat "$negative_declaration_boundary_resilience_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project declaration boundary resilience contracts" "$negative_declaration_boundary_resilience_marker_output"
rm -rf "$negative_declaration_boundary_resilience_marker_fixture"
rm -f "$negative_declaration_boundary_resilience_marker_output"
negative_mac_timer_category_queue_marker_fixture="$(mktemp -d)"
negative_mac_timer_category_queue_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_mac_timer_category_queue_marker_fixture"/
python3 - "$negative_mac_timer_category_queue_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Mac timer category queue contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_mac_timer_category_queue_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_mac_timer_category_queue_marker_output" 2>&1; then
  echo "Expected negative Mac timer category queue marker fixture to fail validation" >&2
  cat "$negative_mac_timer_category_queue_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project mac timer category queue contracts" "$negative_mac_timer_category_queue_marker_output"
rm -rf "$negative_mac_timer_category_queue_marker_fixture"
rm -f "$negative_mac_timer_category_queue_marker_output"
negative_ci_action_node24_marker_fixture="$(mktemp -d)"
negative_ci_action_node24_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_ci_action_node24_marker_fixture"/
python3 - "$negative_ci_action_node24_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "CI action Node.js 24 contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_ci_action_node24_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_ci_action_node24_marker_output" 2>&1; then
  echo "Expected negative CI action Node.js 24 marker fixture to fail validation" >&2
  cat "$negative_ci_action_node24_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project ci action Node.js 24 contracts" "$negative_ci_action_node24_marker_output"
rm -rf "$negative_ci_action_node24_marker_fixture"
rm -f "$negative_ci_action_node24_marker_output"
negative_ci_failure_summary_output_marker_fixture="$(mktemp -d)"
negative_ci_failure_summary_output_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_ci_failure_summary_output_marker_fixture"/
python3 - "$negative_ci_failure_summary_output_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "CI failure summary output contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_ci_failure_summary_output_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_ci_failure_summary_output_marker_output" 2>&1; then
  echo "Expected negative CI failure summary output marker fixture to fail validation" >&2
  cat "$negative_ci_failure_summary_output_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project ci failure summary output contracts" "$negative_ci_failure_summary_output_marker_output"
rm -rf "$negative_ci_failure_summary_output_marker_fixture"
rm -f "$negative_ci_failure_summary_output_marker_output"
negative_ci_artifact_archive_integrity_marker_fixture="$(mktemp -d)"
negative_ci_artifact_archive_integrity_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_ci_artifact_archive_integrity_marker_fixture"/
python3 - "$negative_ci_artifact_archive_integrity_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "CI artifact archive integrity contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_ci_artifact_archive_integrity_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_ci_artifact_archive_integrity_marker_output" 2>&1; then
  echo "Expected negative CI artifact archive integrity marker fixture to fail validation" >&2
  cat "$negative_ci_artifact_archive_integrity_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project ci artifact archive integrity contracts" "$negative_ci_artifact_archive_integrity_marker_output"
rm -rf "$negative_ci_artifact_archive_integrity_marker_fixture"
rm -f "$negative_ci_artifact_archive_integrity_marker_output"
negative_ci_artifact_api_metadata_marker_fixture="$(mktemp -d)"
negative_ci_artifact_api_metadata_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_ci_artifact_api_metadata_marker_fixture"/
python3 - "$negative_ci_artifact_api_metadata_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "CI artifact API metadata contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_ci_artifact_api_metadata_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_ci_artifact_api_metadata_marker_output" 2>&1; then
  echo "Expected negative CI artifact API metadata marker fixture to fail validation" >&2
  cat "$negative_ci_artifact_api_metadata_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project ci artifact API metadata contracts" "$negative_ci_artifact_api_metadata_marker_output"
rm -rf "$negative_ci_artifact_api_metadata_marker_fixture"
rm -f "$negative_ci_artifact_api_metadata_marker_output"
negative_existing_category_reuse_marker_fixture="$(mktemp -d)"
negative_existing_category_reuse_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_existing_category_reuse_marker_fixture"/
python3 - "$negative_existing_category_reuse_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Existing category reuse contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb \
  "$negative_existing_category_reuse_marker_fixture" \
  --commit fixture-sha \
  --run-id 12345 \
  --attempt 1 \
  --archive "$artifact_archive_fixture" \
  --archive-size "$artifact_archive_size" \
  --archive-digest "$artifact_archive_digest" \
  --artifact-metadata "$artifact_metadata_fixture" \
  --run-metadata "$run_metadata_fixture" \
  >"$negative_existing_category_reuse_marker_output" 2>&1; then
  echo "Expected negative existing category reuse marker fixture to fail validation" >&2
  cat "$negative_existing_category_reuse_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project existing category reuse contracts" "$negative_existing_category_reuse_marker_output"
assert_archive_passes "$negative_existing_category_reuse_marker_output"
assert_artifact_metadata_passes "$negative_existing_category_reuse_marker_output"
assert_run_metadata_passes_except "$negative_existing_category_reuse_marker_output"
rm -rf "$negative_existing_category_reuse_marker_fixture"
rm -f "$negative_existing_category_reuse_marker_output"

negative_existing_category_usage_marker_fixture="$(mktemp -d)"
negative_existing_category_usage_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_existing_category_usage_marker_fixture"/
python3 - "$negative_existing_category_usage_marker_fixture" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
marker = "Existing category usage context contracts verified.\n"
source = verify_log_path.read_text(encoding="utf-8")
if source.count(marker) != 1:
    raise SystemExit("Expected exactly one existing category usage context marker")
verify_log_path.write_text(source.replace(marker, ""), encoding="utf-8")

index_path = root / "ci-artifact-index.json"
for _ in range(10):
    index = json.loads(index_path.read_text(encoding="utf-8"))
    for entry in index["entries"]:
        contract_path = entry["path"]
        prefix = "ci-results/"
        relative_path = contract_path[len(prefix):] if contract_path.startswith(prefix) else contract_path
        local_path = root / relative_path
        if entry["kind"] == "file":
            entry["byteCount"] = local_path.stat().st_size
        elif entry["kind"] == "directory":
            files = [child for child in local_path.rglob("*") if child.is_file()]
            entry["fileCount"] = len(files)
            entry["recursiveByteCount"] = sum(child.stat().st_size for child in files)
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
    encoded = json.dumps(index, ensure_ascii=False, indent=2) + "\n"
    if encoded == index_path.read_text(encoding="utf-8"):
        break
    index_path.write_text(encoded, encoding="utf-8")
else:
    raise SystemExit("Existing category usage marker fixture index did not stabilize")
PY
if ruby scripts/validate_ci_artifact.rb \
  "$negative_existing_category_usage_marker_fixture" \
  --commit fixture-sha \
  --run-id 12345 \
  --attempt 1 \
  --archive "$artifact_archive_fixture" \
  --archive-size "$artifact_archive_size" \
  --archive-digest "$artifact_archive_digest" \
  --artifact-metadata "$artifact_metadata_fixture" \
  --run-metadata "$run_metadata_fixture" \
  >"$negative_existing_category_usage_marker_output" 2>&1; then
  echo "Expected negative existing category usage context marker fixture to fail validation" >&2
  cat "$negative_existing_category_usage_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project existing category usage context contracts" "$negative_existing_category_usage_marker_output"
grep -q "PASS verify_project existing category reuse contracts" "$negative_existing_category_usage_marker_output"
assert_archive_passes "$negative_existing_category_usage_marker_output"
assert_artifact_metadata_passes "$negative_existing_category_usage_marker_output"
assert_run_metadata_passes_except "$negative_existing_category_usage_marker_output"
if [[ "$(grep -c '^FAIL ' "$negative_existing_category_usage_marker_output")" -ne 1 ]]; then
  echo "Expected only the existing category usage context contract to fail" >&2
  cat "$negative_existing_category_usage_marker_output" >&2
  exit 1
fi
rm -rf "$negative_existing_category_usage_marker_fixture"
rm -f "$negative_existing_category_usage_marker_output"

negative_existing_category_search_marker_fixture="$(mktemp -d)"
negative_existing_category_search_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_existing_category_search_marker_fixture"/
python3 - "$negative_existing_category_search_marker_fixture" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
marker = "Existing category search contracts verified.\n"
source = verify_log_path.read_text(encoding="utf-8")
if source.count(marker) != 1:
    raise SystemExit("Expected exactly one existing category search marker")
verify_log_path.write_text(source.replace(marker, ""), encoding="utf-8")

index_path = root / "ci-artifact-index.json"
for _ in range(10):
    index = json.loads(index_path.read_text(encoding="utf-8"))
    for entry in index["entries"]:
        contract_path = entry["path"]
        prefix = "ci-results/"
        relative_path = contract_path[len(prefix):] if contract_path.startswith(prefix) else contract_path
        local_path = root / relative_path
        if entry["kind"] == "file":
            entry["byteCount"] = local_path.stat().st_size
        elif entry["kind"] == "directory":
            files = [child for child in local_path.rglob("*") if child.is_file()]
            entry["fileCount"] = len(files)
            entry["recursiveByteCount"] = sum(child.stat().st_size for child in files)
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
    encoded = json.dumps(index, ensure_ascii=False, indent=2) + "\n"
    if encoded == index_path.read_text(encoding="utf-8"):
        break
    index_path.write_text(encoded, encoding="utf-8")
else:
    raise SystemExit("Existing category search marker fixture index did not stabilize")
PY
if ruby scripts/validate_ci_artifact.rb \
  "$negative_existing_category_search_marker_fixture" \
  --commit fixture-sha \
  --run-id 12345 \
  --attempt 1 \
  --archive "$artifact_archive_fixture" \
  --archive-size "$artifact_archive_size" \
  --archive-digest "$artifact_archive_digest" \
  --artifact-metadata "$artifact_metadata_fixture" \
  --run-metadata "$run_metadata_fixture" \
  >"$negative_existing_category_search_marker_output" 2>&1; then
  echo "Expected negative existing category search marker fixture to fail validation" >&2
  cat "$negative_existing_category_search_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project existing category search contracts" "$negative_existing_category_search_marker_output"
assert_archive_passes "$negative_existing_category_search_marker_output"
assert_artifact_metadata_passes "$negative_existing_category_search_marker_output"
assert_run_metadata_passes_except "$negative_existing_category_search_marker_output"
if [[ "$(grep -c '^FAIL ' "$negative_existing_category_search_marker_output")" -ne 1 ]]; then
  echo "Expected only the existing category search contract to fail" >&2
  cat "$negative_existing_category_search_marker_output" >&2
  exit 1
fi
rm -rf "$negative_existing_category_search_marker_fixture"
rm -f "$negative_existing_category_search_marker_output"

negative_schedule_timer_handoff_marker_fixture="$(mktemp -d)"
negative_schedule_timer_handoff_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_schedule_timer_handoff_marker_fixture"/
python3 - "$negative_schedule_timer_handoff_marker_fixture" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
marker = "Schedule to timer handoff contracts verified.\n"
source = verify_log_path.read_text(encoding="utf-8")
if source.count(marker) != 1:
    raise SystemExit("Expected exactly one schedule to timer handoff marker")
verify_log_path.write_text(source.replace(marker, ""), encoding="utf-8")

index_path = root / "ci-artifact-index.json"
for _ in range(10):
    index = json.loads(index_path.read_text(encoding="utf-8"))
    for entry in index["entries"]:
        contract_path = entry["path"]
        prefix = "ci-results/"
        relative_path = contract_path[len(prefix):] if contract_path.startswith(prefix) else contract_path
        local_path = root / relative_path
        if entry["kind"] == "file":
            entry["byteCount"] = local_path.stat().st_size
        elif entry["kind"] == "directory":
            files = [child for child in local_path.rglob("*") if child.is_file()]
            entry["fileCount"] = len(files)
            entry["recursiveByteCount"] = sum(child.stat().st_size for child in files)
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
    encoded = json.dumps(index, ensure_ascii=False, indent=2) + "\n"
    if encoded == index_path.read_text(encoding="utf-8"):
        break
    index_path.write_text(encoded, encoding="utf-8")
else:
    raise SystemExit("Schedule to timer handoff marker fixture index did not stabilize")
PY
if ruby scripts/validate_ci_artifact.rb \
  "$negative_schedule_timer_handoff_marker_fixture" \
  --commit fixture-sha \
  --run-id 12345 \
  --attempt 1 \
  --archive "$artifact_archive_fixture" \
  --archive-size "$artifact_archive_size" \
  --archive-digest "$artifact_archive_digest" \
  --artifact-metadata "$artifact_metadata_fixture" \
  --run-metadata "$run_metadata_fixture" \
  >"$negative_schedule_timer_handoff_marker_output" 2>&1; then
  echo "Expected negative schedule to timer handoff marker fixture to fail validation" >&2
  cat "$negative_schedule_timer_handoff_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project schedule to timer handoff contracts" "$negative_schedule_timer_handoff_marker_output"
grep -q "PASS verify_project existing category search contracts" "$negative_schedule_timer_handoff_marker_output"
assert_archive_passes "$negative_schedule_timer_handoff_marker_output"
assert_artifact_metadata_passes "$negative_schedule_timer_handoff_marker_output"
assert_run_metadata_passes_except "$negative_schedule_timer_handoff_marker_output"
if [[ "$(grep -c '^FAIL ' "$negative_schedule_timer_handoff_marker_output")" -ne 1 ]]; then
  echo "Expected only the schedule to timer handoff contract to fail" >&2
  cat "$negative_schedule_timer_handoff_marker_output" >&2
  exit 1
fi
rm -rf "$negative_schedule_timer_handoff_marker_fixture"
rm -f "$negative_schedule_timer_handoff_marker_output"

negative_ci_workflow_run_api_metadata_marker_fixture="$(mktemp -d)"
negative_ci_workflow_run_api_metadata_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_ci_workflow_run_api_metadata_marker_fixture"/
python3 - "$negative_ci_workflow_run_api_metadata_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "CI workflow run API metadata contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb \
  "$negative_ci_workflow_run_api_metadata_marker_fixture" \
  --commit fixture-sha \
  --run-id 12345 \
  --attempt 1 \
  --archive "$artifact_archive_fixture" \
  --archive-size "$artifact_archive_size" \
  --archive-digest "$artifact_archive_digest" \
  --artifact-metadata "$artifact_metadata_fixture" \
  --run-metadata "$run_metadata_fixture" \
  >"$negative_ci_workflow_run_api_metadata_marker_output" 2>&1; then
  echo "Expected negative CI workflow run API metadata marker fixture to fail validation" >&2
  cat "$negative_ci_workflow_run_api_metadata_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project ci workflow run API metadata contracts" "$negative_ci_workflow_run_api_metadata_marker_output"
assert_archive_passes "$negative_ci_workflow_run_api_metadata_marker_output"
assert_artifact_metadata_passes "$negative_ci_workflow_run_api_metadata_marker_output"
assert_run_metadata_passes_except "$negative_ci_workflow_run_api_metadata_marker_output"
rm -rf "$negative_ci_workflow_run_api_metadata_marker_fixture"
rm -f "$negative_ci_workflow_run_api_metadata_marker_output"

negative_ci_workflow_run_provenance_marker_fixture="$(mktemp -d)"
negative_ci_workflow_run_provenance_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_ci_workflow_run_provenance_marker_fixture"/
python3 - "$negative_ci_workflow_run_provenance_marker_fixture" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
marker = "CI workflow run provenance contracts verified.\n"
source = verify_log_path.read_text(encoding="utf-8")
if source.count(marker) != 1:
    raise SystemExit("Expected exactly one CI workflow run provenance marker")
verify_log_path.write_text(source.replace(marker, ""), encoding="utf-8")

index_path = root / "ci-artifact-index.json"
for _ in range(10):
    index = json.loads(index_path.read_text(encoding="utf-8"))
    for entry in index["entries"]:
        contract_path = entry["path"]
        prefix = "ci-results/"
        relative_path = contract_path[len(prefix):] if contract_path.startswith(prefix) else contract_path
        local_path = root / relative_path
        if entry["kind"] == "file":
            entry["byteCount"] = local_path.stat().st_size
        elif entry["kind"] == "directory":
            files = [child for child in local_path.rglob("*") if child.is_file()]
            entry["fileCount"] = len(files)
            entry["recursiveByteCount"] = sum(child.stat().st_size for child in files)
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
    encoded = json.dumps(index, ensure_ascii=False, indent=2) + "\n"
    if encoded == index_path.read_text(encoding="utf-8"):
        break
    index_path.write_text(encoded, encoding="utf-8")
else:
    raise SystemExit("CI workflow run provenance marker fixture index did not stabilize")
PY
if ruby scripts/validate_ci_artifact.rb \
  "$negative_ci_workflow_run_provenance_marker_fixture" \
  --commit fixture-sha \
  --run-id 12345 \
  --attempt 1 \
  --archive "$artifact_archive_fixture" \
  --archive-size "$artifact_archive_size" \
  --archive-digest "$artifact_archive_digest" \
  --artifact-metadata "$artifact_metadata_fixture" \
  --run-metadata "$run_metadata_fixture" \
  >"$negative_ci_workflow_run_provenance_marker_output" 2>&1; then
  echo "Expected negative CI workflow run provenance marker fixture to fail validation" >&2
  cat "$negative_ci_workflow_run_provenance_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project ci workflow run provenance contracts" "$negative_ci_workflow_run_provenance_marker_output"
assert_archive_passes "$negative_ci_workflow_run_provenance_marker_output"
assert_artifact_metadata_passes "$negative_ci_workflow_run_provenance_marker_output"
assert_run_metadata_passes_except "$negative_ci_workflow_run_provenance_marker_output"
if [[ "$(grep -c '^FAIL ' "$negative_ci_workflow_run_provenance_marker_output")" -ne 1 ]]; then
  echo "Expected only the CI workflow run provenance contract to fail" >&2
  cat "$negative_ci_workflow_run_provenance_marker_output" >&2
  exit 1
fi
rm -rf "$negative_ci_workflow_run_provenance_marker_fixture"
rm -f "$negative_ci_workflow_run_provenance_marker_output"
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
negative_mac_quick_add_title_context_marker_fixture="$(mktemp -d)"
negative_mac_quick_add_title_context_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_mac_quick_add_title_context_marker_fixture"/
python3 - "$negative_mac_quick_add_title_context_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Mac quick add title field category context contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_mac_quick_add_title_context_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_mac_quick_add_title_context_marker_output" 2>&1; then
  echo "Expected negative Mac quick add title field category context marker fixture to fail validation" >&2
  cat "$negative_mac_quick_add_title_context_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project mac quick add title field category context contracts" "$negative_mac_quick_add_title_context_marker_output"
rm -rf "$negative_mac_quick_add_title_context_marker_fixture"
rm -f "$negative_mac_quick_add_title_context_marker_output"
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
negative_task_editor_save_marker_fixture="$(mktemp -d)"
negative_task_editor_save_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_task_editor_save_marker_fixture"/
python3 - "$negative_task_editor_save_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Task editor save category accessibility contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_task_editor_save_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_task_editor_save_marker_output" 2>&1; then
  echo "Expected negative task editor save marker fixture to fail validation" >&2
  cat "$negative_task_editor_save_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project task editor save category accessibility contracts" "$negative_task_editor_save_marker_output"
rm -rf "$negative_task_editor_save_marker_fixture"
rm -f "$negative_task_editor_save_marker_output"
negative_task_editor_cancel_marker_fixture="$(mktemp -d)"
negative_task_editor_cancel_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_task_editor_cancel_marker_fixture"/
python3 - "$negative_task_editor_cancel_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Task editor cancel category accessibility contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_task_editor_cancel_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_task_editor_cancel_marker_output" 2>&1; then
  echo "Expected negative task editor cancel marker fixture to fail validation" >&2
  cat "$negative_task_editor_cancel_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project task editor cancel category accessibility contracts" "$negative_task_editor_cancel_marker_output"
rm -rf "$negative_task_editor_cancel_marker_fixture"
rm -f "$negative_task_editor_cancel_marker_output"
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
negative_analytics_category_share_session_count_marker_fixture="$(mktemp -d)"
negative_analytics_category_share_session_count_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_analytics_category_share_session_count_marker_fixture"/
python3 - "$negative_analytics_category_share_session_count_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Analytics category share session count contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_analytics_category_share_session_count_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_analytics_category_share_session_count_marker_output" 2>&1; then
  echo "Expected negative analytics category share session count marker fixture to fail validation" >&2
  cat "$negative_analytics_category_share_session_count_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project analytics category share session count contracts" "$negative_analytics_category_share_session_count_marker_output"
rm -rf "$negative_analytics_category_share_session_count_marker_fixture"
rm -f "$negative_analytics_category_share_session_count_marker_output"
negative_analytics_category_share_ranking_marker_fixture="$(mktemp -d)"
negative_analytics_category_share_ranking_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_analytics_category_share_ranking_marker_fixture"/
python3 - "$negative_analytics_category_share_ranking_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Analytics category share ranking contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_analytics_category_share_ranking_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_analytics_category_share_ranking_marker_output" 2>&1; then
  echo "Expected negative analytics category share ranking marker fixture to fail validation" >&2
  cat "$negative_analytics_category_share_ranking_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project analytics category share ranking contracts" "$negative_analytics_category_share_ranking_marker_output"
rm -rf "$negative_analytics_category_share_ranking_marker_fixture"
rm -f "$negative_analytics_category_share_ranking_marker_output"
negative_analytics_category_share_sort_context_marker_fixture="$(mktemp -d)"
negative_analytics_category_share_sort_context_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_analytics_category_share_sort_context_marker_fixture"/
python3 - "$negative_analytics_category_share_sort_context_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Analytics category share sort context contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_analytics_category_share_sort_context_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_analytics_category_share_sort_context_marker_output" 2>&1; then
  echo "Expected negative analytics category share sort context marker fixture to fail validation" >&2
  cat "$negative_analytics_category_share_sort_context_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project analytics category share sort context contracts" "$negative_analytics_category_share_sort_context_marker_output"
rm -rf "$negative_analytics_category_share_sort_context_marker_fixture"
rm -f "$negative_analytics_category_share_sort_context_marker_output"
negative_analytics_category_share_empty_state_marker_fixture="$(mktemp -d)"
negative_analytics_category_share_empty_state_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_analytics_category_share_empty_state_marker_fixture"/
python3 - "$negative_analytics_category_share_empty_state_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Analytics category share empty state contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_analytics_category_share_empty_state_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_analytics_category_share_empty_state_marker_output" 2>&1; then
  echo "Expected negative analytics category share empty state marker fixture to fail validation" >&2
  cat "$negative_analytics_category_share_empty_state_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project analytics category share empty state contracts" "$negative_analytics_category_share_empty_state_marker_output"
rm -rf "$negative_analytics_category_share_empty_state_marker_fixture"
rm -f "$negative_analytics_category_share_empty_state_marker_output"
negative_analytics_category_share_metadata_readability_marker_fixture="$(mktemp -d)"
negative_analytics_category_share_metadata_readability_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_analytics_category_share_metadata_readability_marker_fixture"/
python3 - "$negative_analytics_category_share_metadata_readability_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Analytics category share metadata readability contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_analytics_category_share_metadata_readability_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_analytics_category_share_metadata_readability_marker_output" 2>&1; then
  echo "Expected negative analytics category share metadata readability marker fixture to fail validation" >&2
  cat "$negative_analytics_category_share_metadata_readability_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project analytics category share metadata readability contracts" "$negative_analytics_category_share_metadata_readability_marker_output"
rm -rf "$negative_analytics_category_share_metadata_readability_marker_fixture"
rm -f "$negative_analytics_category_share_metadata_readability_marker_output"
negative_analytics_category_share_percent_readability_marker_fixture="$(mktemp -d)"
negative_analytics_category_share_percent_readability_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_analytics_category_share_percent_readability_marker_fixture"/
python3 - "$negative_analytics_category_share_percent_readability_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Analytics category share percent readability contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_analytics_category_share_percent_readability_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_analytics_category_share_percent_readability_marker_output" 2>&1; then
  echo "Expected negative analytics category share percent readability marker fixture to fail validation" >&2
  cat "$negative_analytics_category_share_percent_readability_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project analytics category share percent readability contracts" "$negative_analytics_category_share_percent_readability_marker_output"
rm -rf "$negative_analytics_category_share_percent_readability_marker_fixture"
rm -f "$negative_analytics_category_share_percent_readability_marker_output"
negative_analytics_recent_session_marker_fixture="$(mktemp -d)"
negative_analytics_recent_session_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_analytics_recent_session_marker_fixture"/
python3 - "$negative_analytics_recent_session_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Analytics recent session category contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_analytics_recent_session_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_analytics_recent_session_marker_output" 2>&1; then
  echo "Expected negative analytics recent session marker fixture to fail validation" >&2
  cat "$negative_analytics_recent_session_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project analytics recent session category contracts" "$negative_analytics_recent_session_marker_output"
rm -rf "$negative_analytics_recent_session_marker_fixture"
rm -f "$negative_analytics_recent_session_marker_output"
negative_analytics_plan_review_marker_fixture="$(mktemp -d)"
negative_analytics_plan_review_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_analytics_plan_review_marker_fixture"/
python3 - "$negative_analytics_plan_review_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Analytics plan review category accessibility contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_analytics_plan_review_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_analytics_plan_review_marker_output" 2>&1; then
  echo "Expected negative analytics plan review marker fixture to fail validation" >&2
  cat "$negative_analytics_plan_review_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project analytics plan review category accessibility contracts" "$negative_analytics_plan_review_marker_output"
rm -rf "$negative_analytics_plan_review_marker_fixture"
rm -f "$negative_analytics_plan_review_marker_output"
negative_category_filter_toggle_marker_fixture="$(mktemp -d)"
negative_category_filter_toggle_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_category_filter_toggle_marker_fixture"/
python3 - "$negative_category_filter_toggle_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Category filter toggle contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_category_filter_toggle_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_category_filter_toggle_marker_output" 2>&1; then
  echo "Expected negative category filter toggle marker fixture to fail validation" >&2
  cat "$negative_category_filter_toggle_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project category filter toggle contracts" "$negative_category_filter_toggle_marker_output"
rm -rf "$negative_category_filter_toggle_marker_fixture"
rm -f "$negative_category_filter_toggle_marker_output"
negative_current_task_selection_marker_fixture="$(mktemp -d)"
negative_current_task_selection_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_current_task_selection_marker_fixture"/
python3 - "$negative_current_task_selection_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Current task selection accessibility contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_current_task_selection_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_current_task_selection_marker_output" 2>&1; then
  echo "Expected negative current task selection marker fixture to fail validation" >&2
  cat "$negative_current_task_selection_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project current task selection accessibility contracts" "$negative_current_task_selection_marker_output"
rm -rf "$negative_current_task_selection_marker_fixture"
rm -f "$negative_current_task_selection_marker_output"
negative_timer_action_marker_fixture="$(mktemp -d)"
negative_timer_action_marker_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_timer_action_marker_fixture"/
python3 - "$negative_timer_action_marker_fixture" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
verify_log_path = root / "verify_project.log"
verify_log_path.write_text(
    verify_log_path.read_text(encoding="utf-8").replace(
        "Timer action accessibility contracts verified.\n",
        "",
    ),
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_timer_action_marker_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_timer_action_marker_output" 2>&1; then
  echo "Expected negative timer action marker fixture to fail validation" >&2
  cat "$negative_timer_action_marker_output" >&2
  exit 1
fi
grep -q "FAIL verify_project timer action accessibility contracts" "$negative_timer_action_marker_output"
rm -rf "$negative_timer_action_marker_fixture"
rm -f "$negative_timer_action_marker_output"
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
negative_manifest_overall_outcome_fixture="$(mktemp -d)"
negative_manifest_overall_outcome_output="$(mktemp)"
cp -R "$artifact_fixture"/. "$negative_manifest_overall_outcome_fixture"/
python3 - "$negative_manifest_overall_outcome_fixture" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
manifest_path = root / "ci-artifact-manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
manifest["overallOutcome"] = "failure"
manifest_path.write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
PY
if ruby scripts/validate_ci_artifact.rb "$negative_manifest_overall_outcome_fixture" --commit fixture-sha --run-id 12345 --attempt 1 >"$negative_manifest_overall_outcome_output" 2>&1; then
  echo "Expected negative manifest overall outcome fixture to fail validation" >&2
  cat "$negative_manifest_overall_outcome_output" >&2
  exit 1
fi
grep -q "FAIL manifest overall outcome" "$negative_manifest_overall_outcome_output"
rm -rf "$negative_manifest_overall_outcome_fixture"
rm -f "$negative_manifest_overall_outcome_output"
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
rm -rf "$artifact_archive_fixture_dir"
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
simulator_build_command="$(ruby scripts/resolve_ios_simulator_destination.rb --simctl-json "$simctl_fixture" --print-build-command)"
grep -Fq -- "xcodebuild -project ChronoFocus.xcodeproj" <<< "$simulator_build_command"
grep -Fq -- "22222222-2222-2222-2222-222222222222" <<< "$simulator_build_command"
rm -f "$simctl_fixture"
grep -q "IOS_SCHEME: ChronoFocus" .github/workflows/ci-results.yml
grep -q "generic/platform=iOS" .github/workflows/ci-results.yml
ruby -e 'source = File.read(".github/workflows/ci-results.yml"); index_source = source[/index = \{[\s\S]*?"entries": entries,/]; raise "workflow artifact index source missing" unless index_source; raise "workflow artifact index artifactName missing" unless index_source.include?("\"artifactName\": os.environ[\"ARTIFACT_NAME\"]")'
grep -q "errors=\"0\"" .github/workflows/ci-results.yml
grep -q "iosBuildOutcome" .github/workflows/ci-results.yml
grep -q "overallOutcome" .github/workflows/ci-results.yml
grep -q "Overall outcome" .github/workflows/ci-results.yml
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

verify_ci_action_versions .github/workflows/ci-results.yml
verify_ci_failure_summary_output .github/workflows/ci-results.yml

checkout_v4_workflow_fixture="$(mktemp)"
checkout_v4_workflow_output="$(mktemp)"
cp .github/workflows/ci-results.yml "$checkout_v4_workflow_fixture"
ruby -e 'path = ARGV.fetch(0); source = File.read(path); updated = source.sub("actions/checkout@v5", "actions/checkout@v4"); raise "checkout fixture replacement missing" if updated == source; File.write(path, updated)' "$checkout_v4_workflow_fixture"
if verify_ci_action_versions "$checkout_v4_workflow_fixture" >"$checkout_v4_workflow_output" 2>&1; then
  echo "Expected actions/checkout@v4 workflow fixture to fail validation" >&2
  exit 1
fi
grep -q "Expected exactly one actions/checkout@v5 declaration" "$checkout_v4_workflow_output"
rm -f "$checkout_v4_workflow_fixture" "$checkout_v4_workflow_output"

upload_v4_workflow_fixture="$(mktemp)"
upload_v4_workflow_output="$(mktemp)"
cp .github/workflows/ci-results.yml "$upload_v4_workflow_fixture"
ruby -e 'path = ARGV.fetch(0); source = File.read(path); updated = source.sub("actions/upload-artifact@v6", "actions/upload-artifact@v4"); raise "upload fixture replacement missing" if updated == source; File.write(path, updated)' "$upload_v4_workflow_fixture"
if verify_ci_action_versions "$upload_v4_workflow_fixture" >"$upload_v4_workflow_output" 2>&1; then
  echo "Expected actions/upload-artifact@v4 workflow fixture to fail validation" >&2
  exit 1
fi
grep -q "Expected exactly one actions/upload-artifact@v6 declaration" "$upload_v4_workflow_output"
rm -f "$upload_v4_workflow_fixture" "$upload_v4_workflow_output"

ci_failure_summary_cat_workflow_fixture="$(mktemp)"
ci_failure_summary_cat_workflow_output="$(mktemp)"
cp .github/workflows/ci-results.yml "$ci_failure_summary_cat_workflow_fixture"
ruby -e 'path = ARGV.fetch(0); source = File.read(path); tee_line = %q{tee -a "$GITHUB_STEP_SUMMARY" < ci-results/ci-failure-summary.md}; cat_line = %q{cat ci-results/ci-failure-summary.md >> "$GITHUB_STEP_SUMMARY"}; updated = source.sub(tee_line, cat_line); raise "CI failure summary cat fixture replacement missing" if updated == source; File.write(path, updated)' "$ci_failure_summary_cat_workflow_fixture"
if verify_ci_failure_summary_output "$ci_failure_summary_cat_workflow_fixture" >"$ci_failure_summary_cat_workflow_output" 2>&1; then
  echo "Expected cat-only CI failure summary workflow fixture to fail validation" >&2
  exit 1
fi
grep -q "Final CI status must tee failure summary to stdout and GITHUB_STEP_SUMMARY" "$ci_failure_summary_cat_workflow_output"
rm -f "$ci_failure_summary_cat_workflow_fixture" "$ci_failure_summary_cat_workflow_output"

echo "CI action Node.js 24 contracts verified."
echo "CI failure summary output contracts verified."
echo "CI artifact archive integrity contracts verified."
echo "CI artifact API metadata contracts verified."
echo "CI workflow run API metadata contracts verified."
echo "CI workflow run provenance contracts verified."

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
test -s /tmp/chronofocus-mac-timer-normal-queue.png
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
