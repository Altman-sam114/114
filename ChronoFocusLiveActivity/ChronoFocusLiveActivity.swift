import ActivityKit
import SwiftUI
import WidgetKit

struct ChronoFocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color(red: 0.03, green: 0.04, blue: 0.06))
                .activitySystemActionForegroundColor(Color(hex: context.state.tintHex))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.modeName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(hex: context.state.tintHex))
                        Text(context.state.taskTitle)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    timerText(for: context)
                        .font(.title3.monospacedDigit().weight(.bold))
                        .foregroundStyle(.white)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    ActivityProgressBar(
                        progress: progress(for: context),
                        tint: Color(hex: context.state.tintHex)
                    )
                    .frame(height: 6)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(Color(hex: context.state.tintHex))
            } compactTrailing: {
                timerText(for: context)
                    .font(.caption.monospacedDigit().weight(.bold))
            } minimal: {
                Image(systemName: "scope")
                    .foregroundStyle(Color(hex: context.state.tintHex))
            }
            .keylineTint(Color(hex: context.state.tintHex))
        }
    }

    @ViewBuilder
    private func timerText(for context: ActivityViewContext<PomodoroActivityAttributes>) -> some View {
        if context.state.isPaused {
            Text(context.state.remainingSeconds.clockString)
        } else {
            Text(timerInterval: Date()...context.state.endDate, countsDown: true)
        }
    }

    private func progress(for context: ActivityViewContext<PomodoroActivityAttributes>) -> Double {
        let total = max(1, context.state.endDate.timeIntervalSince(context.attributes.startedAt))
        let elapsed: TimeInterval
        if context.state.isPaused {
            elapsed = total - Double(context.state.remainingSeconds)
        } else {
            elapsed = Date().timeIntervalSince(context.attributes.startedAt)
        }
        return min(1, max(0, elapsed / total))
    }
}

private struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<PomodoroActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: context.state.tintHex).opacity(0.16))
                Image(systemName: context.state.isPaused ? "pause.fill" : "scope")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color(hex: context.state.tintHex))
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.modeName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: context.state.tintHex))
                Text(context.state.taskTitle)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 4) {
                if context.state.isPaused {
                    Text(context.state.remainingSeconds.clockString)
                        .font(.title2.monospacedDigit().weight(.bold))
                } else {
                    Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                        .font(.title2.monospacedDigit().weight(.bold))
                }
                Text(context.state.isPaused ? "暂停" : "后台运行")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.62))
            }
            .foregroundStyle(.white)
        }
        .padding()
    }
}

private struct ActivityProgressBar: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.16))
                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * progress)
            }
        }
    }
}
