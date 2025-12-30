import SwiftUI
import Combine

enum AIProviderType: String, CaseIterable, Identifiable {
    case ollama = "Ollama"
    case openai = "OpenAI"
    case claude = "Claude"
    case apple = "Apple (On-device)"

    var id: String { rawValue }
}

class AISettings: ObservableObject {
    // Provider selection
    @Published var providerType: AIProviderType {
        didSet {
            UserDefaults.standard.set(providerType.rawValue, forKey: "ai_providerType")
        }
    }

    // Ollama settings
    @Published var ollamaBaseURL: String {
        didSet { UserDefaults.standard.set(ollamaBaseURL, forKey: "ai_ollamaBaseURL") }
    }

    @Published var ollamaModel: String {
        didSet { UserDefaults.standard.set(ollamaModel, forKey: "ai_ollamaModel") }
    }

    // Auto-synthesis
    @Published var autoSynthesize: Bool {
        didSet { UserDefaults.standard.set(autoSynthesize, forKey: "ai_autoSynthesize") }
    }

    init() {
        // Load saved settings
        if let savedProvider = UserDefaults.standard.string(forKey: "ai_providerType"),
           let type = AIProviderType(rawValue: savedProvider) {
            self.providerType = type
        } else {
            self.providerType = .ollama
        }

        self.ollamaBaseURL = UserDefaults.standard.string(forKey: "ai_ollamaBaseURL") ?? "http://localhost:11434"
        self.ollamaModel = UserDefaults.standard.string(forKey: "ai_ollamaModel") ?? "llama3.2"
        self.autoSynthesize = UserDefaults.standard.bool(forKey: "ai_autoSynthesize")
    }

    // API key methods (stored in Keychain for security)
    func getOpenAIKey() -> String? {
        return KeychainHelper.retrieve(key: "ai_openai_key")
    }

    func setOpenAIKey(_ key: String) {
        KeychainHelper.save(key: "ai_openai_key", value: key)
    }

    func getClaudeKey() -> String? {
        return KeychainHelper.retrieve(key: "ai_claude_key")
    }

    func setClaudeKey(_ key: String) {
        KeychainHelper.save(key: "ai_claude_key", value: key)
    }
}

// Simple Keychain helper
class KeychainHelper {
    static func save(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }
}
