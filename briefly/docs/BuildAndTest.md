# Build and Test Guide: Briefly macOS

This document provides instructions for setting up the development environment, building the application, and verifying its functionality.

## 1. Prerequisites

To build and run the Briefly macOS app, you need:

- **macOS**: Sonoma (14.0) or later.
- **Xcode**: 15.0 or later.
- **Swift**: 5.9 or later.

## 2. Building the App

### Using Xcode (Recommended)

1. Open the project file: `briefly.xcodeproj`.
2. Select the `briefly` scheme from the toolbar.
3. Choose **My Mac** as the run destination.
4. Press `Cmd + R` to build and run the application.

### Using Command Line

If you prefer the terminal, you can build the project using `xcodebuild`:

```bash
xcodebuild -scheme briefly -destination 'platform=macOS' build
```

## 3. Testing and Verification

### 3.1 Data Seeding (Manual Verification)

The app includes a built-in seeding mechanism for testing the UI without a live backend connection.

1. Launch the app.
2. On first launch, the `NewsEngine` will automatically seed sample data.
3. Verify that the **Sidebar** displays "Technology" and "Finance" categories.
4. Verify that the **Story List** contains the "Apple's M4 MacBook Transition" story.
5. Click on the story to verify the **Smart Brevity UI** renders correctly in the detail view.

### 3.2 Running Unit Tests

Briefly uses XCTest for automated verification.

1. In Xcode, press `Cmd + U` to run all tests.
2. Alternatively, use the command line:

   ```bash
   xcodebuild -scheme briefly -destination 'platform=macOS' test
   ```

### 3.3 UI Testing

The project includes a `brieflyUITests` target for verifying user flows.

1. Run UI tests via the **Test Navigator** (`Cmd + 6`) in Xcode.
2. Verify that clicking through categories correctly updates the middle column.

## 4. Troubleshooting

- **SwiftData Issues**: If you experience crashes due to model changes, you may need to delete the app's local data container or increment the model version.
- **Build Errors**: Ensure you are using the latest version of Xcode and have the macOS SDK installed.
- **Missing Data**: If the list is empty on launch, check the console output for any errors during the `seedSampleData` call in `NewsEngine.swift`.

## 5. Development Workflow

1. **Feature Implementation**: Add new models to `DataModel.swift` and update the UI in `ContentView.swift`.
2. **Refresh Logic**: Use the "Refresh" button in the toolbar to simulate fetching new content (currently prints to console).
3. **Drafting Content**: You can modify `NewsEngine.swift` to add more diverse sample stories for testing different UI scenarios.
