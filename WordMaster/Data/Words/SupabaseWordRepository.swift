import Foundation

enum WordRepositoryError: LocalizedError {
    case missingSupabaseConfig
    case missingSession
    case invalidResponse
    case wordNotFound

    var errorDescription: String? {
        switch self {
        case .missingSupabaseConfig:
            return "缺少 Supabase 配置"
        case .missingSession:
            return "登录已失效，请重新登录"
        case .invalidResponse:
            return "服务返回异常，请稍后重试"
        case .wordNotFound:
            return "词条不存在"
        }
    }
}

final class SupabaseWordRepository: WordRepository {
    private let config: SupabaseConfig
    private let sessionStore: SupabaseSessionStore
    private let urlSession: URLSession
    private let calendar: Calendar

    init(
        config: SupabaseConfig,
        sessionStore: SupabaseSessionStore = .shared,
        urlSession: URLSession = .shared,
        calendar: Calendar = .current
    ) {
        self.config = config
        self.sessionStore = sessionStore
        self.urlSession = urlSession
        self.calendar = calendar
    }

    func fetchDueWords(userId: UUID, today: Date) async throws -> [WordItem] {
        var components = try baseRestComponents(path: "words")
        components.queryItems = [
            URLQueryItem(name: "select", value: wordSelect),
            URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString.lowercased())"),
            URLQueryItem(name: "next_review_date", value: "lte.\(formatDate(today))"),
            URLQueryItem(name: "order", value: "next_review_date.asc,en_word.asc")
        ]

