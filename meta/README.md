# Apple App Meta Template

A reusable template repository containing scripts, documentation, and release materials for Apple app development. This template provides the operational infrastructure (scripts, docs, App Store/TestFlight materials) without any app source code.

## What's Included

### Core Components

- **`scripts/`** - Xcode project management, icon generation, and maintenance utilities
- **`docs/`** - Developer documentation for Xcode setup, iOS data persistence, and workflows
- **`release/`** - App Store and TestFlight deployment guides and templates
- **`legal/`** - Privacy policy template
- **`support_site/`** - Support website content templates
- **`.cursor/`** - Cursor rules, subagents, and shared commands (portable workflow)

### Optional Modules

- **`modules/healthkit_watch/`** - HealthKit and Apple Watch specific documentation and privacy guides

## Quick Start

### 1. Copy Template to Your Project

```bash
# Copy the entire template to your project root
cp -r /Users/kennethnygren/Cursor/Template/apple-app-meta-template/* /path/to/your/project/

# Or copy specific components
cp -r scripts/ /path/to/your/project/
cp -r release/ /path/to/your/project/
```

### 2. Replace Placeholders

All files contain placeholder tokens like `{{APP_NAME}}` and `{{BUNDLE_ID}}` that must be replaced with your app-specific values.

**See [PLACEHOLDERS.md](PLACEHOLDERS.md) for complete list and replacement instructions.**

Quick replacement example:
```bash
# Replace in all files
find . -type f \( -name "*.md" -o -name "*.py" -o -name "*.sh" \) -exec sed -i '' \
  -e "s/{{APP_NAME}}/MyApp/g" \
  -e "s/{{BUNDLE_ID}}/com.company.myapp/g" \
  {} \;
```

### 3. Customize for Your App

- Update script paths if your folder structure differs
- Customize App Store metadata in `release/app-store/`
- Update privacy policy in `legal/privacy-policy.md`
- Add/remove modules as needed

## Directory Structure

```
apple-app-meta-template/
├── README.md                    # This file
├── PLACEHOLDERS.md             # Placeholder substitution guide
│
├── scripts/                     # Utility scripts
│   ├── xcode-project/          # Xcode project management
│   ├── icons/                  # Icon generation and fixes
│   ├── maintenance/            # Maintenance utilities
│   ├── README.md
│   └── QUICK_START.md
│
├── docs/                        # Developer documentation
│   ├── xcode/                  # Xcode setup and project management
│   ├── ios-data/               # Core Data, SwiftData, CloudKit guides
│   └── guides/                 # General development guides
│
├── release/                     # Release materials
│   ├── app-store/              # App Store submission guides
│   └── testflight/             # TestFlight deployment guides
│
├── legal/                       # Legal templates
│   └── privacy-policy.md       # Privacy policy template
│
├── support_site/                # Support website content
│   └── README.md
│
└── modules/                     # Optional modules
    └── healthkit_watch/         # HealthKit & Watch specific docs
```

## Module Selection Guide

### Standard iOS App
Copy these core components:
- ✅ `scripts/`
- ✅ `docs/`
- ✅ `release/`
- ✅ `legal/`
- ❌ Skip `modules/healthkit_watch/`

### iOS App with HealthKit
Copy core components + HealthKit module:
- ✅ `scripts/`
- ✅ `docs/`
- ✅ `release/`
- ✅ `legal/`
- ✅ `modules/healthkit_watch/`

### iOS App with Apple Watch
Copy core components + HealthKit module (Watch apps often use HealthKit):
- ✅ `scripts/`
- ✅ `docs/`
- ✅ `release/`
- ✅ `legal/`
- ✅ `modules/healthkit_watch/`

## New App Checklist

When starting a new Apple app project:

### Initial Setup
- [ ] Copy template files to project
- [ ] Replace all placeholders (see `PLACEHOLDERS.md`)
- [ ] Set up Xcode project management scripts
- [ ] Configure icon generation scripts

### Development
- [ ] Review Xcode setup docs in `docs/xcode/`
- [ ] Set up data persistence (Core Data/SwiftData) using `docs/ios-data/`
- [ ] Configure CloudKit/App Groups if needed

### Pre-Release
- [ ] Review `release/app-store/PRE_DEPLOYMENT_CHECKLIST.md`
- [ ] Fix app icons using `scripts/icons/`
- [ ] Prepare App Store metadata using `release/app-store/APP_STORE_METADATA.md`
- [ ] Update privacy policy in `legal/privacy-policy.md`
- [ ] If using HealthKit: Complete privacy disclosure using `modules/healthkit_watch/`

### TestFlight
- [ ] Follow `release/testflight/TESTFLIGHT_DEPLOYMENT_GUIDE.md`
- [ ] Prepare tester instructions from `release/testflight/`
- [ ] Upload build and configure testers

### App Store Submission
- [ ] Complete all App Store Connect metadata
- [ ] Upload screenshots
- [ ] Submit for review

## Scripts Overview

### Xcode Project Management
- `add_missing_files_to_project.py` - Automatically add Swift files to Xcode project
- `add_files_build_phase.sh` - Build phase script for automatic file addition
- `setup_automatic_addition.sh` - Interactive setup wizard

### Icon Management
- `fix_app_store_icons.py` - Remove alpha channels from app icons
- `generate_icons.sh` - Generate all required icon sizes
- `generate_watch_icons.sh` - Generate Watch-specific icons

### Maintenance
- `delete_coredata_stores.sh` - Clean up Core Data stores (customize for your model name)

See `scripts/README.md` for detailed usage.

## Documentation

- **Xcode Setup**: `docs/xcode/` - Project setup, signing, build phases
- **iOS Data**: `docs/ios-data/` - Core Data, SwiftData, CloudKit configuration
- **Guides**: `docs/guides/` - General development workflows and best practices

## Release Materials

- **App Store**: `release/app-store/` - Submission checklist, metadata templates, icon fixes
- **TestFlight**: `release/testflight/` - Deployment guide, tester instructions

## Support

This template was extracted from a production app and includes:
- ✅ Battle-tested scripts and workflows
- ✅ Complete App Store submission materials
- ✅ Comprehensive developer documentation
- ✅ Privacy policy templates

## Customization Notes

- Scripts assume standard iOS project structure (iOS app, optional Watch app, shared code)
- Adjust paths in scripts if your structure differs
- Some scripts may need Python dependencies (check script headers)
- All markdown files use standard Markdown (GitHub Flavored)

## License

This template is provided as-is. Customize freely for your projects.

---

**Next Steps**: Read [PLACEHOLDERS.md](PLACEHOLDERS.md) to understand what needs to be customized for your app.
