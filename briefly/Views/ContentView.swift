import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Story.clusterDate, order: .reverse) private var stories: [Story]
    @Query(sort: \Article.publishDate, order: .reverse) private var articles: [Article]

    @State private var selection: NavigationItem? = .dailyBriefs
    @State private var detailSelection: DetailSelection?
    @State private var navigationPath = NavigationPath()
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    @StateObject private var readingSettings = ReadingSettings()
    @StateObject private var aiSettings = AISettings()
    @State private var isShowingReadingSettings = false
    @State private var isShowingAISettings = false
    @State private var isShowingAddSource = false
    @State private var isShowingDiscover = false

    enum NavigationItem: Hashable {
        case dailyBriefs
        case allStories
        case allArticles
        case category(Category)
    }

    enum DetailSelection: Hashable {
        case story(Story)
        case article(Article)
    }

    var body: some View {
        Group {
            if selection == .dailyBriefs {
                // 2-column layout: Sidebar + Document
                NavigationSplitView {
                    sidebar
                } detail: {
                    DailyBriefsDocumentView(stories: stories)
                        .toolbar {
                            ToolbarItem {
                                globalToolbar
                            }
                        }
                }
            } else {
                // 3-column layout: Sidebar + List + Detail
                NavigationSplitView {
                    sidebar
                } content: {
                    navigatorList
                } detail: {
                    detailColumn
                }
            }
        }
        .onChange(of: selection) {
            navigationPath = NavigationPath()
            detailSelection = nil
        }
        .onChange(of: detailSelection) {
            navigationPath = NavigationPath()
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        List(selection: $selection) {
            NavigationLink(value: NavigationItem.dailyBriefs) {
                Label("Daily Briefs", systemImage: "newspaper")
            }

            NavigationLink(value: NavigationItem.allStories) {
                Label("All Stories", systemImage: "tray.2")
            }

            NavigationLink(value: NavigationItem.allArticles) {
                Label("All Articles", systemImage: "list.dash")
            }

            Button(action: { isShowingAddSource = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Add Source")
                        .font(.headline)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            Section("Categories") {
                ForEach(categories) { category in
                    NavigationLink(value: NavigationItem.category(category)) {
                        Label(category.name, systemImage: category.iconName)
                    }
                }
            }

            Section {
                Button(action: { isShowingDiscover = true }) {
                    Label("Discover Top Stories", systemImage: "sparkles")
                        .foregroundStyle(.purple)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Briefly")
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private var navigatorList: some View {
        List(selection: $detailSelection) {
            switch selection {
            case .allStories:
                if stories.isEmpty {
                    ContentUnavailableView("No Stories", systemImage: "newspaper", description: Text("Synthesize your feed to see stories."))
                } else {
                    ForEach(groupedStories, id: \.0) { bucket, storiesInBucket in
                        Section(bucket) {
                            ForEach(storiesInBucket) { story in
                                StoryRow(story: story)
                                    .tag(DetailSelection.story(story))
                            }
                        }
                    }
                }

            case .allArticles:
                ForEach(groupedArticlesByCategory, id: \.0?.id) { category, articlesInCategory in
                    Section(category?.name ?? "Other Sources") {
                        ForEach(articlesInCategory) { article in
                            ArticleRow(article: article)
                                .tag(DetailSelection.article(article))
                        }
                    }
                }

            case .category(let category):
                ForEach(groupedArticlesBySource(for: category), id: \.0?.id) { source, articlesInSource in
                    Section(source?.name ?? "Unknown Source") {
                        ForEach(articlesInSource) { article in
                            ArticleRow(article: article)
                                .tag(DetailSelection.article(article))
                        }
                    }
                }

            default:
                EmptyView()
            }
        }
        .navigationTitle(navigationTitle)
    }

    @ViewBuilder
    private var detailColumn: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if let detailSelection {
                    switch detailSelection {
                    case .story(let story):
                        StoryDetailView(story: story)
                    case .article(let article):
                        ArticleDetailView(article: article, settings: readingSettings)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "newspaper")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text("Select a Story or Article")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Choose something from the list to start reading.")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationDestination(for: Story.self) { story in
                StoryDetailView(story: story)
            }
            .navigationDestination(for: Article.self) { article in
                ArticleDetailView(article: article, settings: readingSettings)
            }
            .toolbar {
                ToolbarItem {
                    globalToolbar
                }
            }
        }
    }

    @ViewBuilder
    private var globalToolbar: some View {
        HStack {
            Button(action: { isShowingAISettings = true }) {
                Label("AI Settings", systemImage: "brain")
            }
            .popover(isPresented: $isShowingAISettings) {
                AISettingsView(settings: aiSettings)
            }

            Button(action: synthesizeStories) {
                Label("Synthesize", systemImage: "sparkles")
            }
            .help("Generate story syntheses from articles")

            Button(action: { isShowingReadingSettings = true }) {
                Label("Reading Settings", systemImage: "textformat.size")
            }
            .popover(isPresented: $isShowingReadingSettings) {
                ReadingSettingsView(settings: readingSettings)
            }

            Button(action: refreshStories) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
    }

    private var navigationTitle: String {
        switch selection {
        case .allStories: return "All Stories"
        case .allArticles: return "All Articles"
        case .category(let category): return category.name
        default: return "Briefly"
        }
    }

    // --- Helper Logic (Moved from previous implementation) ---

    private var groupedStories: [(String, [Story])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let groups = Dictionary(grouping: stories) { story in
            let date = calendar.startOfDay(for: story.clusterDate)
            if date == today { return "Today" }
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), date == yesterday { return "Yesterday" }
            return "Earlier"
        }

        return ["Today", "Yesterday", "Earlier"].compactMap { bucket in
            guard let items = groups[bucket], !items.isEmpty else { return nil }
            return (bucket, items.sorted { $0.clusterDate > $1.clusterDate })
        }
    }

    private var groupedArticlesByCategory: [(Category?, [Article])] {
        let groups = Dictionary(grouping: articles) { $0.source?.category }
        return groups.map { ($0.key, $0.value) }
            .sorted { ($0.0?.name ?? "") < ($1.0?.name ?? "") }
    }

    private func groupedArticlesBySource(for category: Category) -> [(Source?, [Article])] {
        let categoryArticles = articles.filter { $0.source?.category == category }
        let groups = Dictionary(grouping: categoryArticles) { $0.source }
        return groups.map { ($0.key, $0.value) }
            .sorted { ($0.0?.name ?? "") < ($1.0?.name ?? "") }
    }

    private func refreshStories() {
        Task {
            let engine = NewsEngine()
            try? await engine.fetchAllFeeds(context: modelContext)
        }
    }

    private func synthesizeStories() {
        Task {
            let engine = NewsEngine()
            try? await engine.synthesizeStories(context: modelContext, provider: aiSettings.currentProvider)
        }
    }
}
