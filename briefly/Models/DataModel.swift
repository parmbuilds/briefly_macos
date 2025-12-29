import Foundation
import SwiftData

@Model
final class Category {
    var name: String
    var iconName: String
    @Relationship(deleteRule: .cascade) var sources: [Source] = []

    init(name: String, iconName: String = "folder") {
        self.name = name
        self.iconName = iconName
    }
}

@Model
final class Source {
    var name: String
    var url: String
    var type: String // "rss", "newsletter", "youtube"
    var category: Category?
    @Relationship(deleteRule: .cascade) var articles: [Article] = []

    init(name: String, url: String, type: String = "rss") {
        self.name = name
        self.url = url
        self.type = type
    }
}

@Model
final class Article {
    var title: String
    var originalContent: String
    var url: String
    var publishDate: Date
    var source: Source?
    var story: Story?

    init(title: String, originalContent: String, url: String, publishDate: Date) {
        self.title = title
        self.originalContent = originalContent
        self.url = url
        self.publishDate = publishDate
    }
}

@Model
final class Story {
    var title: String
    var summary: String
    var clusterDate: Date
    @Relationship(deleteRule: .nullify) var articles: [Article] = []

    // Smart Brevity components (could be parsed from summary or separate fields)
    var hook: String
    var facts: [String]
    var context: String

    init(title: String, summary: String, clusterDate: Date, hook: String = "", facts: [String] = [], context: String = "") {
        self.title = title
        self.summary = summary
        self.clusterDate = clusterDate
        self.hook = hook
        self.facts = facts
        self.context = context
    }
}
