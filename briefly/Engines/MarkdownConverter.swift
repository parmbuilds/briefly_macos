import Foundation
import SwiftSoup

class MarkdownConverter {
    static let shared = MarkdownConverter()

    private init() {}

    func convert(html: String) -> String {
        do {
            let doc = try SwiftSoup.parse(html)

            // 1. Extract Main Image (OG Image)
            let mainImageUrl = try extractMainImage(from: doc)

            // 2. Identify and Clean Main Content
            let mainContent = try extractMainContent(from: doc)

            // 3. Convert DOM to Markdown
            var markdown = ""

            // Prepend main image if found
            if let imageUrl = mainImageUrl, !imageUrl.isEmpty {
                markdown += "![](\(imageUrl))\n\n"
            }

            markdown += try convertNode(mainContent)

            // 4. Final Cleanup
            return cleanWhitespace(markdown)

        } catch {
            print("MarkdownConverter: Error parsing HTML: \(error)")
            // Fallback: Return original HTML stripped of tags if parsing fails heavily?
            // Or just return empty string to avoid showing raw HTML junk.
            return "Error: Could not parse content."
        }
    }

    // MARK: - Extractor Helpers

    private func extractMainImage(from doc: Document) throws -> String? {
        // Try OpenGraph image
        if let ogImage = try? doc.select("meta[property=og:image]").first(),
           let src = try? ogImage.attr("content"), !src.isEmpty {
            return src
        }
        // Try Twitter image
        if let twitterImage = try? doc.select("meta[name=twitter:image]").first(),
           let src = try? twitterImage.attr("content"), !src.isEmpty {
            return src
        }
        return nil
    }

    private func extractMainContent(from doc: Document) throws -> Element {
        // 1. Remove obvious junk globally
        try removeJunk(from: doc)

        // 2. Try to find semantic content containers
        let contentSelectors = [
            "article",
            "[role='main']",
            ".article-body",
            ".post-content",
            ".entry-content",
            ".content",
            "#content",
            ".main-content"
        ]

        for selector in contentSelectors {
            if let element = try? doc.select(selector).first() {
                // Simple heuristic: must have some substantial text
                if (try? element.text().count) ?? 0 > 100 {
                   return element
                }
            }
        }

        // 3. Fallback: Body
        guard let body = doc.body() else {
            return doc
        }
        return body
    }

    private func removeJunk(from doc: Element) throws {
        let junkSelectors = [
            "script", "style", "iframe", "noscript",
            ".ad", ".advertisement", ".banner",
            ".sidebar", ".widget",
            ".nav", ".menu", "nav", "footer",
            ".promo", ".subscribe", ".related-posts",
            ".social-share", "#cookies", ".cookie-banner",
            ".is-hidden", ".hidden"
        ]

        for selector in junkSelectors {
            try doc.select(selector).remove()
        }
    }

    // MARK: - Conversion Logic

    private func convertNode(_ node: Node) throws -> String {
        if let textNode = node as? TextNode {
            // Collapse excessive internal whitespace in text nodes, but keep leading/trailing if significant?
            // HTML collapsing rule: sequence of whitespace = single space.
            // We'll trust SwiftSoup's text() for elements, but here we are manual.
            let text = textNode.getWholeText()
            return text.replacingOccurrences(of: "[\\s\\n]+", with: " ", options: .regularExpression)
        }

        if let element = node as? Element {
            return try convertElement(element)
        }

        return ""
    }

