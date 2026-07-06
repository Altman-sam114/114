import SwiftUI

struct MacAnalyticsDetailView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var premium: MacPremiumAccessService
    @State private var reportRange: ReportRange = .week

    private let calendar = Calendar.current

    private var analysis: WorkloadAnalysis {
        store.workloadAnalysis()
    }

    private var dailyGoalProgress: Double {
        min(1, Double(store.todayFocusSeconds) / Double(max(store.settings.dailyGoalSeconds, 1)))
    }

    private var maxDailySeconds: Int {
        max(store.weekBuckets().map(\.focusSeconds).max() ?? 1, 1)
    }

    private var reportBuckets: [MacReportBucket] {
        let now = Date()
        switch reportRange {
        case .day:
            return (0..<7).reversed().compactMap { offset in
                guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: now)) else { return nil }
                return MacReportBucket(label: day.shortWeekdayText, seconds: store.focusSeconds(on: day))
            }
        case .week:
            return (0..<6).reversed().compactMap { offset in
                guard
                    let date = calendar.date(byAdding: .weekOfYear, value: -offset, to: now),
                    let interval = calendar.dateInterval(of: .weekOfYear, for: date)
                else { return nil }
                let seconds = store.sessions
                    .filter { $0.mode == .focus && $0.completed && interval.contains($0.startedAt) }
                    .reduce(0) { $0 + $1.actualSeconds }
                return MacReportBucket(label: "W\(calendar.component(.weekOfYear, from: date))", seconds: seconds)
            }
        case .month:
            return (0..<6).reversed().compactMap { offset in
                guard
                    let date = calendar.date(byAdding: .month, value: -offset, to: now),
                    let interval = calendar.dateInterval(of: .month, for: date)
                else { return nil }
                let seconds = store.sessions
                    .filter { $0.mode == .focus && $0.completed && interval.contains($0.startedAt) }
                    .reduce(0) { $0 + $1.actualSeconds }
                return MacReportBucket(label: "\(calendar.component(.month, from: date))月", seconds: seconds)
            }
        }
    }

    private var maxReportSeconds: Int {
        max(reportBuckets.map(\.seconds).max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            MacPageHeaderView(
                title: "统计复盘",
                subtitle: premium.isProUnlocked ? "完整工作复盘、分类投入和任务安排分析已解锁。" : "基础概览可用，Pro 解锁完整报表和工作分析。",
                symbolName: "chart.xyaxis.line"
            )

            MacAnalyticsSummaryGridView(analysis: analysis)
            MacDailyGoalPanelView(dailyGoalProgress: dailyGoalProgress)

            if premium.isProUnlocked {
                MacReportPanelView(
                    reportRange: $reportRange,
                    reportBuckets: reportBuckets,
                    maxReportSeconds: maxReportSeconds
                )
                HStack(alignment: .top, spacing: 18) {
                    MacWorkloadPanelView(analysis: analysis)
                    MacPlanCoveragePanelView(analysis: analysis)
                }
                HStack(alignment: .top, spacing: 18) {
                    MacWeeklyChartPanelView(maxDailySeconds: maxDailySeconds)
                    MacCategoryChartPanelView()
                }
                MacRecentSessionsPanelView()
            } else {
                MacProPreviewPanelView(analysis: analysis)
            }
        }
        .padding(24)
        .task {
            await premium.refreshEntitlements()
        }
    }
}

private struct MacAnalyticsSummaryGridView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var premium: MacPremiumAccessService

    let analysis: WorkloadAnalysis

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 14)], spacing: 14) {
            MacMetricView(title: "今日专注", value: store.todayFocusSeconds.hourMinuteText, tint: .cyan)
            MacMetricView(title: "本周专注", value: store.weekFocusSeconds.hourMinuteText, tint: .mint)
            MacMetricView(title: "累计轮数", value: "\(store.completedFocusRounds)", tint: .orange)
            MacMetricView(
                title: premium.isProUnlocked ? "压力等级" : "Pro 统计",
                value: premium.isProUnlocked ? analysis.pressureLevel : "体验",
                tint: .purple
            )
        }
    }
}

private struct MacDailyGoalPanelView: View {
    @EnvironmentObject private var store: FocusStore

    let dailyGoalProgress: Double

    var body: some View {
        MacGlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("今日目标", systemImage: "target")
                        .font(.headline)
                        .foregroundStyle(MacTheme.primaryText)
                    Spacer()
                    Text("\(Int(dailyGoalProgress * 100))%")
                        .font(.title2.bold())
                        .monospacedDigit()
                        .foregroundStyle(.cyan)
                }

