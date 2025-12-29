import SwiftUI
import SwiftData

struct CuratedFeed: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let categoryName: String
    let description: String
}

struct DiscoverFeedsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingSources: [Source]
    @Query private var categories: [Category]

    @State private var isProcessing = false

    let curatedFeeds: [CuratedFeed] = [
        // Tech
        CuratedFeed(name: "The Verge", url: "https://www.theverge.com/rss/index.xml", categoryName: "Technology", description: "Tech, science, art, and culture."),
        CuratedFeed(name: "Wired", url: "https://www.wired.com/feed/rss", categoryName: "Technology", description: "Deep dives into tech trends."),
        CuratedFeed(name: "TechCrunch", url: "https://techcrunch.com/feed/", categoryName: "Technology", description: "Startup and technology news."),

        // Finance
        CuratedFeed(name: "CNBC Finance", url: "https://www.cnbc.com/id/10000664/device/rss/rss.html", categoryName: "Finance", description: "Real-time business news and financial market data."),

        // Crypto
        CuratedFeed(name: "CoinDesk", url: "https://www.coindesk.com/arc/outboundfeeds/rss/", categoryName: "Crypto", description: "Leader in crypto and blockchain news."),
        CuratedFeed(name: "Cointelegraph", url: "https://cointelegraph.com/rss", categoryName: "Crypto", description: "The latest news about bitcoin, ethereum, and blockchain."),

        // Business
        CuratedFeed(name: "WSJ Business", url: "https://feeds.a.dj.com/rss/WSJcomUSBusiness.xml", categoryName: "Business", description: "Breaking business news and analysis."),

        // Science
        CuratedFeed(name: "Scientific American", url: "https://www.scientificamerican.com/feed/rss/", categoryName: "Science", description: "The most awe-inspiring advances in science and technology."),

        // Space
        CuratedFeed(name: "NASA News", url: "https://www.nasa.gov/rss/dyn/breaking_news.rss", categoryName: "Space", description: "Latest news from the space agency."),
        CuratedFeed(name: "Space.com", url: "https://www.space.com/feeds/all", categoryName: "Space", description: "The leading source for space exploration."),

        // Economics
        CuratedFeed(name: "The Economist", url: "https://www.economist.com/sections/economics/rss.xml", categoryName: "Economics", description: "Global economic news and analysis."),
        CuratedFeed(name: "Freakonomics", url: "https://freakonomics.com/feed/", categoryName: "Economics", description: "The hidden side of everything.")
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(uniqueCategories, id: \.self) { categoryName in
                    Section(header: Text(categoryName)) {
                        ForEach(feedsInCategory(categoryName)) { feed in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(feed.name)
                                        .font(.headline)
                                    Text(feed.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if isAdded(feed) {
                                    Button("Remove") {
                                        removeFeed(feed)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.red)
                                } else {
                                    Button("Add") {
                                        addFeed(feed)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Discover Top Stories")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isProcessing {
                    ProgressView("Scraping initial stories...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
        .onDisappear {
            isProcessing = false
        }
    }

    private var uniqueCategories: [String] {
        Array(Set(curatedFeeds.map { $0.categoryName })).sorted()
    }

    private func feedsInCategory(_ name: String) -> [CuratedFeed] {
        curatedFeeds.filter { $0.categoryName == name }
    }

    private func isAdded(_ feed: CuratedFeed) -> Bool {
        existingSources.contains { $0.url == feed.url }
    }

    private func addFeed(_ feed: CuratedFeed) {
        // Find or create category
        var category = categories.first { $0.name == feed.categoryName }
        if category == nil {
            category = Category(name: feed.categoryName)
            modelContext.insert(category!)
        }

        let newSource = Source(name: feed.name, url: feed.url, type: "rss")
        newSource.category = category
        modelContext.insert(newSource)

        // Start scraping
        Task {
            let sName = newSource.name
            let sURL = newSource.url
            let sType = newSource.type
            let sID = newSource.persistentModelID

            isProcessing = true
            do {
                let engine = NewsEngine.shared
                let scrapedData = try await engine.fetchArticles(url: sURL, type: sType, name: sName)
                await MainActor.run {
                    if let source = modelContext.model(for: sID) as? Source {
                        for data in scrapedData {
                            let article = Article(
                                title: data.title,
                                originalContent: data.content,
                                url: data.url,
                                publishDate: data.publishDate
                            )
                            article.source = source
                            modelContext.insert(article)
                        }
                        try? modelContext.save()
                    }
                    isProcessing = false
                }
            } catch {
                print("Discovery: Failed to fetch for \(sName): \(error)")
                await MainActor.run { isProcessing = false }
            }
        }
    }

    private func removeFeed(_ feed: CuratedFeed) {
        if let source = existingSources.first(where: { $0.url == feed.url }) {
            modelContext.delete(source)
            try? modelContext.save()
        }
    }
}

#Preview {
    DiscoverFeedsView()
}
