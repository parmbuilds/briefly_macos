import Foundation

class AppleMLProvider: AIProvider {
    var name: String { "Apple On-Device (Disabled)" }
    var supportsEmbeddings: Bool { false }

    private let modelManager = ModelManager.shared

    func generateCompletion(prompt: String) async throws -> String {
        throw AIProviderError.networkError("Provider is currently disabled")
    }

    func generateEmbedding(text: String) async throws -> [Float] {
        throw AIProviderError.embeddingsNotSupported
    }
}
