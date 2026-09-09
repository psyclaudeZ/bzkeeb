# bzkeeb (WIP)

Keyboard mouse for macOS. Very early prototype.

```sh
./scripts/build-app.sh
open dist/BzKeeb.app
```

## Keys

Default prefix: `⌃⌥` (Control-Option).

- `⌃⌥F` hints → click
- `⌃⌥H` hints → hover
- `⌃⌥R` hints → right-click
- `⌃⌥G` grid → precision mode
- `⌃⌥P` precision mode
- `⌃⌥S` scroll mode
- `⌃⌥/` help

Precision mode: `hjkl` move, `return` click/drop, `r` right-click, `d` double-click, `v` drag, `esc` exit.

Scroll mode: `hjkl` scroll, `Shift+hjkl` move the pointer, `u/d` page up/down, `esc` exit. Move the pointer over another pane to scroll it without leaving scroll mode.

Change the prefix in `BK` → `Settings`, then restart the app.

The prototype is ad-hoc signed, so rebuilding can invalidate its previous Accessibility grant even when Settings still shows it enabled. If this happens, remove BzKeeb from System Settings → Privacy & Security → Accessibility, add `dist/BzKeeb.app` again, and enable it. BzKeeb retries the keyboard listener after permission is granted.

Built with [Codex](https://github.com/openai/codex).
