import SwiftUI

struct TimerContextHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: String
    let category: String?
    let mode: TimerMode
    let isRunning: Bool
    let isPaused: Bool
    let round: Int
    let tint: Color

    private var status: String {
        isRunning ? (isPaused ? "已暂停" : "正在\(mode.title)") : "准备开始"
    }

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
        layout {
            VStack(alignment: .leading, spacing: 6) {
                Text(isRunning ? status : "准备好，专注当下")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.readableTint(tint))
                Text(title)
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundStyle(AppTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("timer.task-title")
                if let category {
                    Label(category, systemImage: "tag.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.readableTint(tint))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text("第 \(round) 轮")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(status)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: AppTheme.controlRadius, style: .continuous))
            .accessibilityElement(children: .combine)
        }
    }
}

struct TimerCountdownView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize = 58

    let remaining: String
    let progress: Double
    let mode: TimerMode
    let plannedSeconds: Int
    let nextModeHint: String
    let tint: Color
    let compact: Bool

    var body: some View {
        GlassPanel {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 12) {
                    countdown
                    ProgressView(value: progress)
                        .tint(tint)
                        .accessibilityLabel("本轮进度")
                    phaseCaption
                }
                .frame(maxWidth: .infinity)
            } else {
                ZStack {
                    Circle()
                        .stroke(AppTheme.border, lineWidth: 10)
                        .accessibilityHidden(true)
                    Circle()
                        .trim(from: 0, to: min(1, max(0, progress)))
                        .stroke(tint, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Image(systemName: mode.symbolName)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(AppTheme.readableTint(tint))
                            .accessibilityHidden(true)
                        countdown
                        phaseCaption
                    }
                    .padding(18)
                }
                .frame(maxWidth: compact ? 210 : 280)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var countdown: some View {
        Text(remaining)
            .font(dynamicTypeSize.isAccessibilitySize
                  ? .system(.title, design: .rounded).bold()
                  : .system(size: timerFontSize, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(AppTheme.primaryText)
            .contentTransition(reduceMotion ? .identity : .numericText(countsDown: true))
            .accessibilityLabel("剩余时间")
            .accessibilityValue(remaining)
            .accessibilityIdentifier("timer.remaining")
    }

    private var phaseCaption: some View {
        VStack(spacing: 6) {
            Text("\(mode.title) · \(plannedSeconds.hourMinuteText)")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
            Text("下一步 \(nextModeHint)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.readableTint(tint))
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
}
