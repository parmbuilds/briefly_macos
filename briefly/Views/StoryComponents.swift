import SwiftUI
import SwiftData
import MarkdownUI

struct StoryContentView: View {
    let story: Story

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header

            if !story.hook.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("THE HOOK")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                    Markdown(story.hook)
                        .markdownTextStyle {
                            FontSize(20)
                            FontWeight(.medium)
                        }
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
                        Markdown(fact)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if !story.context.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("THE CONTEXT")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Markdown(story.context)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            SourcesSection(articles: story.articles)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(story.clusterDate, style: .date)
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)

                Spacer()

                if let category = story.articles.first?.source?.category {
                    Text(category.name.uppercased())
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .cornerRadius(4)
                }
            }

            Text(story.title)
                .font(.system(size: 34, weight: .bold))
                .lineLimit(3)

            if let imageURL = story.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 300)
                            .clipped()
                            .cornerRadius(12)
                    } else {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.1))
                            .frame(height: 300)
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
}

struct StoryDetailView: View {
    let story: Story

    var body: some View {
        ScrollView {
            StoryContentView(story: story)
                .padding(32)
                .frame(maxWidth: 800)
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
                VStack(alignment: .leading, spacing: 8) {
                    Text(article.source?.name ?? "Incoming Source")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(article.title)
                        .font(.largeTitle.bold())
                }

                Divider()

                Markdown(article.originalContent)
                    .markdownTheme(dynamicTheme)
                    .lineSpacing(settings.lineSpacing * 10 - 10)
                    .kerning(settings.characterSpacing)
                    .multilineTextAlignment(settings.getTextAlignment())
            }
            .padding(32)
            .frame(maxWidth: 800)
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
        }
        .padding(.vertical, 4)
    }
}
