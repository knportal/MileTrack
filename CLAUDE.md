# CLAUDE.md - MileTrack by Plenitudo

## Project
iOS mileage tracking app (Swift/SwiftUI, Xcode). Tracks trips with GPS, categorizes business/personal.

## Session Logging (IMPORTANT)
Before ending a session, append a brief summary to `.claude-session-log.md` with this format:

```
## YYYY-MM-DD HH:MM
- What was done (bullet points)
- Key decisions made
- Current blockers or next steps
---
```

This file is read by Sven (AI assistant on iMac) during daily syncs. Be descriptive in commit messages too — they're part of the knowledge pipeline.

## Conventions
- Commit messages should be descriptive (what + why, not just "fix bug")
- Test on Simulator before pushing when possible
- Keep `.claude-session-log.md` in `.gitignore` if you prefer it local-only
