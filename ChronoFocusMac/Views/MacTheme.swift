import AppKit
import SwiftUI

enum MacTheme {
    static let background = LinearGradient(
        colors: [
            adaptive(dark: NSColor(srgbRed: 0.08, green: 0.10, blue: 0.14, alpha: 1), light: NSColor(srgbRed: 0.96, green: 0.98, blue: 0.97, alpha: 1)),
            adaptive(dark: NSColor(srgbRed: 0.12, green: 0.14, blue: 0.20, alpha: 1), light: NSColor(srgbRed: 0.91, green: 0.95, blue: 0.97, alpha: 1)),
            adaptive(dark: NSColor(srgbRed: 0.10, green: 0.16, blue: 0.18, alpha: 1), light: NSColor(srgbRed: 0.89, green: 0.96, blue: 0.93, alpha: 1))
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panel = adaptive(dark: .white.withAlphaComponent(0.08), light: .black.withAlphaComponent(0.04))
    static let panelStrong = adaptive(dark: .white.withAlphaComponent(0.13), light: .white.withAlphaComponent(0.82))
    static let inset = adaptive(dark: .white.withAlphaComponent(0.06), light: .black.withAlphaComponent(0.04))
    static let border = adaptive(dark: .white.withAlphaComponent(0.12), light: .black.withAlphaComponent(0.14))
    static let track = adaptive(dark: .white.withAlphaComponent(0.12), light: .black.withAlphaComponent(0.14))
    static let primaryText = adaptive(dark: .white.withAlphaComponent(0.94), light: NSColor(srgbRed: 0.08, green: 0.14, blue: 0.18, alpha: 1))
    static let secondaryText = adaptive(dark: .white.withAlphaComponent(0.60), light: NSColor(srgbRed: 0.29, green: 0.36, blue: 0.40, alpha: 1))
    static let sidebar = adaptive(dark: .black.withAlphaComponent(0.18), light: .white.withAlphaComponent(0.50))
    static let quickPanel = adaptive(dark: NSColor(srgbRed: 0.10, green: 0.14, blue: 0.20, alpha: 0.98), light: NSColor(srgbRed: 0.98, green: 0.99, blue: 0.99, alpha: 0.98))

    // Keep the stored accent for fills; light surfaces need darker accent text.
    static func readableTint(_ tint: Color) -> Color {
        let original = NSColor(tint)
        return Color(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua { return original }
            return original.blended(withFraction: 0.58, of: .black) ?? original
        })
    }

    private static func adaptive(dark: NSColor, light: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }
}

private struct MacSnapshotRenderingKey: EnvironmentKey {
    static let defaultValue = false
}

private struct MacSnapshotShowsQuickPanelKey: EnvironmentKey {
    static let defaultValue = false
}

private struct MacSnapshotCategorySearchKey: EnvironmentKey {
    static let defaultValue = ""
}

private struct MacSnapshotCategoriesExpandedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var macSnapshotCategoriesExpanded: Bool {
        get { self[MacSnapshotCategoriesExpandedKey.self] }
        set { self[MacSnapshotCategoriesExpandedKey.self] = newValue }
    }

    var macSnapshotCategorySearch: String {
        get { self[MacSnapshotCategorySearchKey.self] }
        set { self[MacSnapshotCategorySearchKey.self] = newValue }
    }

    var macSnapshotRendering: Bool {
        get { self[MacSnapshotRenderingKey.self] }
        set { self[MacSnapshotRenderingKey.self] = newValue }
    }

    var macSnapshotShowsQuickPanel: Bool {
        get { self[MacSnapshotShowsQuickPanelKey.self] }
        set { self[MacSnapshotShowsQuickPanelKey.self] = newValue }
    }
}

struct MacStaticInputRowView: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(MacTheme.secondaryText)
            Spacer()
            Text(value)
                .foregroundStyle(MacTheme.primaryText)
                .lineLimit(1)
        }
        .font(.subheadline)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(MacTheme.inset, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct MacStaticSegmentedView: View {
    let title: String
    let selectedTitle: String
    let options: [String]

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(MacTheme.secondaryText)
            ForEach(options, id: \.self) { option in
                Text(option)
                    .font(.caption.bold())
                    .foregroundStyle(option == selectedTitle ? Color.black.opacity(0.82) : MacTheme.secondaryText)
                    .frame(minWidth: 34, minHeight: 26)
                    .padding(.horizontal, 4)
                    .background(option == selectedTitle ? Color.cyan : MacTheme.inset, in: RoundedRectangle(cornerRadius: 7))
            }
        }
    }
}

struct MacStaticToggleRowView: View {
    let title: String
    let isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(MacTheme.primaryText)
            Spacer()
            Capsule()
                .fill(isOn ? Color.cyan : MacTheme.track)
                .frame(width: 42, height: 22)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(isOn ? Color.black.opacity(0.82) : MacTheme.secondaryText)
                        .frame(width: 16, height: 16)
                        .padding(3)
                }
        }
        .font(.subheadline)
    }
}

struct MacStaticSliderView: View {
    let title: String
    let value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value * 100))%")
                    .monospacedDigit()
            }
            .font(.subheadline)
            .foregroundStyle(MacTheme.primaryText)

            MacLinearProgressView(value: value, tint: .cyan, height: 8)
        }
    }
}
