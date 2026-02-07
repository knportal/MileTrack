# Placeholder Substitution Guide

This template uses placeholder tokens that must be replaced with your app-specific values before use.

## Required Placeholders

### App Identity
- `{{APP_NAME}}` - Your app's display name (e.g., "MyApp")
- `{{BUNDLE_ID}}` - Your app's bundle identifier (e.g., "com.company.myapp")
- `{{XCODE_PROJECT_NAME}}` - Your Xcode project name without .xcodeproj extension (e.g., "MyApp")

### Target Names
- `{{IOS_APP_TARGET}}` - Your iOS app target folder name (e.g., "MyApp")
- `{{WATCH_APP_TARGET}}` - Your watchOS app target folder name (e.g., "MyApp Watch App")
- `{{SHARED_TARGET}}` - Your shared code target folder name (e.g., "MyAppShared")

### Schemes (for test instructions / tooling)
- `{{IOS_SCHEME}}` - Your iOS scheme name (often same as app name, e.g., "MyApp")
- `{{WATCH_SCHEME}}` - Your watch scheme name (optional, e.g., "MyApp Watch App")

### Data Model
- `{{DATA_MODEL_NAME}}` - Your Core Data model name (e.g., "MyAppDataModel")

### Contact Information
- `{{SUPPORT_EMAIL}}` - Support email address (e.g., "support@example.com")
- `{{INFO_EMAIL}}` - General info email address (e.g., "info@example.com")
- `{{DOMAIN}}` - Your website domain (e.g., "example.com")

### URLs
- `{{PRIVACY_POLICY_URL}}` - Full URL to privacy policy (e.g., "https://example.com/privacy-policy")
- `{{SUPPORT_URL}}` - Full URL to support page (e.g., "https://example.com/support")

### Project Paths
- `{{PROJECT_ROOT}}` - Absolute path to your project root (e.g., "/Users/username/Projects/MyApp")

### App Store Metadata (Optional)
- `{{APP_SUBTITLE}}` - App Store subtitle (30 characters max)
- `{{PRIMARY_CATEGORY}}` - Primary App Store category
- `{{SECONDARY_CATEGORY}}` - Secondary App Store category
- `{{DESCRIPTIVE_SUBTITLE}}` - Descriptive subtitle for name alternatives
- `{{FEATURE_DESCRIPTION}}` - Feature description for name alternatives
- `{{TAGLINE}}` - App tagline
- `{{MODIFIER_1}}`, `{{MODIFIER_2}}`, `{{MODIFIER_3}}` - Alternative name modifiers
- `{{COMPANY_NAME}}` - Your company/brand name

## How to Replace Placeholders

### Option 1: Manual Search & Replace
1. Use your editor's find & replace feature
2. Search for each placeholder (e.g., `{{APP_NAME}}`)
3. Replace with your actual value

### Option 2: Script-Based Replacement
Create a simple script to replace all placeholders at once:

```bash
#!/bin/bash
# replace_placeholders.sh

APP_NAME="MyApp"
BUNDLE_ID="com.company.myapp"
# ... set all variables ...

# Replace in all files
find . -type f \( -name "*.md" -o -name "*.py" -o -name "*.sh" -o -name "*.txt" \) -exec sed -i '' \
  -e "s/{{APP_NAME}}/$APP_NAME/g" \
  -e "s/{{BUNDLE_ID}}/$BUNDLE_ID/g" \
  # ... add all replacements ...
  {} \;
```

### Option 3: Use a Template Engine
Consider using tools like:
- `envsubst` (GNU gettext)
- `mustache` templates
- Custom Python/Node script

## Files That Need Substitution

All files in this template may contain placeholders. Key files to check:

- **Scripts**: `scripts/xcode-project/*.py`, `scripts/xcode-project/*.sh`, `scripts/maintenance/*.sh`
- **Release Docs**: `release/app-store/*.md`, `release/testflight/*.md`, `release/testflight/*.txt`
- **Legal**: `legal/privacy-policy.md`
- **Support**: `support_site/*.md`
- **Documentation**: `docs/**/*.md`

## Verification

After replacing placeholders, verify:
1. No `{{PLACEHOLDER}}` tokens remain (search for `{{`)
2. All paths are correct for your project structure
3. All URLs are valid and accessible
4. All email addresses are correct
5. Bundle IDs match your Xcode project

## Notes

- Placeholders are case-sensitive: `{{APP_NAME}}` ≠ `{{app_name}}`
- Some placeholders may be optional depending on your app type
- HealthKit/Watch-specific placeholders are in `modules/healthkit_watch/` if you use that module
