import SwiftUI
import SwiftData

struct DashboardView: View {
    let stories: [Story]
    var title: String = "Latest Briefs"
    var subtitle: String = "Stay informed with your top 10 synthesised stories."

    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 400), spacing: 24)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title.uppercased())
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.blue)
                        .tracking(2)

                    Text(subtitle)
                        .font(.custom("Iowan Old Style", size: 24).weight(.bold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 8)

                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(stories.filter(\.isQualityBrief)) { story in
                        NavigationLink(value: story) {
                            StoryCard(story: story)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(32)
        }
    }
}

struct StoryCard: View {
    let story: Story
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Header (Only if available)
            if let imageURL = story.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 140)
                            .clipped()
                    default:
                        // No placeholder for cleaner look
                        EmptyView()
                    }
                }
            } else {
                // Subtle accent bar for text-only cards
                Rectangle()
                    .fill(categoryColor.opacity(0.3))
                    .frame(height: 4)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(story.clusterDate, style: .date)
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)

                    Spacer()

                    if let category = story.articles.first?.source?.category {
                        Text(category.name.uppercased())
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(categoryColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(categoryColor.opacity(0.1))
                            .cornerRadius(4)
                    }
                }

                Text(story.title)
                    .font(.custom("Iowan Old Style", size: 18).weight(.bold))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if story.imageURL == nil {
                    // Show more hook text if no image
                    Text(story.hook)
                        .font(.custom("Iowan Old Style", size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                } else {
                    Text(story.hook)
                        .font(.custom("Iowan Old Style", size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 12)

                HStack {
                    HStack(spacing: -6) {
                        ForEach(Array(story.articles.prefix(3))) { article in
                            Circle()
                                .fill(Color(NSColor.windowBackgroundColor))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Text(String(article.source?.name.prefix(1) ?? "?"))
                                        .font(.system(size: 8, weight: .bold))
                                )
                                .shadow(radius: 1)
                        }
                    }

                    Spacer()

                    Text(sourceCountText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
        }
        .frame(minHeight: 220)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovering ? categoryColor.opacity(0.3) : Color.primary.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isHovering ? 0.08 : 0.03), radius: isHovering ? 12 : 4, x: 0, y: isHovering ? 6 : 2)
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var sourceCountText: String {
        let count = story.articles.count
        return count == 1 ? "1 source" : "\(count) sources"
    }

    private var categoryColor: Color {
        let colors: [Color] = [.blue, .purple, .orange, .green, .pink, .indigo]
        if let category = story.articles.first?.source?.category {
            let index = abs(category.name.hashValue) % colors.count
            return colors[index]
        }
        return .blue
    }
}
