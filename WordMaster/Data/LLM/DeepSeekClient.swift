import Foundation

enum DeepSeekClientError: LocalizedError {
    case missingApiKey
    case invalidResponse
    case requestFailed(statusCode: Int, message: String)
    case networkFailure(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "请先在“我的”页面配置 DeepSeek API Key"
        case .invalidResponse:
            return "DeepSeek 返回格式异常"
        case let .requestFailed(statusCode, message):
            if let friendly = friendlyMessage(for: statusCode) {
                let detail = message.trimmingCharacters(in: .whitespacesAndNewlines)
                return detail.isEmpty ? friendly : "\(friendly)（\(detail)）"
            }

            if message.isEmpty {
                return "DeepSeek 请求失败（HTTP \(statusCode)）"
            }
            return "DeepSeek 请求失败（HTTP \(statusCode)）：\(message)"
        case let .networkFailure(underlying):
            return "连接 DeepSeek 失败：\(underlying.localizedDescription)"
        }
    }

    private func friendlyMessage(for statusCode: Int) -> String? {
        switch statusCode {
        case 401:
            return "DeepSeek API Key 无效或已失效"
        case 402:
            return "DeepSeek 账户余额不足"
        case 429:
            return "DeepSeek 请求过于频繁，请稍后再试"
        default:
            return nil
        }
    }
}

protocol DeepSeekClientProtocol {
    func generateCandidates(for zhText: String, apiKey: String) async throws -> [String]
}

final class DeepSeekClient: DeepSeekClientProtocol {
    private let endpoint = URL(string: "https://api.deepseek.com/chat/completions")!
    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func generateCandidates(for zhText: String, apiKey: String) async throws -> [String] {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw DeepSeekClientError.missingApiKey }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20

        let prompt = """
        你是英语词汇助手。用户输入一个中文词义，请返回 3 到 8 个最常见、最合适的英文单词候选。
        只输出 JSON 数组字符串，例如：["apple","fruit","pome"]。
        中文输入：\(zhText)
        """
        let payload = DeepSeekRequest(
            model: DeepSeekSettings.defaultModel,
            messages: [
                DeepSeekMessage(role: "system", content: "You are a concise bilingual vocabulary assistant."),
                DeepSeekMessage(role: "user", content: prompt)
            ],
            temperature: 0.2
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            throw DeepSeekClientError.networkFailure(underlying: error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw DeepSeekClientError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let message = parseErrorMessage(from: data)
            throw DeepSeekClientError.requestFailed(statusCode: http.statusCode, message: message)
        }

        let decoded = try JSONDecoder().decode(DeepSeekResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw DeepSeekClientError.invalidResponse
        }

        return parseCandidates(from: content)
    }

    private func parseCandidates(from content: String) -> [String] {
        let cleaned = content
            .replacingOccurrences(of: "```json", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let jsonLike: String
        if let range = cleaned.range(of: #"\[[\s\S]*\]"#, options: .regularExpression) {
            jsonLike = String(cleaned[range])
        } else {
            jsonLike = cleaned
        }

        if let data = jsonLike.data(using: .utf8),
           let array = try? JSONDecoder().decode([String].self, from: data) {
            return normalize(array)
        }

        // Fallback when the model does not return strict JSON.
        let separators = CharacterSet(charactersIn: ",\n;|")
        let rough = cleaned
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .components(separatedBy: separators)
        return normalize(rough)
    }

    private func normalize(_ input: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for raw in input {
            let word = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !word.isEmpty else { continue }
            guard word.range(of: #"^[a-z][a-z\- ]*$"#, options: .regularExpression) != nil else { continue }

            if !seen.contains(word) {
                seen.insert(word)
                result.append(word)
            }
        }

        return Array(result.prefix(8))
    }

    private func parseErrorMessage(from data: Data) -> String {
        if let decoded = try? JSONDecoder().decode(DeepSeekErrorEnvelope.self, from: data) {
            let message = decoded.error.message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !message.isEmpty {
                return message
            }
        }

        if let raw = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty {
            return raw
        }

        return "请检查 API Key 或稍后重试"
    }
}

private struct DeepSeekRequest: Encodable {
    let model: String
    let messages: [DeepSeekMessage]
    let temperature: Double
}

private struct DeepSeekMessage: Codable {
    let role: String
    let content: String
}

private struct DeepSeekResponse: Decodable {
    let choices: [DeepSeekChoice]
}

private struct DeepSeekChoice: Decodable {
    let message: DeepSeekMessage
}

private struct DeepSeekErrorEnvelope: Decodable {
    let error: DeepSeekErrorBody
}

private struct DeepSeekErrorBody: Decodable {
    let message: String?
}
