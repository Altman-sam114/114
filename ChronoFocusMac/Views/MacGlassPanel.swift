import SwiftUI

struct MacGlassPanel<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(MacTheme.panelStrong, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(MacTheme.border, lineWidth: 1)
            }
    }
}

// Measure against the detail area's width, including the window sidebar allowance.
struct MacAdaptiveColumns: Layout {
    var minimumWidth: CGFloat = 780
    var leadingWidth: CGFloat? = nil
    var compactLeadingFirst = true
    var spacing: CGFloat = 18

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = resolvedWidth(proposal.width)
        let sizes = measuredSizes(width: width, subviews: subviews)
        let height = width >= minimumWidth
            ? max(sizes.0.height, sizes.1.height)
            : sizes.0.height + sizes.1.height + spacing
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let sizes = measuredSizes(width: bounds.width, subviews: subviews)
        if bounds.width >= minimumWidth {
            subviews[0].place(at: bounds.origin, proposal: ProposedViewSize(sizes.0))
            subviews[1].place(
                at: CGPoint(x: bounds.minX + sizes.0.width + spacing, y: bounds.minY),
                proposal: ProposedViewSize(sizes.1)
            )
        } else {
            let first = compactLeadingFirst ? 0 : 1
            let second = 1 - first
            let firstSize = first == 0 ? sizes.0 : sizes.1
            let secondSize = second == 0 ? sizes.0 : sizes.1
            subviews[first].place(at: bounds.origin, proposal: ProposedViewSize(firstSize))
            subviews[second].place(
                at: CGPoint(x: bounds.minX, y: bounds.minY + firstSize.height + spacing),
                proposal: ProposedViewSize(secondSize)
            )
        }
    }

    private func resolvedWidth(_ proposedWidth: CGFloat?) -> CGFloat {
        guard let proposedWidth, proposedWidth.isFinite else { return minimumWidth }
        return max(proposedWidth, 1)
    }

    private func measuredSizes(width: CGFloat, subviews: Subviews) -> (CGSize, CGSize) {
        guard subviews.count == 2 else { return (.zero, .zero) }
        let isWide = width >= minimumWidth
        let firstWidth = isWide ? (leadingWidth ?? (width - spacing) * 0.5) : width
        let secondWidth = isWide ? width - firstWidth - spacing : width
        let first = subviews[0].sizeThatFits(ProposedViewSize(width: firstWidth, height: nil))
        let second = subviews[1].sizeThatFits(ProposedViewSize(width: secondWidth, height: nil))
        return (CGSize(width: firstWidth, height: first.height), CGSize(width: secondWidth, height: second.height))
    }
}
