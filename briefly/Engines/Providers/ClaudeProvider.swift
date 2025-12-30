import Foundation

class ClaudeProvider: AIProvider {
    var name: String { "Claude" }
    var supportsEmbeddings: Bool { false } // Anthropic doesn't have an embedding endpoint in the same way yet

    private let apiKey: String
    private let baseURL = URL(string: "https://api.anthropic.com/v1")!

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func generateCompletion(prompt: String) async throws -> String {
        let url = baseURL.appendingPathComponent("messages")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Using Claude 3.5 Sonnet as default
        let body: [String: Any] = [
            "model": "claude-3-5-sonnet-20240620",
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.networkError("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIProviderError.apiError(message)
            }
            throw AIProviderError.apiError("HTTP status \(httpResponse.statusCode)")
        }

        // Parse Success Response
        // Structure: { "content": [ { "type": "text", "text": "..." } ] }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let firstContent = contentArray.first,
              let text = firstContent["text"] as? String else {
            throw AIProviderError.decodingError("Invalid JSON structure")
        }

        return text
    }

    func generateEmbedding(text: String) async throws -> [Float] {
        throw AIProviderError.embeddingsNotSupported
    }
}
