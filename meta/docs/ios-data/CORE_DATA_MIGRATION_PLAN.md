# Core Data Migration Plan

## Decision: Switch from SwiftData to Core Data

**Reason**: SwiftData is failing even with minimal models, suggesting a device/configuration issue. Core Data is more stable and proven.

## Benefits of Core Data

- ✅ Works on iOS 16.0+ (broader device support)
- ✅ More mature and stable
- ✅ Better documentation and examples
- ✅ Proven reliability
- ✅ Better debugging tools
- ✅ More control over data model

## Implementation Plan

### Step 1: Create Core Data Model File
- Create `PlenaDataModel.xcdatamodeld`
- Define entities: MeditationSession, HeartRateSample, HRVSample, RespiratoryRateSample, StateOfMindLog
- Set up relationships with proper delete rules

### Step 2: Generate NSManagedObject Subclasses
- Create managed object classes
- Or use Codegen: Class Definition

### Step 3: Create Core Data Stack
- NSPersistentContainer setup
- Background context support
- Migration handling

### Step 4: Update Storage Service
- Replace SwiftDataStorageService with CoreDataStorageService
- Keep same protocol interface
- Maintain compatibility with existing code

### Step 5: Update App Setup
- Remove SwiftData ModelContainer
- Add Core Data stack initialization
- Update migration logic

## Estimated Time
- 2-3 hours for full migration
- All existing functionality preserved
- Same data structure and relationships

## Next Steps

Would you like me to:
1. **Create Core Data implementation** (recommended)
2. **Continue debugging SwiftData** (may take longer, uncertain outcome)

I recommend Option 1 - Core Data will work reliably and you'll have a functioning app sooner.




