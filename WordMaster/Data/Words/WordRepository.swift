import Foundation

struct UpsertWordResult {
    let word: WordItem
    let merged: Bool
}

protocol WordRepository: AnyObject {
    func fetchDueWords(userId: UUID, today: Date) async throws -> [WordItem]
    func fetchAllWords(userId: UUID) async throws -> [WordItem]
    func upsertWord(userId: UUID, zhText: String, enWord: String, today: Date) async throws -> UpsertWordResult
    func deleteWord(userId: UUID, wordId: UUID) async throws
    func applyReview(
        userId: UUID,
        wordId: UUID,
        result: ReviewResult,
        today: Date,
        scheduler: ReviewScheduler
    ) async throws -> WordItem
}

enum WordRepositoryFactory {
    static func makeDefault() -> WordRepository {
        if let config = SupabaseClientFactory.loadConfig() {
            return SupabaseWordRepository(config: config)
        }
        return InMemoryWordRepository()
    }
}

actor InMemoryWordRepository: WordRepository {
    private var storage: [UUID: [WordItem]] = [:]

    func fetchDueWords(userId: UUID, today: Date) async throws -> [WordItem] {
        let normalizedToday = startOfDay(today)
        return (storage[userId] ?? [])
            .filter { startOfDay($0.nextReviewDate) <= normalizedToday }
            .sorted { lhs, rhs in
                if lhs.nextReviewDate == rhs.nextReviewDate {
                    return lhs.enWord.localizedCaseInsensitiveCompare(rhs.enWord) == .orderedAscending
                }
                return lhs.nextReviewDate < rhs.nextReviewDate
            }
    }

    func fetchAllWords(userId: UUID) async throws -> [WordItem] {
        (storage[userId] ?? []).sorted { $0.enWord.localizedCaseInsensitiveCompare($1.enWord) == .orderedAscending }
    }

    func upsertWord(userId: UUID, zhText: String, enWord: String, today: Date) async throws -> UpsertWordResult {
        var bucket = storage[userId] ?? []
        let normalizedEnglish = normalizeWord(enWord)
        let tomorrow = addDays(1, to: today)

        if let idx = bucket.firstIndex(where: { normalizeWord($0.enWord) == normalizedEnglish }) {
            var existing = bucket[idx]
            existing.zhText = zhText.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.enWord = enWord.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.stage = 1
            existing.nextReviewDate = tomorrow
            existing.isMastered = false
            bucket[idx] = existing
            storage[userId] = bucket
            return UpsertWordResult(word: existing, merged: true)
        }

        let created = WordItem(
            userId: userId,
            zhText: zhText.trimmingCharacters(in: .whitespacesAndNewlines),
            enWord: enWord.trimmingCharacters(in: .whitespacesAndNewlines),
            stage: 1,
            nextReviewDate: tomorrow,
            isMastered: false
        )
        bucket.append(created)
        storage[userId] = bucket
        return UpsertWordResult(word: created, merged: false)
    }

    func deleteWord(userId: UUID, wordId: UUID) async throws {
        var bucket = storage[userId] ?? []
        bucket.removeAll { $0.id == wordId }
        storage[userId] = bucket
    }

    func applyReview(
        userId: UUID,
        wordId: UUID,
        result: ReviewResult,
        today: Date,
        scheduler: ReviewScheduler
    ) async throws -> WordItem {
        var bucket = storage[userId] ?? []
        guard let idx = bucket.firstIndex(where: { $0.id == wordId }) else {
            throw NSError(domain: "WordRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "词条不存在"])
        }

        var word = bucket[idx]
        let transition = scheduler.nextState(currentStage: word.stage, result: result, today: today)
        word.stage = transition.stage
        word.nextReviewDate = transition.nextReviewDate
        word.isMastered = (transition.stage >= 6)

        bucket[idx] = word
        storage[userId] = bucket
        return word
    }

    private func normalizeWord(_ input: String) -> String {
        input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private func addDays(_ days: Int, to date: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }
}
