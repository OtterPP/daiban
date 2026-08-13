import Foundation

enum PolishSettings {
    static let baseURLDefaultsKey = "polish.baseURL"
    static let modelDefaultsKey = "polish.model"
    static let defaultBaseURL = "https://api.x.ai/v1"
    static let defaultModel = "grok-3-mini"

    static var baseURL: String {
        let stored = UserDefaults.standard.string(forKey: baseURLDefaultsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return stored.isEmpty ? defaultBaseURL : stored
    }

    static var model: String {
        let stored = UserDefaults.standard.string(forKey: modelDefaultsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return stored.isEmpty ? defaultModel : stored
    }
}

enum PolishService {
    enum PolishError: LocalizedError {
        case empty
        case badURL
        case httpStatus(Int, String)
        case noContent

        var errorDescription: String? {
            switch self {
            case .empty:
                return "没有可润色的内容"
            case .badURL:
                return "接口地址无效"
            case .httpStatus(let code, _):
                return "润色接口返回 \(code)"
            case .noContent:
                return "模型没有返回内容"
            }
        }
    }

    /// Rewrites `raw` into one short, verb-first Chinese todo.
    /// Uses the OpenAI-compatible API when a Keychain key exists; otherwise local cleanup.
    static func polish(_ raw: String) async throws -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PolishError.empty }

        if let key = KeychainStore.apiKey() {
            do {
                return try await requestChatCompletion(text: trimmed, apiKey: key)
            } catch {
                let fallback = LocalCleanup.clean(trimmed)
                if fallback != trimmed {
                    return fallback
                }
                throw error
            }
        }

        return LocalCleanup.clean(trimmed)
    }

    private static func requestChatCompletion(text: String, apiKey: String) async throws -> String {
        let root = PolishSettings.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: root + "/chat/completions") else {
            throw PolishError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = ChatRequest(
            model: PolishSettings.model,
            messages: [
                .init(role: "system", content: Self.systemPrompt),
                .init(role: "user", content: text)
            ],
            temperature: 0.2,
            max_tokens: 80
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let snippet = String(data: data, encoding: .utf8) ?? ""
            throw PolishError.httpStatus(status, snippet)
        }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        let content = decoded.choices.first?.message.content?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”"))
        guard let content, !content.isEmpty else { throw PolishError.noContent }
        return content
    }

    private static let systemPrompt = """
    你是待办润色助手。把用户输入改写成一条短的、可勾选的中文待办。
    要求：
    - 只输出这一条待办本身，不要引号、解释、编号或前缀
    - 动词开头（如：写、发、买、回复、提交、约）
    - 尽量不超过 20 个字
    - 保留具体对象和必要细节，去掉口语填充（我想、能不能、帮我、一下、吧 等）
    """
}

enum LocalCleanup {
    private static let prefixes = [
        "能不能帮我", "可以帮我", "请帮我", "麻烦帮我",
        "能不能", "能否", "可不可以", "是不是可以",
        "帮我", "麻烦你", "麻烦", "我想要", "我想", "我要"
    ]

    private static let suffixes = [
        "谢谢", "一下", "可以吗", "好吗", "吧", "嘛", "啊", "呢", "哦", "呀", "哈"
    ]

    static func clean(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return raw }

        var changed = true
        while changed {
            changed = false
            for prefix in prefixes where text.hasPrefix(prefix) {
                text.removeFirst(prefix.count)
                text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                changed = true
            }
        }

        changed = true
        while changed {
            changed = false
            for suffix in suffixes where text.hasSuffix(suffix) {
                text.removeLast(suffix.count)
                text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                changed = true
            }
        }

        text = text.trimmingCharacters(in: CharacterSet(charactersIn: "。！？!?.,，、;；:："))
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? raw.trimmingCharacters(in: .whitespacesAndNewlines) : text
    }
}

private struct ChatRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    let model: String
    let messages: [Message]
    let temperature: Double
    let max_tokens: Int
}

private struct ChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }

        let message: Message
    }

    let choices: [Choice]
}
