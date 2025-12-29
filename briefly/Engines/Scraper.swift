import Foundation

class Scraper {
    static let shared = Scraper()

    private init() {}

    func scrape(url: URL) async throws -> String {
        print("Scraper: Starting scrape for \(url)")
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("Scraper: Invalid response for \(url)")
            throw NSError(domain: "Scraper", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
        }

        print("Scraper: Received status code \(httpResponse.statusCode) for \(url)")

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Scraper", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned error: \(httpResponse.statusCode)"])
        }

        guard let html = String(data: data, encoding: .utf8) else {
            print("Scraper: Failed to decode content for \(url)")
            throw NSError(domain: "Scraper", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to decode content from \(url.host ?? "server")"])
        }

        let cleanedText = MarkdownConverter.shared.convert(html: html)
        print("Scraper: Successfully converted HTML to Markdown (\(cleanedText.count) characters) from \(url)")
        return cleanedText
    }

}
