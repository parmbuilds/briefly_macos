import Foundation
import SwiftData

struct ScrapedArticleData: Sendable {
    let title: String
    let content: String
    let url: String
    let publishDate: Date
    let imageURL: String?
}

class NewsEngine {
    static let shared = NewsEngine()

    init() {}

    func fetchAllFeeds(context: ModelContext) async throws {
        print("NewsEngine: Fetching all feeds...")
        let descriptor = FetchDescriptor<Source>()
        let sources = try context.fetch(descriptor)

        for source in sources {
            do {
                let scrapedData = try await fetchArticles(url: source.url, type: source.type, name: source.name)
                for data in scrapedData {
                    // Check if article already exists
                    let url = data.url
                    let articleDescriptor = FetchDescriptor<Article>(predicate: #Predicate { $0.url == url })
                    let existing = try context.fetch(articleDescriptor)

                    if existing.isEmpty {
                        let article = Article(
                            title: data.title,
                            originalContent: data.content,
                            url: data.url,
                            publishDate: data.publishDate,
                            imageURL: data.imageURL
                        )
                        article.source = source
                        context.insert(article)
                    }
                }
            } catch {
                print("NewsEngine: Failed to fetch \(source.name): \(error)")
            }
        }
        try context.save()
    }

    func fetchArticles(url: String, type: String, name: String) async throws -> [ScrapedArticleData] {
        print("NewsEngine: Fetching articles for URL: \(url) (\(type))")
        if type == "rss" {
            guard let feedURL = URL(string: url) else {
                throw NSError(domain: "NewsEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid RSS URL"])
            }
            return try await fetchRSSArticles(from: feedURL)
        } else {
            // For custom URLs and Videos, we fetch the content immediately
            let content = try await fetchContent(url: url, type: type)
            print("NewsEngine: Content fetched, length: \(content.count)")
            return [
                ScrapedArticleData(
                    title: name,
                    content: content,
                    url: url,
                    publishDate: Date(),
                    imageURL: nil
                )
            ]
        }
    }

    private func fetchRSSArticles(from url: URL) async throws -> [ScrapedArticleData] {
        let (data, _) = try await URLSession.shared.data(from: url)
        let parser = RSSParser()
        let rssItems = parser.parse(data: data)
        print("NewsEngine: Parsed \(rssItems.count) items from RSS feed \(url)")

        let topItems = Array(rssItems.prefix(5))

        return await withTaskGroup(of: ScrapedArticleData?.self) { group in
            for item in topItems {
                group.addTask {
                    guard let itemURL = URL(string: item.link) else { return nil }

                    var content = item.description
                    do {
                        print("NewsEngine: Deep scraping concurrently: \(item.link)")
                        let fullContent = try await Scraper.shared.scrape(url: itemURL)
                        if !fullContent.isEmpty {
                            content = fullContent
                        }
                    } catch {
                        print("NewsEngine: Scrape failed for \(item.link), using description")
                    }

                    return ScrapedArticleData(
                        title: item.title,
                        content: content,
                        url: item.link,
                        publishDate: item.pubDate ?? Date(),
                        imageURL: item.imageURL
                    )
                }
            }

            var results: [ScrapedArticleData] = []
            for await scraped in group {
                if let scraped = scraped {
                    results.append(scraped)
                }
            }
            // Sort by date as they might return out of order
            return results.sorted { $0.publishDate > $1.publishDate }
        }
    }

