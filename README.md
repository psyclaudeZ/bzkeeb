# BzKeeb prototype

A deliberately rough macOS menu-bar prototype for testing keyboard-driven mouse control.

## Try it

```sh
./scripts/build-app.sh
open dist/BzKeeb.app
```

On first launch, grant BzKeeb access in **System Settings → Privacy & Security → Accessibility**, then choose **Check Accessibility permission** from the `BK` menu-bar item.

## Shortcuts

| Shortcut | Action |
| --- | --- |
| `Control-Option-F` | Show Accessibility hints and left-click the chosen target |
| `Control-Option-M` | Show Accessibility hints and move/hover over the chosen target |
| `Control-Option-R` | Show Accessibility hints and right-click the chosen target |
| `Control-Option-G` | Start a recursive grid; after three choices it enters precision mode |
| `Control-Option-P` | Enter precision mode at the current pointer |
| `Control-Option-S` | Enter HJKL scroll mode at the current pointer |

Hints use `asdfghjkl`. In precision mode, use `h/j/k/l`, `Shift` for larger steps, `Return` or `Space` to click, `r` to right-click, `d` to double-click, and `v` to begin a drag. While dragging, `Return` drops. `Escape` always exits and safely releases an active drag.

The grid uses the spatial keys:

```text
q w e
a s d
z x c
```

This is a plumbing prototype, not production software. It currently scans only the focused window, uses fixed shortcuts, and has intentionally basic overlays.

### Development-signing caveat

The prototype is ad-hoc signed because no local Apple code-signing identity is configured. macOS ties Accessibility approval to that exact build, so after changing and rebuilding the app you must remove and re-add BzKeeb in Accessibility settings. The build script refuses to overwrite the bundle while BzKeeb is running, which would otherwise invalidate the live process immediately.
