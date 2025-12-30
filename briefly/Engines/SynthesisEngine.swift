import Foundation
import SwiftData

/// Engine for synthesizing news stories from multiple articles
class SynthesisEngine {
    private let provider: AIProvider

    init(provider: AIProvider) {
        self.provider = provider
    }

    // MARK: - Main Synthesis Flow

    /// Cluster and synthesize articles into stories
    func synthesizeStories(from articles: [Article], context: ModelContext) async throws -> [Story] {
        print("SynthesisEngine: Starting synthesis for \(articles.count) articles")

        // Filter unsynthesized articles from this week
        let unsynthesized = articles.filter { article in
            article.story == nil && isFromCurrentWeek(article.publishDate)
        }

        guard !unsynthesized.isEmpty else {
            print("SynthesisEngine: No unsynthesized articles from this week")
            return []
        }

        // Generate embeddings for articles that don't have them
        try await generateEmbeddings(for: unsynthesized)
        try context.save() // Save embeddings to persist progress

        // Cluster articles by similarity
        let clusters = try clusterArticles(unsynthesized)
        print("SynthesisEngine: Created \(clusters.count) clusters")

        // Generate story for each cluster
        var stories: [Story] = []
        for cluster in clusters {
            // Allow single articles to become stories if they are significant enough
            // Upper bound keeps prompt size manageable
            guard !cluster.isEmpty && cluster.count <= 10 else {
                print("SynthesisEngine: Skipping cluster with \(cluster.count) articles")
                continue
            }

            let story = try await synthesizeStory(from: cluster)

            // Link articles to story
            for article in cluster {
                article.story = story
            }

            context.insert(story)
            stories.append(story)
        }

        try context.save()
        return stories
    }

    // MARK: - Embedding Generation

    private func generateEmbeddings(for articles: [Article]) async throws {
        for article in articles where article.embedding == nil {
            let text = "\(article.title)\n\(article.originalContent.prefix(1000))"
            let vector = try await provider.generateEmbedding(text: text)
            article.embedding = encodeVector(vector)
            print("SynthesisEngine: Generated embedding for '\(article.title.prefix(50))'")
        }
    }

    // MARK: - Clustering

    private func clusterArticles(_ articles: [Article]) throws -> [[Article]] {
        guard !articles.isEmpty else { return [] }

        var clusters: [[Article]] = []
        var assigned = Set<String>()

        for article in articles {
            guard !assigned.contains(article.url) else { continue }

            var cluster = [article]
            assigned.insert(article.url)

            // Find similar articles
            for other in articles {
                guard !assigned.contains(other.url) else { continue }

                if let similarity = try? cosineSimilarity(article, other),
                   similarity > 0.75 { // Threshold for same story
                    cluster.append(other)
                    assigned.insert(other.url)
                }
            }

            clusters.append(cluster)
        }

        return clusters
    }

    private func cosineSimilarity(_ a: Article, _ b: Article) throws -> Float {
        guard let vecA = a.embedding, let vecB = b.embedding else {
            throw AIProviderError.invalidResponse
        }

        let embedA = decodeVector(vecA)
        let embedB = decodeVector(vecB)

        guard embedA.count == embedB.count else {
            throw AIProviderError.invalidResponse
        }

        var dotProduct: Float = 0
        var magnitudeA: Float = 0
        var magnitudeB: Float = 0

        for i in 0..<embedA.count {
            dotProduct += embedA[i] * embedB[i]
            magnitudeA += embedA[i] * embedA[i]
            magnitudeB += embedB[i] * embedB[i]
        }

        let magnitude = sqrt(magnitudeA) * sqrt(magnitudeB)
        return magnitude > 0 ? dotProduct / magnitude : 0
    }

    // MARK: - Story Synthesis

    private func synthesizeStory(from articles: [Article]) async throws -> Story {
        let prompt = buildSynthesisPrompt(articles: articles)
        let response = try await provider.generateCompletion(prompt: prompt)

        // Parse response into Smart Brevity format
        let parsed = parseSmartBrevity(response)

        // Pick a representative image from the articles
        let imageURL = articles.first(where: { $0.imageURL != nil })?.imageURL

        let story = Story(
            title: parsed.title,
            summary: response,
            clusterDate: Date(),
            hook: parsed.hook,
            facts: parsed.facts,
            context: parsed.context,
            imageURL: imageURL
        )

        story.articles = articles

        return story
    }

    private func buildSynthesisPrompt(articles: [Article]) -> String {
        var prompt = """
        You are a professional news synthesizer using the Smart Brevity format.

        Analyze these \(articles.count) articles on the same topic from different sources and create a synthesis:

        """

        for (index, article) in articles.enumerated() {
            let source = article.source?.name ?? "Unknown"
            let preview = article.originalContent.prefix(500)
            prompt += """

            Article \(index + 1) (\(source)):
            Title: \(article.title)
            Content: \(preview)...

            """
        }

        prompt += """

        Create a synthesis in Smart Brevity format:

        TITLE: A clear, compelling headline (max 10 words)

        HOOK: One powerful sentence that captures why this matters (1 sentence only)

        FACTS: 3-5 key bullet points covering:
        - What different sources are reporting
        - Where sources agree or disagree
        - Notable quotes or data points

        CONTEXT: Why this story matters, background the reader needs (2-3 sentences)

        Format your response EXACTLY like this:
        TITLE: [your title]
        HOOK: [your hook]
        FACTS:
        • [fact 1]
        • [fact 2]
        • [fact 3]
        CONTEXT: [your context]
        """

        return prompt
    }

    private func parseSmartBrevity(_ response: String) -> (title: String, hook: String, facts: [String], context: String) {
        var title = "Untitled Story"
        var hook = ""
        var facts: [String] = []
        var context = ""

        let lines = response.components(separatedBy: .newlines)
        var currentSection = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("TITLE:") {
                title = trimmed.replacingOccurrences(of: "TITLE:", with: "").trimmingCharacters(in: .whitespaces)
                currentSection = "title"
            } else if trimmed.hasPrefix("HOOK:") {
                hook = trimmed.replacingOccurrences(of: "HOOK:", with: "").trimmingCharacters(in: .whitespaces)
                currentSection = "hook"
            } else if trimmed.hasPrefix("FACTS:") {
                currentSection = "facts"
            } else if trimmed.hasPrefix("CONTEXT:") {
                context = trimmed.replacingOccurrences(of: "CONTEXT:", with: "").trimmingCharacters(in: .whitespaces)
                currentSection = "context"
            } else if currentSection == "facts" && (trimmed.hasPrefix("•") || trimmed.hasPrefix("-")) {
                let fact = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                facts.append(fact)
            } else if currentSection == "context" && !trimmed.isEmpty {
                context += " " + trimmed
            }
        }

        return (title, hook, facts, context)
    }

    // MARK: - Helpers

    private func isFromCurrentWeek(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return false
        }

        return date >= weekStart
    }

    private func encodeVector(_ vector: [Float]) -> Data {
        var data = Data()
        for value in vector {
            withUnsafeBytes(of: value) { bytes in
                data.append(contentsOf: bytes)
            }
        }
        return data
    }

    private func decodeVector(_ data: Data) -> [Float] {
        var vector: [Float] = []
        let count = data.count / MemoryLayout<Float>.size

        for i in 0..<count {
            let start = i * MemoryLayout<Float>.size
            let end = start + MemoryLayout<Float>.size
            let slice = data[start..<end]
            let value = slice.withUnsafeBytes { $0.load(as: Float.self) }
            vector.append(value)
        }

        return vector
    }
}
