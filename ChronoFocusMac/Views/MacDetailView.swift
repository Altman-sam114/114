import SwiftUI

@MainActor
final class MacDetailSelection: ObservableObject {
    @Published var selectedSection: MacDetailSection?

    init(selectedSection: MacDetailSection = .timer) {
        self.selectedSection = selectedSection
    }
}

struct MacDetailView: View {
    @ObservedObject var selection: MacDetailSelection

    var body: some View {
        NavigationSplitView {
            List(MacDetailSection.allCases, selection: $selection.selectedSection) { section in
                Label(section.title, systemImage: section.symbolName)
                    .tag(section)
            }
            .navigationTitle("ChronoFocus")
            .scrollContentBackground(.hidden)
            .background(Color.black.opacity(0.18))
            .frame(minWidth: 190)
        } detail: {
            MacDetailContentView(section: selection.selectedSection ?? .timer)
        }
        .background(MacTheme.background)
        .preferredColorScheme(.dark)
    }
}

private struct MacDetailContentView: View {
    let section: MacDetailSection

    var body: some View {
        ScrollView {
            switch section {
            case .timer:
                MacTimerDetailView()
            case .schedule:
                MacScheduleDetailView()
            case .analytics:
                MacAnalyticsDetailView()
            case .settings:
                MacSettingsDetailView()
            }
        }
        .scrollIndicators(.hidden)
        .background(MacTheme.background)
    }
}

enum MacDetailSection: String, CaseIterable, Identifiable {
    case timer
    case schedule
    case analytics
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .timer: return "计时"
        case .schedule: return "日程"
        case .analytics: return "统计"
        case .settings: return "设置"
        }
    }

    var symbolName: String {
        switch self {
        case .timer: return "timer"
        case .schedule: return "calendar"
        case .analytics: return "chart.xyaxis.line"
        case .settings: return "slider.horizontal.3"
        }
    }
}
