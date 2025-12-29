import Foundation

class MarkdownConverter {
    static let shared = MarkdownConverter()

    private init() {}

    func convert(html: String) -> String {
        var markdown = html

        // 1. Remove script and style tags entirely
        markdown = markdown.replacingOccurrences(of: "<script[\\s\\S]*?</script>", with: "", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: "<style[\\s\\S]*?</style>", with: "", options: .regularExpression)

        // 2. Headings
        markdown = markdown.replacingOccurrences(of: "<h1[^>]*>([\\s\\S]*?)</h1>", with: "\n# $1\n", options: [.regularExpression, .caseInsensitive])
        markdown = markdown.replacingOccurrences(of: "<h2[^>]*>([\\s\\S]*?)</h2>", with: "\n## $1\n", options: [.regularExpression, .caseInsensitive])
        markdown = markdown.replacingOccurrences(of: "<h3[^>]*>([\\s\\S]*?)</h3>", with: "\n### $1\n", options: [.regularExpression, .caseInsensitive])
        markdown = markdown.replacingOccurrences(of: "<h4[^>]*>([\\s\\S]*?)</h4>", with: "\n#### $1\n", options: [.regularExpression, .caseInsensitive])

        // 3. Bold / Strong
        markdown = markdown.replacingOccurrences(of: "<(strong|b)[^>]*>([\\s\\S]*?)</\\1>", with: "**$2**", options: [.regularExpression, .caseInsensitive])

        // 4. Italic / Emphasis
        markdown = markdown.replacingOccurrences(of: "<(em|i)[^>]*>([\\s\\S]*?)</\\1>", with: "_$2_", options: [.regularExpression, .caseInsensitive])

        // 5. Links
        markdown = markdown.replacingOccurrences(of: "<a[^>]+href=\"([^\"]+)\"[^>]*>([\\s\\S]*?)</a>", with: "[$2]($1)", options: [.regularExpression, .caseInsensitive])

        // 6. Lists
        markdown = markdown.replacingOccurrences(of: "<li[^>]*>([\\s\\S]*?)</li>", with: "\n- $1", options: [.regularExpression, .caseInsensitive])

        // 7. Paragraphs & Line breaks
        markdown = markdown.replacingOccurrences(of: "<p[^>]*>([\\s\\S]*?)</p>", with: "\n$1\n", options: [.regularExpression, .caseInsensitive])
        markdown = markdown.replacingOccurrences(of: "<br[^>]*>", with: "\n", options: [.regularExpression, .caseInsensitive])

        // 8. Blockquotes
        markdown = markdown.replacingOccurrences(of: "<blockquote[^>]*>([\\s\\S]*?)</blockquote>", with: "\n> $1\n", options: [.regularExpression, .caseInsensitive])

        // 9. Strip all remaining tags
        markdown = markdown.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // 10. Decode common HTML entities
        markdown = decodeEntities(markdown)

        // 11. Clean up excessive whitespace
        markdown = cleanWhitespace(markdown)

        return markdown
    }

    private func decodeEntities(_ text: String) -> String {
        var decoded = text
        let entities = [
            "&nbsp;": " ",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'",
            "&#39;": "'",
            "&rsquo;": "'",
            "&lsquo;": "'",
            "&rdquo;": "\"",
            "&ldquo;": "\"",
            "&mdash;": "—",
            "&ndash;": "–"
        ]

        for (entity, replacement) in entities {
            decoded = decoded.replacingOccurrences(of: entity, with: replacement)
        }

        return decoded
    }

    private func cleanWhitespace(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let cleanedLines = lines.map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Join with double newlines for paragraph separation, but try to avoid triple+ newlines
        return cleanedLines.joined(separator: "\n\n")
    }
}
