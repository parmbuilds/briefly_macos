import Foundation

class OpenAIProvider: AIProvider {
    var name: String { "OpenAI" }
    var supportsEmbeddings: Bool { true }

    private let apiKey: String
    private let baseURL = URL(string: "https://api.openai.com/v1")!

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func generateCompletion(prompt: String) async throws -> String {
        let url = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Using GPT-4o-mini as a good default for cost/speed
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.networkError("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Parse error message if possible
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIProviderError.apiError(message)
            }
            throw AIProviderError.apiError("HTTP status \(httpResponse.statusCode)")
        }

        // Parse Success Response
        // Structure: { "choices": [ { "message": { "content": "..." } } ] }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIProviderError.decodingError("Invalid JSON structure")
        }

        return content
    }

    func generateEmbedding(text: String) async throws -> [Float] {
        let url = baseURL.appendingPathComponent("embeddings")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "text-embedding-3-small",
            "input": text
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
             throw AIProviderError.apiError("Embeddings HTTP Error")
        }

        // Parse Response
        // Structure: { "data": [ { "embedding": [0.1, 0.2, ...] } ] }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]],
              let firstItem = dataArray.first,
              let embedding = firstItem["embedding"] as? [Double] else { // Embedding comes as Doubles
            throw AIProviderError.decodingError("Invalid embedding JSON")
        }

        return embedding.map { Float($0) }
    }
}
