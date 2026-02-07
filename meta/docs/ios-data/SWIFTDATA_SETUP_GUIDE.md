# SwiftData Setup Guide

## 1. Update App Entry Point

Update `PlenaApp.swift` to configure SwiftData:

```swift
import SwiftUI
import SwiftData

@main
struct PlenaApp: App {
    // Configure SwiftData with CloudKit sync (optional but recommended)
    let modelContainer: ModelContainer = {
        let schema = Schema([
            MeditationSessionData.self,
            HeartRateSampleData.self,
            HRVSampleData.self,
            RespiratoryRateSampleData.self,
            StateOfMindLogData.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        // Enable CloudKit sync for iPhone/Watch sharing
        // Note: Requires CloudKit capability in Xcode
        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
```

## 2. Update Minimum iOS Version

In Xcode project settings:

- Set **iOS Deployment Target** to **17.0**
- Set **watchOS Deployment Target** to **10.0** (watchOS 10 supports SwiftData)

## 3. Enable CloudKit (Optional but Recommended)

1. In Xcode, select your project
2. Go to **Signing & Capabilities**
3. Add **CloudKit** capability
4. This enables automatic sync between iPhone and Watch

## 4. Update ViewModels to Use SwiftData

Example update for `MeditationSessionViewModel`:

```swift
import SwiftData

@MainActor
class MeditationSessionViewModel: ObservableObject {
    // ... existing properties ...

    private let modelContext: ModelContext
    private let storageService: SwiftDataStorageServiceProtocol

    init(
        healthKitService: HealthKitServiceProtocol,
        modelContext: ModelContext
    ) {
        self.healthKitService = healthKitService
        self.modelContext = modelContext
        self.storageService = SwiftDataStorageService(modelContext: modelContext)
    }

    // ... rest of implementation uses storageService ...
}
```

## 5. Pass ModelContext to Views

In your views, use `@Environment(\.modelContext)`:

```swift
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        MeditationSessionView(
            healthKitService: HealthKitService(),
            modelContext: modelContext
        )
    }
}
```

## 6. One-Time Migration from JSON

Add migration check in app startup:

```swift
@main
struct PlenaApp: App {
    // ... modelContainer setup ...

    init() {
        // Check if migration is needed
        checkAndMigrateIfNeeded()
    }

    private func checkAndMigrateIfNeeded() {
        let userDefaults = UserDefaults.standard
        if !userDefaults.bool(forKey: "hasMigratedToSwiftData") {
            // Perform migration
            let modelContext = modelContainer.mainContext
            let storageService = SwiftDataStorageService(modelContext: modelContext)

            do {
                try storageService.migrateFromJSON()
                userDefaults.set(true, forKey: "hasMigratedToSwiftData")
            } catch {
                print("Migration failed: \(error)")
            }
        }
    }

    // ... body ...
}
```



