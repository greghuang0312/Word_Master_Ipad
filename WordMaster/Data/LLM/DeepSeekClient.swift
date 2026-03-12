import Foundation

enum DeepSeekClientError: LocalizedError {
    case missingApiKey
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "请先在“我的”页面配置 DeepSeek API Key"
        case .invalidResponse:
            return "DeepSeek 返回格式异常"
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

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DeepSeekClientError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(DeepSeekResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw DeepSeekClientError.invalidResponse
        }

        return parseCandidates(from: content)
    }

    private func parseCandidates(from content: String) -> [String] {
        let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = cleaned.data(using: .utf8),
           let array = try? JSONDecoder().decode([String].self, from: data) {
            return normalize(array)
        }

        // Fallback: split lines/commas if model didn't return JSON
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
            let word = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            guard !word.isEmpty else { continue }
            guard word.range(of: #"^[a-z][a-z\- ]*$"#, options: .regularExpression) != nil else { continue }
            if !seen.contains(word) {
                seen.insert(word)
                result.append(word)
            }
        }
        return Array(result.prefix(8))
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

