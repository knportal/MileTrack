# Xcode Build Phase Setup Instructions

## Fixing the "Run Script" Warning

When you add the build phase script, Xcode will show this warning:

> "Run script build phase 'Run Script' will be run during every build because it does not specify any outputs."

## Solution: Disable Dependency Analysis (Recommended)

The simplest and most reliable solution:

1. In Xcode, select the **Plena** target
2. Go to **Build Phases** tab
3. Find your **"Ensure Files in Project"** script phase
4. Expand it to show the settings
5. **Uncheck "Based on dependency analysis"**

This tells Xcode to always run the script, which is fine because:
- The script is fast (only runs when files need adding)
- Avoids path/sandboxing issues with output files
- Ensures files are always checked before building

## Alternative: Use Output Files (Advanced)

If you want dependency analysis, you can specify an output file, but use a relative path:

1. In the script phase settings
2. In **Output Files**, click **+** and add:
   ```
   $(SRCROOT)/Plena.xcodeproj/project.pbxproj
   ```

**Note**: Some Xcode versions may have issues with `.xcodeproj` paths in output files. If you see "stale file" errors, use the first solution instead.

## Recommended Configuration

**Disable dependency analysis** (first option) - This is the most reliable and avoids path issues.

## Verification

After adding the output file:
1. The warning should disappear
2. The script will only run when `project.pbxproj` might need updating
3. Builds should be slightly faster when no files need adding

