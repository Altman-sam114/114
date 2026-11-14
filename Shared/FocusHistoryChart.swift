import SwiftUI

struct FocusHistoryPoint: Identifiable {
    let id: String
    let label: String
    let seconds: Int
}

/// Both platforms share the same zero-value, large-text and VoiceOver behavior.
struct FocusHistoryChart: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let points: [FocusHistoryPoint]
    let tint: Color
    let primaryText: Color
    let secondaryText: Color
    let track: Color

    private var maximum: Int { max(points.map(\.seconds).max() ?? 0, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if points.allSatisfy({ $0.seconds == 0 }) {
                Label("这段时间还没有完成的专注", systemImage: "chart.bar.xaxis")
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
            } else if dynamicTypeSize.isAccessibilitySize {
                ForEach(points) { point in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(point.label) · \(point.seconds.hourMinuteText)")
                            .font(.subheadline)
                            .foregroundStyle(primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        ProgressView(value: Double(max(0, point.seconds)), total: Double(maximum))
                            .tint(tint)
                            .accessibilityHidden(true)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(point.label)
                    .accessibilityValue("专注 \(point.seconds.hourMinuteText)")
                }
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(points) { point in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(point.seconds > 0 ? tint : track)
                                .frame(height: point.seconds > 0 ? max(4, CGFloat(point.seconds) / CGFloat(maximum) * 128) : 2)
                                .frame(height: 128, alignment: .bottom)
                            Text(point.label)
                                .font(.caption2)
                                .foregroundStyle(secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(point.seconds.hourMinuteText)
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(point.label)
                        .accessibilityValue("专注 \(point.seconds.hourMinuteText)")
                        .help("\(point.label)：\(point.seconds.hourMinuteText)")
                    }
                }
                .multilineTextAlignment(.center)

                Text("合计 \(points.reduce(0) { $0 + $1.seconds }.hourMinuteText)")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
