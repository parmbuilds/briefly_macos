import SwiftUI
import SwiftData

struct AddSourceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Category.name) private var categories: [Category]

    @State private var urlString: String = ""
    @State private var selectedCategory: Category?
    @State private var sourceType: String = "rss"
    @State private var name: String = ""
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String?

    let sourceTypes = [
        ("RSS Feed", "rss"),
        ("YouTube Video", "youtube"),
        ("Web Page", "web")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Source Details") {
                    Picker("Source Type", selection: $sourceType) {
                        ForEach(sourceTypes, id: \.1) { label, value in
                            Text(label).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("URL", text: $urlString)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .onChange(of: urlString) { _, newValue in
                            autoDetectType(for: newValue)
                        }

                    TextField("Name (Optional)", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                Section("Category") {
                    Picker("Select Category", selection: $selectedCategory) {
                        Text("None").tag(nil as Category?)
                        ForEach(categories) { category in
                            Text(category.name).tag(category as Category?)
                        }
                    }
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Original Source")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addSource()
                    }
                    .disabled(urlString.isEmpty || isProcessing)
                }
            }
            .overlay {
                if isProcessing {
                    ProgressView("Processing...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 400)
    }

    private func autoDetectType(for url: String) {
        if url.contains("youtube.com") || url.contains("youtu.be") {
            sourceType = "youtube"
        } else if url.contains(".xml") || url.contains("/rss") || url.contains("/feed") {
            sourceType = "rss"
        }
    }

    private func addSource() {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }

        isProcessing = true
        errorMessage = nil

        let finalName = name.isEmpty ? (url.host ?? "New Source") : name
        let newSource = Source(name: finalName, url: urlString, type: sourceType)
        newSource.category = selectedCategory

        modelContext.insert(newSource)

        Task {
            let sourceName = newSource.name
            let sourceURL = newSource.url
            let sourceType = newSource.type
            let sourceID = newSource.persistentModelID

            print("AddSourceView: Starting background ingestion for \(sourceName)")
            do {
                let engine = NewsEngine.shared
                let scrapedData = try await engine.fetchArticles(url: sourceURL, type: sourceType, name: sourceName)
                print("AddSourceView: Fetched \(scrapedData.count) articles")

                await MainActor.run {
                    // Fetch the source again in the main actor context to be safe
                    if let source = modelContext.model(for: sourceID) as? Source {
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
                        print("AddSourceView: Successfully saved articles to database")
                    }
                }
            } catch {
                print("AddSourceView: Ingestion failed: \(error.localizedDescription)")
            }
        }

        dismiss()
    }
}

#Preview {
    AddSourceView()
        .modelContainer(for: [Category.self, Source.self], inMemory: true)
}
