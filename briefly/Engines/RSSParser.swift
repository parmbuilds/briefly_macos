import Foundation

struct RSSItem {
    var title: String = ""
    var link: String = ""
    var description: String = ""
    var pubDate: Date?
}

class RSSParser: NSObject, XMLParserDelegate {
    private var parser: XMLParser?
    private var items: [RSSItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDescription = ""
    private var currentPubDate = ""

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // Common RSS date formats
        return formatter
    }()

    func parse(data: Data) -> [RSSItem] {
        items = []
        parser = XMLParser(data: data)
        parser?.delegate = self
        parser?.parse()
        return items
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if currentElement == "item" || currentElement == "entry" {
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
            currentPubDate = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title": currentTitle += string
        case "link": currentLink += string
        case "description", "content", "summary": currentDescription += string
        case "pubDate", "published", "updated": currentPubDate += string
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" || elementName == "entry" {
            let item = RSSItem(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                description: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                pubDate: parseDate(currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines))
            )
            items.append(item)
        }
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss z",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        ]

        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }
}
