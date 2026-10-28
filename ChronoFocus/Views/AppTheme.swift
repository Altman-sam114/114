import SwiftUI
import UIKit

enum AppTheme {
    static let panelRadius: CGFloat = 20
    static let controlRadius: CGFloat = 14

    static let background = LinearGradient(
        colors: [
            dynamicColor(dark: UIColor(red: 0.03, green: 0.04, blue: 0.06, alpha: 1), light: UIColor(red: 0.96, green: 0.98, blue: 1.00, alpha: 1)),
            dynamicColor(dark: UIColor(red: 0.02, green: 0.07, blue: 0.09, alpha: 1), light: UIColor(red: 0.91, green: 0.98, blue: 0.97, alpha: 1)),
            dynamicColor(dark: UIColor(red: 0.04, green: 0.10, blue: 0.12, alpha: 1), light: UIColor(red: 0.94, green: 0.97, blue: 0.99, alpha: 1))
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panel = dynamicColor(dark: UIColor.white.withAlphaComponent(0.075), light: UIColor.white.withAlphaComponent(0.72))
    static let panelStrong = dynamicColor(dark: UIColor.white.withAlphaComponent(0.12), light: UIColor.white.withAlphaComponent(0.92))
    static let opaquePanel = dynamicColor(dark: UIColor(red: 0.09, green: 0.14, blue: 0.17, alpha: 1), light: .white)
    static let border = dynamicColor(dark: UIColor.white.withAlphaComponent(0.12), light: UIColor.black.withAlphaComponent(0.08))
    static let primaryText = dynamicColor(dark: .white, light: UIColor(red: 0.06, green: 0.08, blue: 0.12, alpha: 1))
    static let secondaryText = dynamicColor(dark: UIColor.white.withAlphaComponent(0.64), light: UIColor(red: 0.28, green: 0.33, blue: 0.42, alpha: 1))

    static func readableTint(_ tint: Color) -> Color {
        let original = UIColor(tint)
        return Color(UIColor { traits in
            let resolved = original.resolvedColor(with: traits)
            guard traits.userInterfaceStyle != .dark else { return resolved }
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            guard resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return resolved }
            return UIColor(red: red * 0.42, green: green * 0.42, blue: blue * 0.42, alpha: alpha)
        })
    }

    static func textOnReadableTint(_ tint: Color) -> Color {
        let fill = UIColor(readableTint(tint))
        return Color(UIColor { traits in
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            guard fill.resolvedColor(with: traits).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
                return .label
            }
            let hex = String(format: "#%02X%02X%02X", Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded()))
            return UIColor(Color(hex: TaskCategoryPreset.contrastTextHex(on: hex)))
        })
    }

    private static func dynamicColor(dark: UIColor, light: UIColor) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }
}

struct GlassPanel<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                reduceTransparency ? AppTheme.opaquePanel : AppTheme.panel,
                in: RoundedRectangle(cornerRadius: AppTheme.panelRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.panelRadius, style: .continuous)
                    .stroke(contrast == .increased ? AppTheme.secondaryText : AppTheme.border, lineWidth: 1)
            }
    }
}

struct MetricTile: View {
    let identifier: String
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.readableTint(tint))
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.panelStrong, in: RoundedRectangle(cornerRadius: AppTheme.panelRadius, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
        .accessibilityIdentifier(identifier)
    }
}
