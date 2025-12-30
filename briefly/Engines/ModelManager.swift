import Foundation
import MLX
import MLXLLM
import MLXLMCommon

/// Manages downloading and loading of local LLM models
@Observable
class ModelManager {
    static let shared = ModelManager()

    var downloadProgress: Double = 0
    var isDownloading: Bool = false
    var modelStatus: String = "Ready to download"
    var lastError: String?

    let defaultModelId = "mlx-community/gemma-2-2b-it-4bit"
    var modelContainer: ModelContainer?

    private init() {}

    var isModelAvailable: Bool {
        return modelContainer != nil
    }

    func loadModel() async throws -> ModelContainer {
        if let container = modelContainer {
            return container
        }

        await MainActor.run {
            modelStatus = "Loading model..."
        }

        // Standard ModelConfiguration initialization
        // If this still fails, we might need to rely on the library's default loader via Registry
        let config = ModelConfiguration(id: defaultModelId)

        let container = try await LLMModelFactory.shared.loadContainer(
            configuration: config,
            progressHandler: { progress in
                Task { @MainActor in
                    self.downloadProgress = progress.fractionCompleted
                    self.isDownloading = true
                    self.modelStatus = "Downloading: \(Int(progress.fractionCompleted * 100))%"
                }
            }
        )

        self.modelContainer = container

        await MainActor.run {
            self.isDownloading = false
            self.modelStatus = "Model Loaded"
        }

        return container
    }

    func generate(prompt: String, container: ModelContainer) async throws -> String {
        let parameters = GenerateParameters(temperature: 0.6)

        // Use LMInput directly.
        // We create it essentially empty or with default init if available, then set properties
        // to avoid "No exact matches in call to initializer" if the label arguments are tricky.
        var input = LMInput()
        input.text = prompt

        return try await container.perform { context in
            let result = try await MLXLMCommon.generate(
                input: input,
                parameters: parameters,
                context: context
            )
            return result.output
        }
    }
}
