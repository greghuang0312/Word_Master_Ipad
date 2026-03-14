import Foundation

struct ProfileResultBanner: Equatable {
    let message: String
    let tone: Tone

    enum Tone: Equatable {
        case success
        case error

        var iconSystemName: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .error:
                return "xmark.circle.fill"
            }
        }
    }
}
