import Foundation

enum MainTab: CaseIterable, Identifiable {
    case review
    case add
    case library
    case stats
    case profile

    var id: Self { self }

    var title: String {
        switch self {
        case .review:
            return "复习"
        case .add:
            return "添加"
        case .library:
            return "库"
        case .stats:
            return "统计"
        case .profile:
            return "我的"
        }
    }

    var systemImage: String {
        switch self {
        case .review:
            return "book"
        case .add:
            return "plus.circle"
        case .library:
            return "books.vertical"
        case .stats:
            return "chart.bar"
        case .profile:
            return "person.crop.circle"
        }
    }

    var reloadsOnActivate: Bool {
        switch self {
        case .review, .library, .stats:
            return true
        case .add, .profile:
            return false
        }
    }
}
