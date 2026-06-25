import SwiftUI

struct MacLinearProgressView: View {
    let value: Double
    var total: Double = 1
    let tint: Color
    var height: CGFloat = 8

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return min(1, max(0, value / total))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(tint)
                    .frame(width: max(height, proxy.size.width * fraction))
            }
        }
        .frame(height: height)
    }
}
