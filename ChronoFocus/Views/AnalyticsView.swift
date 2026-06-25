import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var premium: PremiumAccessService
    @State private var reportRange: ReportRange = .week

    private let calendar = Calendar.current

    private var analysis: WorkloadAnalysis {
        store.workloadAnalysis()
    }

    private var maxDailySeconds: Int {
        max(store.weekBuckets().map(\.focusSeconds).max() ?? 1, 1)
    }

    private var dailyGoalProgress: Double {
        min(1, Double(store.todayFocusSeconds) / Double(max(store.settings.dailyGoalSeconds, 1)))
    }

    private var reportBuckets: [ReportBucket] {
        let now = Date()
        switch reportRange {
        case .day:
            return (0..<7).reversed().compactMap { offset in
                guard let day = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: now)) else { return nil }
                return ReportBucket(label: day.shortWeekdayText, seconds: store.focusSeconds(on: day))
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
                return ReportBucket(label: "W\(calendar.component(.weekOfYear, from: date))", seconds: seconds)
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
                return ReportBucket(label: "\(calendar.component(.month, from: date))月", seconds: seconds)
            }
        }
    }

    private var maxReportSeconds: Int {
        max(reportBuckets.map(\.seconds).max() ?? 1, 1)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    summaryGrid
                    dailyGoalPanel

                    if premium.isProUnlocked {
                        reportPanel
                        workloadPanel
                        planCoveragePanel
                        weeklyChart
                        categoryChart
                        recentSessions
                    } else {
                        proPreviewPanel
                    }
                }
                .padding(18)
                .padding(.bottom, 26)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("统计分析")
            .task {
                await premium.refreshEntitlements()
            }
        }
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            MetricTile(title: "今日专注", value: store.todayFocusSeconds.hourMinuteText, symbol: "sun.max.fill", tint: .cyan)
            MetricTile(title: "本周专注", value: store.weekFocusSeconds.hourMinuteText, symbol: "calendar", tint: .mint)
            MetricTile(title: "累计轮数", value: "\(store.completedFocusRounds)", symbol: "number.circle.fill", tint: .orange)
            MetricTile(title: premium.isProUnlocked ? "压力等级" : "Pro 统计", value: premium.isProUnlocked ? analysis.pressureLevel : "体验", symbol: premium.isProUnlocked ? "gauge.medium" : "lock.fill", tint: .purple)
        }
    }

    private var dailyGoalPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("今日目标", systemImage: "target")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text("\(Int(dailyGoalProgress * 100))%")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.cyan)
                }

                ProgressView(value: dailyGoalProgress)
                    .tint(.cyan)
                    .scaleEffect(x: 1, y: 1.7, anchor: .center)

                HStack {
                    Text(store.todayFocusSeconds.hourMinuteText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text("目标 \(store.settings.dailyGoalSeconds.hourMinuteText)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
    }

    private var proPreviewPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Pro 工作分析", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text(premium.priceText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.cyan)
                }

                VStack(spacing: 10) {
                    LockedInsightRow(title: "待安排轮次", value: "\(analysis.remainingRounds)", symbol: "square.stack.3d.up.fill", tint: .cyan)
                    LockedInsightRow(title: "今日到期", value: "\(analysis.dueTodayTasks)", symbol: "calendar.badge.exclamationmark", tint: .orange)
                    LockedInsightRow(title: "计划覆盖", value: "\(Int(analysis.planCoverage * 100))%", symbol: "chart.bar.xaxis", tint: .mint)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.black.opacity(0.24))
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundStyle(.cyan)
                        Text("解锁 Pro 查看完整统计、工作压力和任务安排建议")
                            .font(.caption.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppTheme.primaryText)
                            .padding(.horizontal, 18)
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        Task { await premium.purchasePro() }
                    } label: {
                        Label("解锁 Pro", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    .disabled(premium.isLoading)

                    Button {
                        Task { await premium.restorePurchases() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .frame(width: 44, height: 34)
                    }
                    .buttonStyle(.bordered)
                    .tint(.mint)
                    .disabled(premium.isLoading)
                    .accessibilityLabel("恢复购买")
                }

                Text(premium.statusText)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private var workloadPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("工作任务安排", systemImage: "brain.head.profile")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text("压力 \(analysis.pressureLevel)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(pressureTint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(pressureTint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    AnalysisTile(title: "待办任务", value: "\(analysis.pendingTasks)", symbol: "checklist.unchecked", tint: .cyan)
                    AnalysisTile(title: "剩余轮次", value: "\(analysis.remainingRounds)", symbol: "timer", tint: .mint)
                    AnalysisTile(title: "今日到期", value: "\(analysis.dueTodayTasks)", symbol: "calendar.badge.clock", tint: .orange)
                    AnalysisTile(title: "已逾期", value: "\(analysis.overdueTasks)", symbol: "exclamationmark.triangle.fill", tint: .red)
                }

                HStack {
                    Text("预估专注")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Spacer()
                    Text(analysis.estimatedFocusSeconds.hourMinuteText)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.primaryText)
                }

                Text(analysis.recommendation)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var reportPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Label("工作复盘报表", systemImage: "chart.xyaxis.line")
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryText)
                        Text("适合回顾上周做了什么，快速整理周报素材。")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    Spacer()
                    Picker("范围", selection: $reportRange) {
                        ForEach(ReportRange.allCases) { range in
                            Text(range.title).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }

                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(reportBuckets) { bucket in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: max(10, CGFloat(bucket.seconds) / CGFloat(maxReportSeconds) * 136))
                            Text(bucket.label)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(AppTheme.secondaryText)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 168)

                VStack(alignment: .leading, spacing: 10) {
                    Label("日程计划回顾", systemImage: "list.bullet.rectangle.portrait")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    if store.pomodoroPlan.isEmpty {
                        Text("生成番茄钟计划后，这里会列出计划项，方便整理日报、周报和月度复盘。")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    } else {
                        ForEach(store.pomodoroPlan.sorted(by: { $0.scheduledStart > $1.scheduledStart }).prefix(8)) { item in
                            HStack {
                                Circle()
                                    .fill(Color(hex: item.accentHex))
                                    .frame(width: 8, height: 8)
                                Text(item.taskTitle)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                    .lineLimit(1)
                                Spacer()
                                Text(item.scheduledStart.scheduleTimeText)
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                    }
                }
            }
        }
    }

    private var planCoveragePanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("番茄钟计划覆盖", systemImage: "chart.bar.doc.horizontal")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text("\(Int(analysis.planCoverage * 100))%")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.mint)
                }

                ProgressView(value: analysis.planCoverage)
                    .tint(.mint)
                    .scaleEffect(x: 1, y: 1.7, anchor: .center)

                HStack {
                    Text("已计划 \(analysis.plannedRounds) 轮")
                    Spacer()
                    Text("计划专注 \(analysis.plannedFocusSeconds.hourMinuteText)")
                }
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private var weeklyChart: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                Label("近 7 日分布", systemImage: "waveform.path.ecg")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(store.weekBuckets()) { bucket in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.cyan, .mint],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: max(8, CGFloat(bucket.focusSeconds) / CGFloat(maxDailySeconds) * 130))
                                .overlay(alignment: .top) {
                                    if bucket.focusSeconds > 0 {
                                        Text(bucket.focusSeconds.hourMinuteText)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.black.opacity(0.75))
                                            .padding(.top, 4)
                                            .minimumScaleFactor(0.65)
                                    }
                                }

                            Text(bucket.weekdayLabel)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.secondaryText)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 170)
            }
        }
    }

    private var categoryChart: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                Label("分类投入", systemImage: "chart.pie.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                if store.categoryBreakdown().isEmpty {
                    Text("完成番茄钟后会自动生成分类统计。")
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(store.categoryBreakdown()) { item in
                        VStack(alignment: .leading, spacing: 7) {
                            HStack {
                                Label(item.category, systemImage: "circle.fill")
                                    .foregroundStyle(Color(hex: item.accentHex))
                                Spacer()
                                Text(item.seconds.hourMinuteText)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                            }
                            ProgressView(value: Double(item.seconds), total: Double(max(store.weekFocusSeconds, 1)))
                                .tint(Color(hex: item.accentHex))
                        }
                    }
                }
            }
        }
    }

    private var recentSessions: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Label("最近记录", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                if store.sessions.isEmpty {
                    Text("专注、暂停和提前停止都会保存可分析的数据。")
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(store.sessions.prefix(8)) { session in
                        HStack {
                            Image(systemName: session.completed ? "checkmark.seal.fill" : "exclamationmark.circle")
                                .foregroundStyle(session.completed ? .mint : .orange)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(session.taskTitle)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                    .lineLimit(1)
                                Text("\(session.mode.title) · \(session.startedAt.scheduleTimeText)")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            Spacer()
                            Text(session.actualSeconds.hourMinuteText)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.primaryText)
                        }
                        .padding(.vertical, 6)
                    }
                }
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

private struct AnalysisTile: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct LockedInsightRow: View {
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
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
            Spacer()
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
        }
        .padding(12)
        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ReportBucket: Identifiable {
    var id: String { label }
    let label: String
    let seconds: Int
}
