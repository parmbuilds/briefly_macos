import SwiftUI
import SwiftData
import MarkdownUI

struct DailyBriefsView: View {
    @Query(sort: \Story.clusterDate, order: .reverse) private var stories: [Story]
    let globalToolbar: AnyView
    @ObservedObject var settings: ReadingSettings

    var body: some View {
        NavigationStack {
            DailyBriefsDocumentView(stories: stories.filter(\.isQualityBrief), settings: settings)
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
    @ObservedObject var settings: ReadingSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .center, spacing: 12) {
                    Text("Daily Briefs")
                        .font(.custom("Iowan Old Style", size: 48).weight(.black))

                    HStack {
                        Rectangle()
                            .fill(Color.primary.opacity(0.1))
                            .frame(height: 1)

                        Text(Date().formatted(date: .long, time: .omitted))
                            .font(.custom("Iowan Old Style", size: 18).italic())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .fixedSize(horizontal: true, vertical: false)

                        Rectangle()
                            .fill(Color.primary.opacity(0.1))
                            .frame(height: 1)
                    }
                    .frame(maxWidth: 500)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .padding(.bottom, 10)

                Divider()

                ForEach(stories) { story in
                    VStack(alignment: .leading, spacing: 32) {
                        StoryContentView(story: story, settings: settings)

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
            .padding(.vertical, 40)
            .padding(.horizontal, 24)
            .frame(maxWidth: 1400)
            .frame(maxWidth: .infinity)
        }
    }
}
