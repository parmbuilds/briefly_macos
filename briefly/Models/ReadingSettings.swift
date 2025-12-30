import SwiftUI
import Combine

class ReadingSettings: ObservableObject {
    @Published var fontSize: Double {
        didSet { UserDefaults.standard.set(fontSize, forKey: "reading_fontSize") }
    }

    @Published var lineSpacing: Double {
        didSet { UserDefaults.standard.set(lineSpacing, forKey: "reading_lineSpacing") }
    }

    @Published var characterSpacing: Double {
        didSet { UserDefaults.standard.set(characterSpacing, forKey: "reading_characterSpacing") }
    }

    @Published var textAlignment: String {
        didSet { UserDefaults.standard.set(textAlignment, forKey: "reading_textAlignment") }
    }

    init() {
        let savedSize = UserDefaults.standard.double(forKey: "reading_fontSize")
        self.fontSize = savedSize > 0 ? savedSize : 16.0

        let savedLines = UserDefaults.standard.double(forKey: "reading_lineSpacing")
        self.lineSpacing = savedLines > 0 ? savedLines : 1.4

        // Character spacing can be 0 or negative, so check for existence differently or just default to 0 if not set?
        // UserDefaults double returns 0 if not found.
        // We'll trust 0 is fine, but we might want to check if it was ever set?
        // For simplicity, 0.0 default is fine.
        self.characterSpacing = UserDefaults.standard.double(forKey: "reading_characterSpacing")

        self.textAlignment = UserDefaults.standard.string(forKey: "reading_textAlignment") ?? "Leading"
    }

    func getTextAlignment() -> TextAlignment {
        switch textAlignment {
        case "Center": return .center
        case "Trailing": return .trailing
        default: return .leading
        }
    }
}