    private func fetchContent(url urlString: String, type: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "NewsEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        if type == "youtube" {
            return try await YouTubeProcessor.shared.extractTranscript(from: url)
        } else {
            return try await Scraper.shared.scrape(url: url)
        }
    }

    // MARK: - AI Synthesis

    func synthesizeStories(context: ModelContext, provider: AIProvider) async throws -> [Story] {
        print("NewsEngine: Starting synthesis...")

        // Fetch all unsynthesized articles
        let descriptor = FetchDescriptor<Article>(
            predicate: #Predicate { $0.story == nil }
        )
        let articles = try context.fetch(descriptor)

        guard !articles.isEmpty else {
            print("NewsEngine: No articles to synthesize")
            return []
        }

        let engine = SynthesisEngine(provider: provider)
        let stories = try await engine.synthesizeStories(from: articles, context: context)

        print("NewsEngine: Created \(stories.count) stories")
        return stories
    }

    @MainActor
    func seedSampleData(context: ModelContext) {
        // Check if data already exists
        let categoryDescriptor = FetchDescriptor<Category>()
        if let count = try? context.fetchCount(categoryDescriptor), count > 0 {
            return
        }

        // Create Categories
        let tech = Category(name: "Technology", iconName: "cpu")
        let finance = Category(name: "Finance", iconName: "dollarsign.circle")
        let crypto = Category(name: "Crypto", iconName: "bitcoinsign.circle")
        let business = Category(name: "Business", iconName: "briefcase")
        let science = Category(name: "Science", iconName: "atom")
        let space = Category(name: "Space", iconName: "star")
        let economics = Category(name: "Economics", iconName: "chart.line.uptrend.xyaxis")

        [tech, finance, crypto, business, science, space, economics].forEach { context.insert($0) }

        // Curated Sources
        let sources = [
            // Tech
            Source(name: "The Verge", url: "https://www.theverge.com/rss/index.xml", type: "rss"),
            Source(name: "Wired", url: "https://www.wired.com/feed/rss", type: "rss"),
            Source(name: "TechCrunch", url: "https://techcrunch.com/feed/", type: "rss"),

            // Finance
            Source(name: "CNBC Finance", url: "https://www.cnbc.com/id/10000664/device/rss/rss.html", type: "rss"),

            // Crypto
            Source(name: "CoinDesk", url: "https://www.coindesk.com/arc/outboundfeeds/rss/", type: "rss"),
            Source(name: "Cointelegraph", url: "https://cointelegraph.com/rss", type: "rss"),

            // Business
            Source(name: "WSJ Business", url: "https://feeds.a.dj.com/rss/WSJcomUSBusiness.xml", type: "rss"),

            // Science
            Source(name: "Scientific American", url: "https://www.scientificamerican.com/feed/rss/", type: "rss"),

            // Space
            Source(name: "NASA News", url: "https://www.nasa.gov/rss/dyn/breaking_news.rss", type: "rss"),
            Source(name: "Space.com", url: "https://www.space.com/feeds/all", type: "rss"),

            // Economics
            Source(name: "The Economist", url: "https://www.economist.com/sections/economics/rss.xml", type: "rss"),
            Source(name: "Economist Intelligence", url: "https://www.economist.com/the-world-ahead/rss.xml", type: "rss")
        ]

        // Map sources to categories
        sources[0...2].forEach { $0.category = tech }
        sources[3...3].forEach { $0.category = finance }
        sources[4...5].forEach { $0.category = crypto }
        sources[6...6].forEach { $0.category = business }
        sources[7...7].forEach { $0.category = science }
        sources[8...9].forEach { $0.category = space }
        sources[10...11].forEach { $0.category = economics }

        sources.forEach { context.insert($0) }

        // Create initial sample data for "All Stories" view
        let sampleArticle = Article(
            title: "Welcome to Briefly",
            originalContent: "This is your daily synthesis. Briefly aggregates your favorite sources and condenses them into smart, scannable summaries.",
            url: "https://briefly.app",
            publishDate: Date(),
            imageURL: "https://images.unsplash.com/photo-1512314889357-e157c22f938d?q=80&w=800&auto=format&fit=crop"
        )
        sampleArticle.source = sources[0]
        context.insert(sampleArticle)

        let welcomeStory = Story(
            title: "Your First Synthesis",
            summary: "Start your morning with a curated brief of everything you care about.",
            clusterDate: Date(),
            hook: "Stay informed, stay brief.",
            facts: [
                "Briefly aggregates RSS, Newsletters, and Video.",
                "Smart Brevity logic extracts 'The Hook', 'The Facts', and 'The Context'.",
                "Procedural Podcasting is coming soon."
            ],
            context: "Designed for high-output professionals who need to stay ahead of the curve.",
            imageURL: "https://images.unsplash.com/photo-1512314889357-e157c22f938d?q=80&w=800&auto=format&fit=crop"
        )
        welcomeStory.articles = [sampleArticle]
        context.insert(welcomeStory)

        try? context.save()
    }
}
