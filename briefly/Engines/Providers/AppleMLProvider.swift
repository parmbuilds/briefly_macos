import Foundation
import MLX
import MLXLLM

class AppleMLProvider: AIProvider {
    var name: String { "Apple On-Device (Gemma 2 2B)" }
    var supportsEmbeddings: Bool { false } // Not supporting embeddings yet

    private let modelManager = ModelManager.shared

    func generateCompletion(prompt: String) async throws -> String {
        let container = try await modelManager.loadModel()
        return try await modelManager.generate(prompt: prompt, container: container)
    }

    func generateEmbedding(text: String) async throws -> [Float] {
        throw AIProviderError.embeddingsNotSupported
    }
}
