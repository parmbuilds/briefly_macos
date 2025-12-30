import SwiftUI
import SwiftData
import MarkdownUI

struct DailyBriefsView: View {
    @Query(sort: \Story.clusterDate, order: .reverse) private var stories: [Story]
    let globalToolbar: AnyView

    var body: some View {
        NavigationStack {
            DailyBriefsDocumentView(stories: stories)
                .toolbar {
                    ToolbarItem {
                        globalToolbar
                    }
                }
        }
    }
}

struct DailyBriefsDocumentView: View {
    let stories: [Story]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 60) {
                VStack(alignment: .center, spacing: 8) {
                    Text("Daily Briefs")
                        .font(.system(size: 40, weight: .black))
                    Text(Date(), style: .date)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
                .padding(.bottom, 20)

                Divider()

                ForEach(stories) { story in
                    VStack(alignment: .leading, spacing: 32) {
                        StoryContentView(story: story)

                        if story.id != stories.last?.id {
                            HStack {
                                Spacer()
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 100, height: 1)
                                Spacer()
                            }
                            .padding(.vertical, 20)
                        }
                    }
                }
            }
            .padding(40)
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity)
        }
    }
}