        let request = try await request(url: components.url, method: "GET")
        let rows: [SupabaseWordRow] = try await send(request: request, decode: [SupabaseWordRow].self)
        return rows.map(Self.toWordItem)
    }

    func fetchAllWords(userId: UUID) async throws -> [WordItem] {
        var components = try baseRestComponents(path: "words")
        components.queryItems = [
            URLQueryItem(name: "select", value: wordSelect),
            URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "en_word.asc")
        ]

        let request = try await request(url: components.url, method: "GET")
        let rows: [SupabaseWordRow] = try await send(request: request, decode: [SupabaseWordRow].self)
        return rows.map(Self.toWordItem)
    }

    func upsertWord(userId: UUID, zhText: String, enWord: String, today: Date) async throws -> UpsertWordResult {
        let normalizedZh = zhText.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEn = enWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let tomorrow = addDays(1, to: today)

        let existed = try await hasExistingWord(userId: userId, enWord: normalizedEn)
        let payload = [WordUpsertPayload(
            userId: userId.uuidString.lowercased(),
            zhText: normalizedZh,
            enWord: normalizedEn,
            stage: 1,
            nextReviewDate: formatDate(tomorrow),
            isMastered: false
        )]

        var components = try baseRestComponents(path: "words")
        components.queryItems = [URLQueryItem(name: "on_conflict", value: "user_id,en_word")]

        var req = try await request(url: components.url, method: "POST")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("resolution=merge-duplicates,return=representation", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONEncoder().encode(payload)

        let rows: [SupabaseWordRow] = try await send(request: req, decode: [SupabaseWordRow].self)
        guard let row = rows.first else { throw WordRepositoryError.invalidResponse }
        return UpsertWordResult(word: Self.toWordItem(row), merged: existed)
    }

    func deleteWord(userId: UUID, wordId: UUID) async throws {
        var components = try baseRestComponents(path: "words")
        components.queryItems = [
            URLQueryItem(name: "id", value: "eq.\(wordId.uuidString.lowercased())"),
            URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString.lowercased())")
        ]

        let req = try await request(url: components.url, method: "DELETE")
        _ = try await send(request: req, decode: EmptyResponse.self)
    }

    func applyReview(
        userId: UUID,
        wordId: UUID,
        result: ReviewResult,
        today: Date,
        scheduler: ReviewScheduler
    ) async throws -> WordItem {
        guard let current = try await fetchWord(userId: userId, wordId: wordId) else {
            throw WordRepositoryError.wordNotFound
        }

        let transition = scheduler.nextState(currentStage: current.stage, result: result, today: today)
        let patched = try await updateWord(
            userId: userId,
            wordId: wordId,
            stage: transition.stage,
            nextReviewDate: transition.nextReviewDate,
            isMastered: transition.stage >= 6
        )

        try await insertReviewLog(
            userId: userId,
            wordId: wordId,
            result: result,
            fromStage: current.stage,
            toStage: transition.stage,
            nextReviewDate: transition.nextReviewDate
        )

        return patched
    }

    private func hasExistingWord(userId: UUID, enWord: String) async throws -> Bool {
        var components = try baseRestComponents(path: "words")
        components.queryItems = [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString.lowercased())"),
            URLQueryItem(name: "en_word", value: "eq.\(enWord)"),
            URLQueryItem(name: "limit", value: "1")
        ]

        let req = try await request(url: components.url, method: "GET")
        let rows: [WordIdRow] = try await send(request: req, decode: [WordIdRow].self)
        return !rows.isEmpty
    }

    private func fetchWord(userId: UUID, wordId: UUID) async throws -> WordItem? {
        var components = try baseRestComponents(path: "words")
        components.queryItems = [
            URLQueryItem(name: "select", value: wordSelect),
            URLQueryItem(name: "id", value: "eq.\(wordId.uuidString.lowercased())"),
            URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ]

        let req = try await request(url: components.url, method: "GET")
        let rows: [SupabaseWordRow] = try await send(request: req, decode: [SupabaseWordRow].self)
        guard let row = rows.first else { return nil }
        return Self.toWordItem(row)
    }

    private func updateWord(userId: UUID, wordId: UUID, stage: Int, nextReviewDate: Date, isMastered: Bool) async throws -> WordItem {
        var components = try baseRestComponents(path: "words")
        components.queryItems = [
            URLQueryItem(name: "id", value: "eq.\(wordId.uuidString.lowercased())"),
            URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString.lowercased())")
        ]

        let payload = WordReviewUpdatePayload(
            stage: stage,
            nextReviewDate: formatDate(nextReviewDate),
            isMastered: isMastered
        )

        var req = try await request(url: components.url, method: "PATCH")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONEncoder().encode(payload)

        let rows: [SupabaseWordRow] = try await send(request: req, decode: [SupabaseWordRow].self)
        guard let row = rows.first else { throw WordRepositoryError.invalidResponse }
        return Self.toWordItem(row)
    }

    private func insertReviewLog(
        userId: UUID,
        wordId: UUID,
        result: ReviewResult,
        fromStage: Int,
        toStage: Int,
        nextReviewDate: Date
    ) async throws {
        let payload = ReviewLogPayload(
            userId: userId.uuidString.lowercased(),
            wordId: wordId.uuidString.lowercased(),
            result: result == .known ? "known" : "unknown",
            fromStage: fromStage,
            toStage: toStage,
            nextReviewDate: formatDate(nextReviewDate)
        )

        let reviewLogURL = try baseRestComponents(path: "review_logs").url
        var req = try await request(url: reviewLogURL, method: "POST")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(payload)
        _ = try await send(request: req, decode: EmptyResponse.self)
    }

    private func baseRestComponents(path: String) throws -> URLComponents {
        guard let base = URL(string: config.urlString) else { throw WordRepositoryError.missingSupabaseConfig }
        guard let url = URL(string: "/rest/v1/\(path)", relativeTo: base) else { throw WordRepositoryError.missingSupabaseConfig }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw WordRepositoryError.missingSupabaseConfig
        }
        return components
    }

    private func request(url: URL?, method: String) async throws -> URLRequest {
        guard let url else { throw WordRepositoryError.missingSupabaseConfig }
        guard let token = await sessionStore.currentAccessToken() else { throw WordRepositoryError.missingSession }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = 20
        req.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return req
    }

    private func send<T: Decodable>(request: URLRequest, decode: T.Type) async throws -> T {
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw WordRepositoryError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 || http.statusCode == 403 {
                throw WordRepositoryError.missingSession
            }
            throw WordRepositoryError.invalidResponse
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func addDays(_ days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    private static func toWordItem(_ row: SupabaseWordRow) -> WordItem {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        let nextReviewDate = formatter.date(from: row.nextReviewDate) ?? Date()

        return WordItem(
            id: UUID(uuidString: row.id) ?? UUID(),
            userId: UUID(uuidString: row.userId) ?? UUID(),
            zhText: row.zhText,
            enWord: row.enWord,
            stage: row.stage,
            nextReviewDate: nextReviewDate,
            isMastered: row.isMastered
        )
    }

    private let wordSelect = "id,user_id,zh_text,en_word,stage,next_review_date,is_mastered,created_at,updated_at"
}

private struct SupabaseWordRow: Decodable {
    let id: String
    let userId: String
    let zhText: String
    let enWord: String
    let stage: Int
    let nextReviewDate: String
    let isMastered: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case zhText = "zh_text"
        case enWord = "en_word"
        case stage
        case nextReviewDate = "next_review_date"
        case isMastered = "is_mastered"
    }
}

private struct WordUpsertPayload: Encodable {
    let userId: String
    let zhText: String
    let enWord: String
    let stage: Int
    let nextReviewDate: String
    let isMastered: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case zhText = "zh_text"
        case enWord = "en_word"
        case stage
        case nextReviewDate = "next_review_date"
        case isMastered = "is_mastered"
    }
}

private struct WordReviewUpdatePayload: Encodable {
    let stage: Int
    let nextReviewDate: String
    let isMastered: Bool

    enum CodingKeys: String, CodingKey {
        case stage
        case nextReviewDate = "next_review_date"
        case isMastered = "is_mastered"
    }
}

private struct ReviewLogPayload: Encodable {
    let userId: String
    let wordId: String
    let result: String
    let fromStage: Int
    let toStage: Int
    let nextReviewDate: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case wordId = "word_id"
        case result
        case fromStage = "from_stage"
        case toStage = "to_stage"
        case nextReviewDate = "next_review_date"
    }
}

private struct WordIdRow: Decodable {
    let id: String
}

private struct EmptyResponse: Decodable {
    init() {}
}