                MacLinearProgressView(value: dailyGoalProgress, tint: .cyan, height: 10)

                HStack {
                    Text(store.todayFocusSeconds.hourMinuteText)
                        .font(.subheadline.bold())
                        .foregroundStyle(MacTheme.primaryText)
                    Spacer()
                    Text("目标 \(store.settings.dailyGoalSeconds.hourMinuteText)")
                        .font(.caption)
                        .foregroundStyle(MacTheme.secondaryText)
                }
            }
        }
    }
}

private struct MacProPreviewPanelView: View {
    @EnvironmentObject private var premium: MacPremiumAccessService
    @Environment(\.macSnapshotRendering) private var isSnapshotRendering

    let analysis: WorkloadAnalysis

    var body: some View {
        MacGlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Pro 工作分析", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundStyle(MacTheme.primaryText)
                    Spacer()
                    Text(premium.priceText)
                        .font(.caption.bold())
                        .foregroundStyle(.cyan)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                    MacLockedInsightView(title: "待安排轮次", value: "\(analysis.remainingRounds)", symbol: "square.stack.3d.up.fill", tint: .cyan)
                    MacLockedInsightView(title: "今日到期", value: "\(analysis.dueTodayTasks)", symbol: "calendar.badge.exclamationmark", tint: .orange)
                    MacLockedInsightView(title: "计划覆盖", value: "\(Int(analysis.planCoverage * 100))%", symbol: "chart.bar.xaxis", tint: .mint)
                }

                HStack(spacing: 10) {
                    if isSnapshotRendering {
                        MacStaticAnalyticsActionChipView(title: "解锁 Pro", symbolName: "sparkles", tint: .cyan, isProminent: true)
                        MacStaticAnalyticsActionChipView(title: "恢复购买", symbolName: "arrow.clockwise", tint: MacTheme.secondaryText, isProminent: false)
                    } else {
                        Button("解锁 Pro", systemImage: "sparkles") {
                            Task { await premium.purchasePro() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                        .disabled(premium.isLoading)

                        Button("恢复购买", systemImage: "arrow.clockwise") {
                            Task { await premium.restorePurchases() }
                        }
                        .buttonStyle(.bordered)
                        .disabled(premium.isLoading)
                    }
                }

                Text(premium.statusText)
                    .font(.caption)
                    .foregroundStyle(MacTheme.secondaryText)
            }
        }
    }
}

private struct MacStaticAnalyticsActionChipView: View {
    let title: String
    let symbolName: String
    let tint: Color
    let isProminent: Bool

    var body: some View {
        Label(title, systemImage: symbolName)
            .font(.subheadline.bold())
            .foregroundStyle(isProminent ? Color.black.opacity(0.82) : tint)
            .frame(minHeight: 30)
            .padding(.horizontal, 10)
            .background(isProminent ? tint : Color.white.opacity(0.07), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isProminent ? tint.opacity(0.9) : MacTheme.border, lineWidth: 1)
            }
            .accessibilityLabel(title)
    }
}

private struct MacReportPanelView: View {
    @Environment(\.macSnapshotRendering) private var isSnapshotRendering

    @Binding var reportRange: ReportRange
    let reportBuckets: [MacReportBucket]
    let maxReportSeconds: Int

    var body: some View {
        MacGlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Label("工作复盘报表", systemImage: "chart.xyaxis.line")
                            .font(.headline)
                            .foregroundStyle(MacTheme.primaryText)
                        Text("适合回顾近期做了什么，快速整理日报、周报和月度复盘。")
                            .font(.caption)
                            .foregroundStyle(MacTheme.secondaryText)
                    }
                    Spacer()
                    if isSnapshotRendering {
                        MacStaticSegmentedView(
                            title: "范围",
                            selectedTitle: reportRange.title,
                            options: ReportRange.allCases.map(\.title)
                        )
                    } else {
                        Picker("范围", selection: $reportRange) {
                            ForEach(ReportRange.allCases) { range in
                                Text(range.title).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                    }
                }

                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(reportBuckets) { bucket in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom))
                                .frame(height: max(10, CGFloat(bucket.seconds) / CGFloat(maxReportSeconds) * 150))
                            Text(bucket.label)
                                .font(.caption)
                                .foregroundStyle(MacTheme.secondaryText)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 188)
            }
        }
    }
}

private struct MacWorkloadPanelView: View {
    let analysis: WorkloadAnalysis

