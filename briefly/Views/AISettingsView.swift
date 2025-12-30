import SwiftUI

struct AISettingsView: View {
    @ObservedObject var settings: AISettings
    @State private var openAIKey: String = ""
    @State private var claudeKey: String = ""
    @State private var testResult: String = ""
    @State private var isTesting: Bool = false

    var body: some View {
        Form {
            Section("AI Provider") {
                Picker("Provider", selection: $settings.providerType) {
                    ForEach(AIProviderType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Provider-specific settings
            switch settings.providerType {
            case .ollama:
                ollamaSettings
            case .openai:
                openAISettings
            case .claude:
                claudeSettings
            case .apple:
                appleSettings
            }

            Section("Synthesis") {
                Toggle("Auto-synthesize on refresh", isOn: $settings.autoSynthesize)
                    .help("Automatically generate story syntheses when fetching new articles")
            }

            if !testResult.isEmpty {
                Section("Test Result") {
                    Text(testResult)
                        .foregroundStyle(testResult.contains("Success") ? .green : .red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 350)
        .onAppear {
            loadAPIKeys()
        }
    }

    private var ollamaSettings: some View {
        Section("Ollama Configuration") {
            TextField("Base URL", text: $settings.ollamaBaseURL)
                .textFieldStyle(.roundedBorder)

            TextField("Model", text: $settings.ollamaModel)
                .textFieldStyle(.roundedBorder)

            Text("Common models: llama3.2, mistral, phi3")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(action: testOllamaConnection) {
                HStack {
                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                    Text("Test Connection")
                }
            }
            .disabled(isTesting)
        }
    }

    private var openAISettings: some View {
        Section("OpenAI Configuration") {
            SecureField("API Key", text: $openAIKey)
                .textFieldStyle(.roundedBorder)
                .onChange(of: openAIKey) { _, newValue in
                    if !newValue.isEmpty {
                        settings.setOpenAIKey(newValue)
                    }
                }

            Link("Get API Key", destination: URL(string: "https://platform.openai.com/api-keys")!)
                .font(.caption)
        }
    }

    private var claudeSettings: some View {
        Section("Claude Configuration") {
            SecureField("API Key", text: $claudeKey)
                .textFieldStyle(.roundedBorder)
                .onChange(of: claudeKey) { _, newValue in
                    if !newValue.isEmpty {
                        settings.setClaudeKey(newValue)
                    }
                }

            Link("Get API Key", destination: URL(string: "https://console.anthropic.com/")!)
                .font(.caption)
        }
    }

    private var appleSettings: some View {
        Section("Apple On-Device ML") {
            Text("Uses local inference powered by Gemma 3 1B.")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Unquantized Gemma 3 1B model")
                    Spacer()
                    if ModelManager.shared.isDownloading {
                        ProgressView(value: ModelManager.shared.downloadProgress)
                            .frame(width: 100)
                    } else if ModelManager.shared.isModelAvailable {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Text("Status: \(ModelManager.shared.modelStatus)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Download / Load Model") {
                Task {
                    do {
                        _ = try await ModelManager.shared.loadModel()
                    } catch {
                        ModelManager.shared.modelStatus = "Error: \(error.localizedDescription)"
                    }
                }
            }
            .disabled(ModelManager.shared.isDownloading)
        }
    }

    private func loadAPIKeys() {
        openAIKey = settings.getOpenAIKey() ?? ""
        claudeKey = settings.getClaudeKey() ?? ""
    }

    private func testOllamaConnection() {
        isTesting = true
        testResult = ""

        Task {
            do {
                let provider = OllamaProvider(
                    baseURL: settings.ollamaBaseURL,
                    model: settings.ollamaModel
                )

                let response = try await provider.generateCompletion(prompt: "Say 'OK' if you can read this.")
                testResult = "✓ Success: \(response.prefix(50))..."
            } catch {
                testResult = "✗ Error: \(error.localizedDescription)"
            }

            isTesting = false
        }
    }
}
