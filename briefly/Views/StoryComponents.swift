import SwiftUI
import SwiftData
import MarkdownUI

struct StoryContentView: View {
    let story: Story
    @ObservedObject var settings: ReadingSettings

    var body: some View {
        HStack(alignment: .top, spacing: 64) {
            // Left Column: Title, Hook, Facts, Context
            VStack(alignment: .leading, spacing: 32) {
                Text(story.title)
                    .font(.custom("Iowan Old Style", size: settings.fontSize * 2.25).weight(.bold))
                    .lineLimit(3)
                    .lineSpacing(settings.lineSpacing * 2)
                    .kerning(settings.characterSpacing)
                    .multilineTextAlignment(settings.getTextAlignment())
                    .fixedSize(horizontal: false, vertical: true)

                if !story.hook.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.blue)
                            Text("THE HOOK")
                                .font(.system(size: 12, weight: .black))
                                .kerning(1.2)
                                .foregroundStyle(.blue)
                        }

                        Markdown(story.hook)
                            .markdownTextStyle {
                                FontSize(settings.fontSize * 1.25)
                                FontWeight(.medium)
                                FontFamily(.custom("Iowan Old Style"))
                            }
                            .lineSpacing(settings.lineSpacing * 5)
                            .kerning(settings.characterSpacing)
                            .multilineTextAlignment(settings.getTextAlignment())
                    }
                    .padding(24)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(4)
                    .overlay(
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 4),
                        alignment: .leading
                    )
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("THE FACTS")
                        .font(.system(size: 12, weight: .black))
                        .kerning(1.2)
                        .foregroundStyle(.secondary)

                    ForEach(story.facts, id: \.self) { fact in
                        HStack(alignment: .top, spacing: 14) {
                            Text("•")
                                .font(.title3)
                                .foregroundStyle(.blue)
                            Markdown(fact)
                                .markdownTextStyle {
                                    FontSize(settings.fontSize)
                                    FontFamily(.custom("Iowan Old Style"))
                                }
                                .lineSpacing(settings.lineSpacing * 10 - 10)
                                .kerning(settings.characterSpacing)
                                .multilineTextAlignment(settings.getTextAlignment())
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if !story.context.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("THE CONTEXT")
                            .font(.system(size: 12, weight: .black))
                            .kerning(1.2)
                            .foregroundStyle(.secondary)

                        Markdown(story.context)
                            .markdownTextStyle {
                                FontSize(settings.fontSize)
                                FontFamily(.custom("Iowan Old Style"))
                                ForegroundColor(.secondary)
                            }
                            .lineSpacing(settings.lineSpacing * 5)
                            .kerning(settings.characterSpacing)
                            .multilineTextAlignment(settings.getTextAlignment())
                    }
                }
            }

            // Right Column: Image, Metadata, and Sources
            VStack(alignment: .leading, spacing: 24) {
                if let imageURL = story.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 350, height: 250)
                                .clipped()
                                .cornerRadius(4)
                        } else {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.05))
                                .frame(width: 350, height: 250)
                                .cornerRadius(4)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    if let category = story.articles.first?.source?.category {
                        Text(category.name.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .kerning(1.5)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(2)
                    }

                    Text(story.clusterDate, style: .date)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                }

                Divider()

                SourcesSection(articles: story.articles, settings: settings)
            }
            .frame(width: 350)
        }
    }
}

struct StoryDetailView: View {
    let story: Story
    @ObservedObject var settings: ReadingSettings

    var body: some View {
        ScrollView {
            StoryContentView(story: story, settings: settings)
                .padding(32)
                .frame(maxWidth: 1200)
                .frame(maxWidth: .infinity)
        }
    }
}

struct ArticleDetailView: View {
    let article: Article
    @ObservedObject var settings: ReadingSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(article.source?.name.uppercased() ?? "SOURCE")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.5)
                        .foregroundStyle(.blue)

                    Text(article.title)
                        .font(.custom("Iowan Old Style", size: settings.fontSize * 2.25).weight(.bold))
                        .lineSpacing(settings.lineSpacing * 2)
                        .kerning(settings.characterSpacing)
                        .multilineTextAlignment(settings.getTextAlignment())
                }

                Divider()

                Markdown(article.originalContent)
                    .markdownTheme(dynamicTheme)
                    .lineSpacing(settings.lineSpacing * 10 - 10)
                    .kerning(settings.characterSpacing)
                    .multilineTextAlignment(settings.getTextAlignment())
            }
            .padding(32)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
    }

    private var dynamicTheme: Theme {
        Theme.gitHub
            .text {
                FontSize(settings.fontSize)
                ForegroundColor(.primary)
            }
    }
}

struct StoryRow: View {
    let story: Story
    var onDelete: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(story.title)
                .font(.custom("Iowan Old Style", size: 16).weight(.bold))
                .lineLimit(2)
                .foregroundStyle(.primary)
            Text(story.clusterDate, style: .date)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete Story", systemImage: "trash")
            }
        }
    }
}

struct ArticleRow: View {
    let article: Article
    var onDelete: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(article.title)
                .font(.custom("Iowan Old Style", size: 14).weight(.bold))
                .lineLimit(2)
                .foregroundStyle(.primary)
            Text(article.source?.name.uppercased() ?? "Unknown Source")
                .font(.system(size: 9, weight: .black))
                .tracking(1)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete Article", systemImage: "trash")
            }
        }
    }
}
struct SourcesSection: View {
    let articles: [Article]
    @ObservedObject var settings: ReadingSettings
    @State private var selectedArticle: Article?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SOURCES")
                .font(.system(size: 12, weight: .black))
                .kerning(1.2)
                .foregroundStyle(.secondary)

            ForEach(articles) { article in
                Button {
                    selectedArticle = article
                } label: {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(article.title)
                                .font(.custom("Iowan Old Style", size: 16).weight(.bold))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)

                            Text(article.source?.name ?? "External Source")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.blue)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(item: $selectedArticle) { article in
            NavigationStack {
                ArticleDetailView(article: article, settings: settings)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                selectedArticle = nil
                            }
                        }
                        ToolbarItem(placement: .primaryAction) {
                            if let url = URL(string: article.url) {
                                Link(destination: url) {
                                    Label("Open in Browser", systemImage: "safari")
                                }
                            }
                        }
                    }
            }
            .frame(minWidth: 1000, minHeight: 700)
        }
    }
}
