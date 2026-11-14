import SwiftUI

/// Presentation only: purchases and entitlements remain in the platform service.
struct PremiumFeatureList: View {
    let primaryText: Color
    let secondaryText: Color
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            feature("复盘与分类统计", detail: "查看投入分布、工作压力和日周月报表。", symbol: "chart.bar.xaxis", identifier: "reports")
            feature("日历同步", detail: "把系统日历中的近期安排转为专注待办。", symbol: "calendar.badge.plus", identifier: "calendar")
            feature("更多到点音色", detail: "选择适合自己的专注结束提示音。", symbol: "waveform", identifier: "sounds")
        }
    }

    private func feature(_ title: String, detail: String, symbol: String, identifier: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryText)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(secondaryText)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("premium.feature.\(identifier)")
    }
}

struct PremiumAccessActions: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let identifier: String
    let isUnlocked: Bool
    let activityText: String?
    let status: String
    let tint: Color
    let textOnTint: Color
    let secondaryText: Color
    let border: Color
    var purchaseTitle = "解锁 Pro"
    var rendersStaticControls = false
    let onPurchase: () -> Void
    let onRestore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isUnlocked {
                Label("Pro 已解锁", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
                    .accessibilityIdentifier("\(identifier).unlocked")
            }

            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 10))
                : AnyLayout(HStackLayout(spacing: 10))
            layout {
                if !isUnlocked {
                    action(title: purchaseTitle, symbol: "sparkles", prominent: true, suffix: "purchase", perform: onPurchase)
                }
                action(title: "恢复购买", symbol: "arrow.clockwise", prominent: false, suffix: "restore", perform: onRestore)
            }
            .disabled(activityText != nil)

            if let activityText {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityHidden(true)
                    Text(activityText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("\(identifier).activity")
            }

            Text(status)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("\(identifier).status")
        }
        .font(.caption)
        .foregroundStyle(secondaryText)
    }

    @ViewBuilder
    private func action(title: String, symbol: String, prominent: Bool, suffix: String, perform: @escaping () -> Void) -> some View {
        if rendersStaticControls {
            Label(title, systemImage: symbol)
                .modifier(PremiumActionSurface(tint: tint, foreground: textOnTint, border: border, prominent: prominent))
                .accessibilityLabel(title)
        } else {
            Button(action: perform) {
                Label(title, systemImage: symbol)
            }
            .buttonStyle(PremiumActionButtonStyle(tint: tint, foreground: textOnTint, border: border, prominent: prominent))
            .accessibilityIdentifier("\(identifier).\(suffix)")
            .accessibilityInputLabels([Text(title)])
        }
    }
}

private struct PremiumActionButtonStyle: ButtonStyle {
    let tint: Color
    let foreground: Color
    let border: Color
    let prominent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(PremiumActionSurface(tint: tint, foreground: foreground, border: border, prominent: prominent))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

private struct PremiumActionSurface: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled

    let tint: Color
    let foreground: Color
    let border: Color
    let prominent: Bool

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .foregroundStyle(prominent ? foreground : tint)
            .background(prominent ? tint : tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(prominent ? Color.clear : border, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(isEnabled ? 1 : 0.5)
    }
}