    var body: some View {
        MacGlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("工作任务安排", systemImage: "brain.head.profile")
                        .font(.headline)
                        .foregroundStyle(MacTheme.primaryText)
                    Spacer()
                    Text("压力 \(analysis.pressureLevel)")
                        .font(.caption.bold())
                        .foregroundStyle(pressureTint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(pressureTint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    MacAnalysisTileView(title: "待办任务", value: "\(analysis.pendingTasks)", symbol: "checklist.unchecked", tint: .cyan)
                    MacAnalysisTileView(title: "剩余轮次", value: "\(analysis.remainingRounds)", symbol: "timer", tint: .mint)
                    MacAnalysisTileView(title: "今日到期", value: "\(analysis.dueTodayTasks)", symbol: "calendar.badge.clock", tint: .orange)
                    MacAnalysisTileView(title: "已逾期", value: "\(analysis.overdueTasks)", symbol: "exclamationmark.triangle.fill", tint: .red)
                }

                LabeledContent("预估专注") {
                    Text(analysis.estimatedFocusSeconds.hourMinuteText)
                        .font(.subheadline.bold())
                        .foregroundStyle(MacTheme.primaryText)
                }
                .foregroundStyle(MacTheme.secondaryText)

                Text(analysis.recommendation)
                    .font(.subheadline)
                    .foregroundStyle(MacTheme.secondaryText)
            }
        }
    }

    private var pressureTint: Color {
        switch analysis.pressureLevel {
        case "高": return .red
        case "中": return .orange
        default: return .mint
        }
    }
}

private struct MacPlanCoveragePanelView: View {
    let analysis: WorkloadAnalysis

    var body: some View {
        MacGlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("番茄钟计划覆盖", systemImage: "chart.bar.doc.horizontal")
                        .font(.headline)
                        .foregroundStyle(MacTheme.primaryText)
                    Spacer()
                    Text("\(Int(analysis.planCoverage * 100))%")
                        .font(.title2.bold())
                        .monospacedDigit()
                        .foregroundStyle(.mint)
                }

                MacLinearProgressView(value: analysis.planCoverage, tint: .mint, height: 10)

                HStack {
                    Text("已计划 \(analysis.plannedRounds) 轮")
                    Spacer()
                    Text("计划专注 \(analysis.plannedFocusSeconds.hourMinuteText)")
                }
                .font(.caption)
                .foregroundStyle(MacTheme.secondaryText)
            }
        }
        .frame(maxWidth: 360)
    }
}

private struct MacWeeklyChartPanelView: View {
    @EnvironmentObject private var store: FocusStore

    let maxDailySeconds: Int

    var body: some View {
        MacGlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                Label("近 7 日分布", systemImage: "waveform.path.ecg")
                    .font(.headline)
                    .foregroundStyle(MacTheme.primaryText)

                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(store.weekBuckets()) { bucket in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(LinearGradient(colors: [.cyan, .mint], startPoint: .top, endPoint: .bottom))
                                .frame(height: max(8, CGFloat(bucket.focusSeconds) / CGFloat(maxDailySeconds) * 140))
                                .overlay(alignment: .top) {
                                    if bucket.focusSeconds > 0 {
                                        Text(bucket.focusSeconds.hourMinuteText)
                                            .font(.caption2.bold())
                                            .foregroundStyle(Color.black.opacity(0.72))
                                            .padding(.top, 4)
                                            .minimumScaleFactor(0.65)
                                    }
                                }

                            Text(bucket.weekdayLabel)
                                .font(.caption)
                                .foregroundStyle(MacTheme.secondaryText)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 178)
            }
        }
    }
}

private struct MacCategoryChartPanelView: View {
    @EnvironmentObject private var store: FocusStore

