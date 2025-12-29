# Changelog

All notable changes to the **Briefly** macOS app will be documented in this file.

## [Unreleased] - 2025-12-29

### Added

- **RSS Feed Integration**: Implemented a native RSS/Atom parser and added background fetching logic.
- **Curated Feeds**: Seeded the app with high-quality default sources for Tech, Finance, Crypto, Business, Science, and Space.
- **Enhanced Add Source UI**: Added a source type picker (RSS, YouTube, Web) with intelligent auto-detection.
- **Initial Project Structure**: Setup native SwiftUI macOS project with SwiftData integration.
- **Data Models**: Created SwiftData models for `Category`, `Source`, `Article`, and `Story`.
- **Navigation Layout**: Implemented a 3-column `NavigationSplitView` (Sidebar, Content, Detail).
- **Smart Brevity UI**: Developed a detail view for synthesized briefings including "The Hook", "The Facts", and "The Context" sections.
- **News Engine**: Added a foundational `NewsEngine` class for data management and sample data seeding.
- **Documentation**: Added an implementation plan and a phase 1 walkthrough in the `brain` artifacts.

### Changed

- Refactored `ContentView.swift` from a simple list to a professional news briefing interface.
- Updated `brieflyApp.swift` to support the new data schema.
- Moved the "Add Source" button from the toolbar to a more prominent location at the top of the sidebar list for better visibility.

### Fixed

- Resolved "Initializer for conditional binding must have Optional type" error in `ContentView.swift` regarding `article.publishDate`.
- Resolved "Cannot find 'Item' in scope" build error by updating the `#Preview` block in `ContentView.swift` to use the new data models.
- Cleaned up documentation linting issues in `Architecture.md` and `BuildAndTest.md`.

### Removed

- Removed the default `Item.swift` template model.
