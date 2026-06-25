import SwiftUI

enum MacTheme {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.08, green: 0.10, blue: 0.14),
            Color(red: 0.12, green: 0.14, blue: 0.20),
            Color(red: 0.10, green: 0.16, blue: 0.18)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panel = Color.white.opacity(0.08)
    static let panelStrong = Color.white.opacity(0.13)
    static let border = Color.white.opacity(0.12)
    static let primaryText = Color.white.opacity(0.94)
    static let secondaryText = Color.white.opacity(0.60)
}

private struct MacSnapshotRenderingKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var macSnapshotRendering: Bool {
        get { self[MacSnapshotRenderingKey.self] }
        set { self[MacSnapshotRenderingKey.self] = newValue }
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
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
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
                    .background(option == selectedTitle ? Color.cyan : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 7))
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
                .fill(isOn ? Color.cyan : Color.white.opacity(0.16))
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