    private func convertElement(_ element: Element) throws -> String {
        let tag = element.tagName().lowercased()

        switch tag {
        case "h1": return "\n\n# " + (try convertChildren(of: element)) + "\n"
        case "h2": return "\n\n## " + (try convertChildren(of: element)) + "\n"
        case "h3": return "\n\n### " + (try convertChildren(of: element)) + "\n"
        case "h4": return "\n\n#### " + (try convertChildren(of: element)) + "\n"
        case "h5", "h6": return "\n\n##### " + (try convertChildren(of: element)) + "\n"

        case "p": return "\n\n" + (try convertChildren(of: element)) + "\n"
        case "br": return "  \n" // Markdown line break
        case "hr": return "\n\n---\n\n"

        case "b", "strong": return "**" + (try convertChildren(of: element)).trimmingCharacters(in: .whitespaces) + "**"
        case "i", "em": return "_" + (try convertChildren(of: element)).trimmingCharacters(in: .whitespaces) + "_"

        case "a":
            let text = try convertChildren(of: element).trimmingCharacters(in: .whitespaces)
            let href = try element.attr("href")
            return "[\(text)](\(href))"

        case "img":
            let alt = try element.attr("alt")
            let src = try element.attr("src")
            return "\n![\(alt)](\(src))\n"

        case "ul": return "\n" + (try convertList(element, ordered: false)) + "\n"
        case "ol": return "\n" + (try convertList(element, ordered: true)) + "\n"
        case "li": return "- " + (try convertChildren(of: element)) + "\n" // Fallback if li not in ul/ol

        case "blockquote": return "\n> " + (try convertChildren(of: element)) + "\n"
        case "pre", "code":
             // Simplification: assume block code for pre, inline for code?
             // Usually code inside pre is block.
             if tag == "pre" {
                 return "\n```\n" + (try element.text()) + "\n```\n"
             }
             return "`" + (try element.text()) + "`"

        case "table": return try convertTable(element)

        case "div", "span", "section", "article", "main":
            return try convertChildren(of: element)

        default:
            // Just return children content for unknown tags
            return try convertChildren(of: element)
        }
    }

    private func convertChildren(of element: Element) throws -> String {
        var result = ""
        for child in element.getChildNodes() {
            result += try convertNode(child)
        }
        return result
    }

    private func convertList(_ list: Element, ordered: Bool) throws -> String {
        var result = ""
        let items = try list.select("li")
        for (index, item) in items.enumerated() {
            let content = try convertChildren(of: item).trimmingCharacters(in: .whitespacesAndNewlines)
            let prefix = ordered ? "\(index + 1). " : "- "
            result += "\(prefix)\(content)\n"
        }
        return result
    }

    private func convertTable(_ table: Element) throws -> String {
        var markdown = "\n"

        let rows = try table.select("tr")
        if rows.isEmpty() { return "" }

        // Headers
        if let headerRow = rows.first() {
            var headers: [String] = []
            // Try th first
            var cols = try headerRow.select("th")
            if cols.isEmpty() {
                // If no th, try td of first row
                cols = try headerRow.select("td")
            }

            for col in cols {
                headers.append(try col.text().trimmingCharacters(in: .whitespacesAndNewlines))
            }

            // Build Header Line
            markdown += "| " + headers.joined(separator: " | ") + " |\n"

            // Build Separator Line
            let separators = headers.map { _ in "---" }
            markdown += "| " + separators.joined(separator: " | ") + " |\n"

            // Data Rows (skip first if we used it as header and it was th? complicated.
            // Simple approach: if we found th, we assume theadow/tbody split or first row is header.
            // Let's iterate all valid rows that are not the header row object)

            for row in rows {
                if row == headerRow { continue }

                let cells = try row.select("td, th")
                if cells.isEmpty() { continue } // Skip if no data cells

                var rowData: [String] = []
                for cell in cells {
                    rowData.append(try convertChildren(of: cell).trimmingCharacters(in: .whitespacesAndNewlines))
                }
                markdown += "| " + rowData.joined(separator: " | ") + " |\n"
            }
        }

        return markdown + "\n"
    }

    private func cleanWhitespace(_ text: String) -> String {
        // Remove massive gaps but keep paragraph breaks
        let paragraphs = text.components(separatedBy: "\n")
        let cleaned = paragraphs.map { $0.trimmingCharacters(in: .whitespaces) }

        // Reconstruct: avoid more than 2 newlines
        var result = ""
        var newlineCount = 0

        for line in cleaned {
            if line.isEmpty {
                newlineCount += 1
            } else {
                if newlineCount > 0 {
                    result += "\n\n"
                    newlineCount = 0
                } else if !result.isEmpty {
                    // Single newline between non-empty lines?
                    // Markdown ignores single newlines mostly, but let's keep them as spaces or breaks?
                    // Better to just add a newline if we are strict, or space if flowing.
                    // Our standard above adds \n for elements.
                    result += "\n"
                }
                result += line
            }
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
