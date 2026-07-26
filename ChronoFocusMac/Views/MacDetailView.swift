import SwiftUI

@MainActor
final class MacDetailSelection: ObservableObject {
    @Published var selectedSection: MacDetailSection?
    @Published private(set) var quickAddRequest: MacQuickAddRequest?

    init(selectedSection: MacDetailSection = .timer) {
        self.selectedSection = selectedSection
    }

    func requestQuickAdd(category: String) {
        quickAddRequest = MacQuickAddRequest(category: category)
        selectedSection = .schedule
    }

    func consumeQuickAddRequest(id: UUID) {
        guard quickAddRequest?.id == id else { return }
        quickAddRequest = nil
    }
}

struct MacQuickAddRequest: Identifiable, Equatable {
    let id = UUID()
    let category: String
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
            MacDetailContentView(selection: selection)
        }
        .background(MacTheme.background)
        .preferredColorScheme(.dark)
    }
}

private struct MacDetailContentView: View {
    @ObservedObject var selection: MacDetailSelection

    var body: some View {
        ScrollView {
            switch selection.selectedSection ?? .timer {
            case .timer:
                MacTimerDetailView(onAddTaskInCategory: selection.requestQuickAdd)
            case .schedule:
                MacScheduleDetailView(
                    quickAddRequest: selection.quickAddRequest,
                    onConsumeQuickAddRequest: selection.consumeQuickAddRequest
                )
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
