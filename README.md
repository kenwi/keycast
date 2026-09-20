# Keycast (`local.keycast`)

On-screen overlay of currently pressed keys, for screen recordings.

The overlay is a click-through box of keycaps. It defaults to the lower-left
corner. Vertical edge, horizontal edge, and padding from that corner are
configurable.

## Features

- Shows the keys that are currently held, not a typing history
- Default position: bottom left
- Configurable vertical edge (`top` / `middle` / `bottom`)
- Configurable horizontal edge (`left` / `middle` / `right`)
- Configurable padding from the chosen edge (0-400 px, default 24; ignored on a middle axis)
- Short linger after release (default 600 ms) so quick taps stay visible on video
- Left-click the bar icon to toggle the overlay
- Right-click the bar icon for position, padding, and the Hyprland bridge
- IPC: `omarchy-shell local.keycast toggle` (also `show`, `hide`, `state`)

## Privacy

Keycast is an on-screen display for recordings, not a logger.

- No `/dev/input` or evdev listener
- No key history, timestamps, or log files
- Held keycodes live only in Hyprland/Quickshell memory
- The overlay is off until you turn it on
- Disable or remove the Hyprland bridge when you are not recording if you want
  the observer unloaded

## Install

```bash
ln -s ~/Work/omarchy-plugins/local.keycast ~/.config/omarchy/plugins/local.keycast
omarchy plugin enable local.keycast
```

Right-click the keyboard icon on the bar and choose **Enable Hyprland bridge**.
That appends a three-line block to `~/.config/hypr/hyprland.lua` and reloads
Hyprland. Left-click the icon to show the overlay, then hold keys to preview it.

Saved plugin files reload automatically. If the plugin is a symlink, prefer
`omarchy restart shell` after edits so QML definitely reloads.

## Settings

Persisted on the bar entry in `~/.config/omarchy/shell.json`:

```json
{
  "id": "local.keycast",
  "overlayEnabled": false,
  "frameEnabled": true,
  "vertical": "bottom",
  "horizontal": "left",
  "padding": 24,
  "scale": 1,
  "lingerMs": 600
}
```

| Key | Values | Default |
|-----|--------|---------|
| `overlayEnabled` | `true` / `false` | `false` |
| `frameEnabled` | `true` / `false` | `true` |
| `vertical` | `top` / `middle` / `bottom` | `bottom` |
| `horizontal` | `left` / `middle` / `right` | `left` |
| `padding` | 0-400 px | `24` (ignored on a middle axis) |
| `scale` | `1` / `1.25` / `1.5` / `1.75` / `2` | `1` |
| `lingerMs` | 0-2000 ms | `600` |

CLI examples:

```bash
omarchy bar set local.keycast vertical middle
omarchy bar set local.keycast horizontal middle
omarchy bar set local.keycast padding 40
omarchy bar set local.keycast scale 1.25
omarchy bar set local.keycast frameEnabled false
omarchy-shell local.keycast toggle
```

## Layout

| File | Role |
|------|------|
| `manifest.json` | Plugin id, service + bar-widget entry points, settings schema |
| `Service.qml` | Bridge events, overlay state, IPC, settings |
| `Overlay.qml` | Click-through corner box on every monitor |
| `BarWidget.qml` | Toggle + settings panel host |
| `Panel.qml` | Bridge setup, position, padding, linger |
| `Keys.js` | Keycode labels, protocol parse, settings normalize |
| `bridge.lua` | Hyprland `input.keyboard.key` observer |
| `scripts/bridge-control` | Inspect / enable / disable the managed Hyprland block |
| `README.md` | This file |

## Tests

```bash
local.keycast/tests/run
```
