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
- `⌃⌥G` grid → precision mode
- `⌃⌥P` precision mode
- `⌃⌥S` scroll mode
- `⌃⌥/` help

Precision mode: `hjkl` move, `return` click/drop, `r` right-click, `d` double-click, `v` drag, `esc` exit.

Scroll mode: `hjkl` scroll, `Shift+hjkl` move, `u/d` page up/down, `esc` exit.

Settings: `BK` → `Settings`, or `⌘,` during a mode. Configure the prefix, cursor effects, and 3s auto-hide.

Built with [Codex](https://github.com/openai/codex).
