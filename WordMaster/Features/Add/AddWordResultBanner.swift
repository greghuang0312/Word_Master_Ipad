import Foundation

struct AddWordResultBanner: Equatable {
    enum Tone: Equatable {
        case progress
        case success
        case error
    }

    let message: String
    let tone: Tone
}
