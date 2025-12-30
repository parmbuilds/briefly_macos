import Foundation

/// Ollama provider for local LLM inference
class OllamaProvider: AIProvider {
    let baseURL: String
    let model: String

    var name: String { "Ollama (\(model))" }
    var supportsEmbeddings: Bool { true }

    init(baseURL: String = "http://localhost:11434", model: String = "llama3.2") {
        self.baseURL = baseURL
        self.model = model
    }

    func generateCompletion(prompt: String) async throws -> String {
        let url = URL(string: "\(baseURL)/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIProviderError.networkError("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }

        struct OllamaResponse: Codable {
            let response: String
        }

        let decoded = try JSONDecoder().decode(OllamaResponse.self, from: data)
        return decoded.response
    }

    func generateEmbedding(text: String) async throws -> [Float] {
        let url = URL(string: "\(baseURL)/api/embeddings")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "prompt": text
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIProviderError.networkError("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }

        struct OllamaEmbeddingResponse: Codable {
            let embedding: [Float]
        }

        let decoded = try JSONDecoder().decode(OllamaEmbeddingResponse.self, from: data)
        return decoded.embedding
    }
}
