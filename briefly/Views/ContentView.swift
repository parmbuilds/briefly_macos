//
//  ContentView.swift
//  briefly
//
//  Created by Parmpreet Singh on 29/12/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Story.clusterDate, order: .reverse) private var stories: [Story]
    @Query(sort: \Article.publishDate, order: .reverse) private var articles: [Article]

    @State private var selectedCategory: Category?
    @State private var selectedStory: Story?
    @State private var selectedArticle: Article?
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var isShowingAddSource = false
    @State private var isShowingDiscover = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar: Categories & Sources
            List(selection: $selectedCategory) {
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

                NavigationLink(value: nil as Category?) {
                    Label("All Stories", systemImage: "tray.2")
                }

                Section("Categories") {
                    Button(action: { isShowingDiscover = true }) {
                        Label("Discover Top Stories", systemImage: "sparkles")
                            .foregroundStyle(.purple)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)

                    ForEach(categories) { category in
                        NavigationLink(value: category) {
                            Label(category.name, systemImage: category.iconName)
                        }
                    }
                }
            }
            .navigationTitle("Briefly")
            .listStyle(.sidebar)
        } content: {
            // Middle Column: Story List
            List {
                if !filteredStories.isEmpty {
                    Section("Daily Briefs") {
                        ForEach(filteredStories) { story in
                            NavigationLink(value: story) {
                                StoryRow(story: story)
                            }
                        }
                    }
                }

                if selectedCategory == nil {
                    // "All Stories" view: Group articles by Category
                    ForEach(groupedArticlesByCategory, id: \.0?.id) { category, articlesInCategory in
                        Section(category?.name ?? "Other Sources") {
                            ForEach(articlesInCategory) { article in
                                NavigationLink(value: article) {
                                    ArticleRow(article: article)
                                }
                            }
                        }
                    }
                } else {
                    // Category view: Group articles by Source
                    ForEach(groupedArticlesBySource, id: \.0?.id) { source, articlesInSource in
                        Section(source?.name ?? "Unknown Source") {
                            ForEach(articlesInSource) { article in
                                NavigationLink(value: article) {
                                    ArticleRow(article: article)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(selectedCategory?.name ?? "Daily Brief")
            .navigationDestination(for: Story.self) { story in
                StoryDetailView(story: story)
            }
            .navigationDestination(for: Article.self) { article in
                ArticleDetailView(article: article)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: refreshStories) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }

        } detail: {
            // Detail Column: The Synthesis
            Text("Select an item to view details")
                .foregroundStyle(.secondary)
        }
        .onAppear {
            NewsEngine.shared.seedSampleData(context: modelContext)
        }
        .sheet(isPresented: $isShowingAddSource, onDismiss: { isShowingAddSource = false }) {
            AddSourceView()
        }
        .sheet(isPresented: $isShowingDiscover, onDismiss: { isShowingDiscover = false }) {
            DiscoverFeedsView()
        }
    }

    private func refreshStories() {
        // This will eventually trigger the Synthesis Engine
        print("Refreshing stories...")
    }

    private var filteredStories: [Story] {
        if let selectedCategory = selectedCategory {
            return stories.filter { story in
                story.articles.contains { $0.source?.category == selectedCategory }
            }
        }
        return stories
    }

    private var unsynthesizedArticles: [Article] {
        articles.filter { $0.story == nil }
    }

    private var groupedArticlesByCategory: [(Category?, [Article])] {
        let dictionary = Dictionary(grouping: unsynthesizedArticles) { $0.source?.category }
        return dictionary.sorted { (a, b) -> Bool in
            guard let aCat = a.key, let bCat = b.key else { return a.key != nil }
            return aCat.name < bCat.name
        }.map { ($0.key, $0.value) }
    }

    private var groupedArticlesBySource: [(Source?, [Article])] {
        guard let selectedCategory = selectedCategory else { return [] }
        let articlesInCategory = unsynthesizedArticles.filter { $0.source?.category == selectedCategory }
        let dictionary = Dictionary(grouping: articlesInCategory) { $0.source }
        return dictionary.sorted { (a, b) -> Bool in
            guard let aSrc = a.key, let bSrc = b.key else { return a.key != nil }
            return aSrc.name < bSrc.name
        }.map { ($0.key, $0.value) }
    }
}

struct StoryRow: View {
    let story: Story
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(story.title)
                .font(.headline)
                .lineLimit(2)
            Text(story.clusterDate, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ArticleRow: View {
    let article: Article
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(article.title)
                .font(.subheadline.bold())
                .lineLimit(1)
            Text(article.source?.name ?? "Unknown Source")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(article.publishDate, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct ArticleDetailView: View {
    let article: Article

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(article.source?.name ?? "Incoming Source")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(article.title)
                        .font(.largeTitle.bold())
                }

                Divider()

                Text(article.originalContent)
                    .font(.body)
                    .lineSpacing(6)
            }
            .padding(32)
            .frame(maxWidth: 800, alignment: .leading)
        }
    }
}

struct StoryDetailView: View {
    let story: Story

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if !story.hook.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("THE HOOK")
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                        Text(story.hook)
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("THE FACTS")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ForEach(story.facts, id: \.self) { fact in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .padding(.top, 8)
                            Text(fact)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if !story.context.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("THE CONTEXT")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(story.context)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("SOURCES")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ForEach(story.articles) { article in
                        Link(destination: URL(string: article.url)!) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(article.title)
                                        .lineLimit(1)
                                    Text(article.source?.name ?? "Unknown Source")
                                        .font(.caption)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: 800)
        }
        .navigationTitle("")
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(story.clusterDate, style: .date)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(story.title)
                .font(.system(size: 34, weight: .bold))
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Category.self, Source.self, Article.self, Story.self], inMemory: true)
}