    var body: some View {
        MacGlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                Label("分类投入", systemImage: "chart.pie.fill")
                    .font(.headline)
                    .foregroundStyle(MacTheme.primaryText)

                if store.categoryBreakdown().isEmpty {
                    ContentUnavailableView("暂无分类统计", systemImage: "chart.pie", description: Text("完成番茄钟后会自动生成分类统计。"))
                        .foregroundStyle(MacTheme.secondaryText)
                        .frame(minHeight: 170)
                } else {
                    ForEach(store.categoryBreakdown()) { item in
                        VStack(alignment: .leading, spacing: 7) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Label(item.category, systemImage: "circle.fill")
                                        .foregroundStyle(Color(hex: item.accentHex))
                                    Text(categoryShareSessionCountText(for: item))
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(MacTheme.secondaryText)
                                }
                                Spacer()
                                Text(item.seconds.hourMinuteText)
                                    .font(.caption.bold())
                                    .foregroundStyle(MacTheme.primaryText)
                                Text("\(categorySharePercent(for: item.seconds))%")
                                    .font(.caption.bold())
                                    .monospacedDigit()
                                    .foregroundStyle(Color(hex: item.accentHex))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color(hex: item.accentHex).opacity(0.14), in: Capsule())
                            }
                            MacLinearProgressView(
                                value: Double(item.seconds),
                                total: Double(categoryShareTotalSeconds),
                                tint: Color(hex: item.accentHex),
                                height: 8
                            )
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(categoryShareAccessibilityLabel(for: item))
                        .accessibilityInputLabels([
                            Text(item.category),
                            Text("\(item.category)分类"),
                            Text("\(item.category)分类投入"),
                            Text("\(item.category)分类\(item.sessionCount)次专注")
                        ])
                    }
                }
            }
        }
        .frame(maxWidth: 360)
    }

    private func categorySharePercent(for seconds: Int) -> Int {
        Int((Double(seconds) / Double(categoryShareTotalSeconds) * 100).rounded())
    }

    private func categoryShareSessionCountText(for item: CategoryFocus) -> String {
        "\(item.sessionCount) 次专注"
    }

    private func categoryShareAccessibilityLabel(for item: CategoryFocus) -> String {
        "\(item.category)分类投入，\(item.seconds.hourMinuteText)，\(item.sessionCount)次专注，占分类投入 \(categorySharePercent(for: item.seconds))%"
    }

    private var categoryShareTotalSeconds: Int {
        max(store.categoryBreakdown().reduce(0) { $0 + $1.seconds }, 1)
    }
}

private struct MacRecentSessionsPanelView: View {
    @EnvironmentObject private var store: FocusStore

    var body: some View {
        MacGlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Label("最近记录", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                    .foregroundStyle(MacTheme.primaryText)

                if store.sessions.isEmpty {
                    ContentUnavailableView("暂无专注记录", systemImage: "clock", description: Text("专注、暂停和提前停止都会保存可分析的数据。"))
                        .foregroundStyle(MacTheme.secondaryText)
                        .frame(minHeight: 150)
                } else {
                    ForEach(store.sessions.prefix(10)) { session in
                        HStack {
                            Image(systemName: session.completed ? "checkmark.seal.fill" : "exclamationmark.circle")
                                .foregroundStyle(session.completed ? Color.mint : Color.orange)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(session.taskTitle)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(MacTheme.primaryText)
                                    .lineLimit(1)
                                HStack(spacing: 6) {
                                    MacRecentSessionCategoryBadgeView(category: session.category)
                                    Text("\(session.mode.title) · \(session.startedAt.scheduleTimeText)")
                                        .font(.caption)
                                        .foregroundStyle(MacTheme.secondaryText)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                            Text(session.actualSeconds.hourMinuteText)
                                .font(.caption.bold())
                                .foregroundStyle(MacTheme.primaryText)
                        }
                        .padding(.vertical, 6)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(recentSessionAccessibilityLabel(for: session))
                        .accessibilityInputLabels([
                            Text(session.taskTitle),
                            Text(session.category),
                            Text("\(session.category)分类"),
                            Text("\(session.category)分类记录")
                        ])
                    }
                }
            }
        }
    }

    private func recentSessionAccessibilityLabel(for session: FocusSession) -> String {
        let completionText = session.completed ? "已完成" : "未完成"
        return "\(session.taskTitle)，\(session.category)分类，\(session.mode.title)，\(session.startedAt.scheduleTimeText)，\(session.actualSeconds.hourMinuteText)，\(completionText)"
    }
}

private struct MacRecentSessionCategoryBadgeView: View {
    let category: String

    private var categoryPreset: TaskCategoryPreset? {
        TaskCategoryPreset.matching(category)
    }

    private var categorySymbolName: String {
        categoryPreset?.symbolName ?? "tag.fill"
    }

    private var tint: Color {
        Color(hex: categoryPreset?.accentHex ?? "#7C8CF8")
    }

    var body: some View {
        Label(category, systemImage: categorySymbolName)
            .font(.caption2.bold())
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(tint.opacity(0.12), in: Capsule())
            .accessibilityLabel("\(category)分类")
            .accessibilityInputLabels([Text(category), Text("\(category)分类")])
    }
}

private struct MacAnalysisTileView: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(MacTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(MacTheme.secondaryText)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(MacTheme.panel, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct MacLockedInsightView: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(MacTheme.primaryText)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(tint)
        }
        .padding(12)
        .background(MacTheme.panel, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct MacReportBucket: Identifiable {
    var id: String { label }
    let label: String
    let seconds: Int
}
