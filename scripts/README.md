# Scripts

This project follows the operational template layout from `Cursor/Template/apple-app-meta-template`.

## Template sync

To copy the upstream template content into this repo (without mixing it into app source), run:

```bash
./scripts/template_sync.sh
```

This will copy the template into `_template_upstream/` so you can:

- keep upstream materials intact
- selectively move/adapt files into `docs/`, `release/`, `legal/`, etc.
- replace placeholders (`{{APP_NAME}}`, `{{BUNDLE_ID}}`, …) at your pace

