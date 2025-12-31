import Foundation
import SwiftData

class FeedSyncEngine {
    static let shared = FeedSyncEngine()

    private init() {}

    func syncFeeds(context: ModelContext) async throws {
        print("FeedSyncEngine: Starting sync...")

        let fileURL = Bundle.main.url(forResource: "rss_feeds", withExtension: "md") ??
                      URL(fileURLWithPath: "/Users/parm/Documents/learning/briefly_app/briefly_macos/briefly/docs/rss_feeds.md")

        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            print("FeedSyncEngine: Could not find or read rss_feeds.md")
            return
        }

        let sections = content.components(separatedBy: .newlines)
        var currentCategory: Category?

        for line in sections {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Detect Category Headers (e.g., "Science Feeds")
            if trimmed.localizedCaseInsensitiveContains("Feeds") && !trimmed.contains("http") {
                let catName = trimmed.replacingOccurrences(of: " Feeds", with: "", options: .caseInsensitive)
                currentCategory = try getOrCreateCategory(name: catName, context: context)
                continue
            }

            // Skip if no category yet
            guard let category = currentCategory else { continue }

            // Match Name: URL format
            if trimmed.contains(": https://") {
                let parts = trimmed.components(separatedBy: ": https://")
                if parts.count >= 2 {
                    let name = parts[0].trimmingCharacters(in: .whitespaces)
                    let url = "https://" + parts[1].trimmingCharacters(in: .whitespaces)
                    try syncSource(name: name, url: url, category: category, context: context)
                }
            }
            // Match embedded URLs (e.g., "Engadget (https://url.xml)")
            else if trimmed.contains("https://") && trimmed.contains("(") && trimmed.contains(")") {
                let pattern = #"([a-zA-Z\s]+)\s*\((https?://[^\s\)]+)\)"#
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
                    let matches = regex.matches(in: trimmed, range: range)

                    for match in matches {
                        if match.numberOfRanges >= 3,
                           let nameRange = Range(match.range(at: 1), in: trimmed),
                           let urlRange = Range(match.range(at: 2), in: trimmed) {
                            let name = String(trimmed[nameRange]).trimmingCharacters(in: .whitespaces)
                            let url = String(trimmed[urlRange])
                            try syncSource(name: name, url: url, category: category, context: context)
                        }
                    }
                }
            }
        }

        try context.save()
        print("FeedSyncEngine: Sync completed.")
    }

    private func getOrCreateCategory(name: String, context: ModelContext) throws -> Category {
        let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.name == name })
        if let existing = try context.fetch(descriptor).first {
            return existing
        }

        // Default icons for known categories
        let icon: String
        switch name.lowercased() {
        case "science": icon = "atom"
        case "ai": icon = "cpu"
        case "technology": icon = "laptopcomputer"
        case "finance & business": icon = "briefcase"
        case "cryptocurrency": icon = "bitcoinsign.circle"
        case "nature": icon = "leaf"
        case "gardening": icon = "camera.macro"
        default: icon = "folder"
        }

        let newCat = Category(name: name, iconName: icon)
        context.insert(newCat)
        return newCat
    }

    private func syncSource(name: String, url: String, category: Category, context: ModelContext) throws {
        let descriptor = FetchDescriptor<Source>(predicate: #Predicate { $0.url == url })
        if let existing = try context.fetch(descriptor).first {
            existing.name = name
            existing.category = category
        } else {
            let newSource = Source(name: name, url: url, type: "rss")
            newSource.category = category
            context.insert(newSource)
            print("FeedSyncEngine: Added new source: \(name)")
        }
    }
}
