import Foundation
import SwiftData

class BackgroundAutomationManager {
    static let shared = BackgroundAutomationManager()

    private var timer: Timer?
    private let calendar = Calendar.current

    // Scheduled hours (8 AM and 5 PM)
    private let morningHour = 8
    private let afternoonHour = 17

    private init() {}

    func start(context: ModelContext, aiSettings: AISettings) {
        print("BackgroundAutomationManager: Starting scheduler...")

        // Run once on start to check if we missed a window
        checkAndRunAutomation(context: context, aiSettings: aiSettings)

        // Check every hour
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.checkAndRunAutomation(context: context, aiSettings: aiSettings)
        }
    }

    func checkAndRunAutomation(context: ModelContext, aiSettings: AISettings) {
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)

        // Determine which window we are in
        let window: String
        if currentHour >= morningHour && currentHour < morningHour + 2 {
            window = "morning"
        } else if currentHour >= afternoonHour && currentHour < afternoonHour + 2 {
            window = "afternoon"
        } else {
            return // Not in a window
        }

        // Check if already run today for this window
        let lastSyncKey = "last_sync_date_\(window)"
        if let lastSync = UserDefaults.standard.object(forKey: lastSyncKey) as? Date {
            if calendar.isDateInToday(lastSync) {
                print("BackgroundAutomationManager: Already synced for \(window) today.")
                return
            }
        }

        print("BackgroundAutomationManager: Starting \(window) automated synthesis...")

        Task {
            let engine = NewsEngine.shared
            do {
                // 1. Fetch
                try await engine.fetchAllFeeds(context: context)

                // 2. Synthesize
                _ = try await engine.synthesizeStories(context: context, provider: aiSettings.currentProvider)

                // 3. Cleanup
                try engine.cleanupOldArticles(context: context)

                // 4. Update last sync date
                UserDefaults.standard.set(Date(), forKey: lastSyncKey)
                print("BackgroundAutomationManager: \(window) automation completed successfully.")
            } catch {
                print("BackgroundAutomationManager: \(window) automation failed: \(error)")
            }
        }
    }
}
