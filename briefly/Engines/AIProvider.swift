import Foundation

/// Protocol defining the interface for AI providers
protocol AIProvider {
    /// Generate a text completion from a prompt
    func generateCompletion(prompt: String) async throws -> String

    /// Generate an embedding vector for the given text
    /// - Returns: Array of floats representing the embedding
    func generateEmbedding(text: String) async throws -> [Float]

    /// Whether this provider supports embeddings
    var supportsEmbeddings: Bool { get }

    /// Display name for the provider
    var name: String { get }
}

/// Errors that can occur when using AI providers
enum AIProviderError: LocalizedError {
    case networkError(String)
    case invalidResponse
    case authenticationFailed
    case modelNotAvailable
    case embeddingsNotSupported
    case apiError(String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let message): return "Network error: \(message)"
        case .invalidResponse: return "Invalid response from AI provider"
        case .authenticationFailed: return "Authentication failed. Check your API key."
        case .modelNotAvailable: return "Selected model is not available"
        case .embeddingsNotSupported: return "This provider does not support embeddings"
        case .apiError(let message): return "API Error: \(message)"
        case .decodingError(let message): return "Decoding Error: \(message)"
        }
    }
}
