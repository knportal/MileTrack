## Cursor workflow (portable)

This template includes repo-local Cursor configuration under `.cursor/`:

- **Rules**: `.cursor/rules/` (always-applied engineering standards)
- **Subagent docs**: `.cursor/agents/` (recommended specialized agent prompts)
- **Slash commands**: `.cursor/commands/` (shared workflows like `/reviewfile`)

### Setup after copying into an app repo

1. Replace placeholders in `.cursor/rules/subagent-suggestions.mdc`:
   - `{{IOS_SCHEME}}` (required)
   - `{{WATCH_SCHEME}}` (optional)

2. If your project has no watch scheme, remove the watch scheme line (or leave it as a placeholder).
