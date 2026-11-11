# bzkeeb (WIP)

Keyboard mouse for macOS.

```sh
./scripts/build-app.sh
open dist/bzkeeb.app
```

## Keys

Default prefix: `⌃⌥`.

- `⌃⌥F` hints → click
- `⌃⌥O` hints → hover
- `⌃⌥R` hints → right-click
- `⌃⌥G` grid → scroll mode
- `⌃⌥S` scroll mode
- `⌃⌥/` help

Help groups all controls by task. Open it during scroll mode with the same shortcut;
`esc` or the shortcut returns to scrolling. Opening help releases an active drag.

Scroll mode combines scrolling and mouse control:

- `hjkl` scroll; `u/d` page up/down.
- `Option+hjkl` or arrow keys move the pointer (40 pixels).
- Add `Shift` to either movement binding for slower movement (10 pixels).
- `return` / `space` click or drop; `r` right-click; `x` double-click; `v` start dragging.
- Clicks and drops exit the mode. `esc` exits and releases an active drag.
- While dragging, movement and scrolling keep working; right-click, double-click, and another drag start are ignored.

Click any mouse button to exit a mode; the click passes through.

Unrecognized keys pulse the screen border and show a centered mode reminder. Each keypress refreshes it.

Settings: `BK` → `Settings`, or `⌘,` during a mode. Configure the prefix, cursor effects, and 3s auto-hide.

Blocked apps: add apps in Settings to disable bzkeeb while they’re focused.

Built with [Codex](https://github.com/openai/codex).
