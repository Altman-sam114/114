#!/usr/bin/env bash
# Actions-only entry point, shared by production verification and UI evidence.
set -euo pipefail

xcrun --sdk macosx swiftc \
  -module-cache-path /tmp/chrono_focus_mac_snapshot_module_cache \
  ChronoFocus/Models/AppModels.swift \
  ChronoFocus/Services/FocusStore.swift \
  ChronoFocus/Services/TimerEngine.swift \
  ChronoFocus/Services/TimerPlatformServices.swift \
  Shared/SharedExtensions.swift \
  Shared/CalendarReadAccess.swift \
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
