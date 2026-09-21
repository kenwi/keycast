# Keycast (`local.keycast`)

On-screen overlay of currently pressed keys, for screen recordings.

The overlay is a click-through box of keycaps. It defaults to the lower-left
corner. Position, padding, scale, outer box, corner rounding, and an optional
shortcut action label are configurable.

## Features

- Shows the keys that are currently held, not a typing history
- Default position: bottom left
- Configurable vertical edge (`top` / `middle` / `bottom`)
- Configurable horizontal edge (`left` / `middle` / `right`)
- Configurable padding from the chosen edge (0-400 px, default 24; ignored on a middle axis)
- Optional outer box around the keycaps
- Optional corner rounding (0-32 px, default 8)
- Overlay scale (`1x` / `1.25x` / `1.5x` / `1.75x` / `2x`)
- Optional shortcut action from Hyprland bind descriptions (same source as Super+K)
- Action placement above or below the keycaps
- Short linger after release (default 600 ms) so quick taps stay visible on video
- Left-click the bar icon to toggle the overlay
- Right-click the bar icon for position, look, and the Hyprland bridge
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
  "roundingEnabled": true,
  "rounding": 8,
  "vertical": "bottom",
  "horizontal": "left",
  "padding": 24,
  "scale": 1,
  "lingerMs": 600,
  "actionEnabled": true,
  "actionPosition": "below"
}
```

| Key | Values | Default |
|-----|--------|---------|
| `overlayEnabled` | `true` / `false` | `false` |
| `frameEnabled` | `true` / `false` | `true` |
| `roundingEnabled` | `true` / `false` | `true` |
| `rounding` | 0-32 px | `8` |
| `vertical` | `top` / `middle` / `bottom` | `bottom` |
| `horizontal` | `left` / `middle` / `right` | `left` |
| `padding` | 0-400 px | `24` (ignored on a middle axis) |
| `scale` | `1` / `1.25` / `1.5` / `1.75` / `2` | `1` |
| `lingerMs` | 0-2000 ms | `600` |
| `actionEnabled` | `true` / `false` | `true` |
| `actionPosition` | `above` / `below` | `below` |

CLI examples:

```bash
omarchy bar set local.keycast vertical middle
omarchy bar set local.keycast horizontal middle
omarchy bar set local.keycast padding 40
omarchy bar set local.keycast scale 1.25
omarchy bar set local.keycast frameEnabled false
omarchy bar set local.keycast roundingEnabled false
omarchy bar set local.keycast rounding 12
omarchy bar set local.keycast actionEnabled true
omarchy bar set local.keycast actionPosition above
omarchy-shell local.keycast toggle
```

## Layout

| File | Role |
|------|------|
| `manifest.json` | Plugin id, service + bar-widget entry points, settings schema |
| `Service.qml` | Bridge events, overlay state, IPC, settings |
| `Overlay.qml` | Click-through corner box on every monitor |
| `BarWidget.qml` | Toggle + settings panel host |
| `Panel.qml` | Bridge setup, position, look, linger, action label |
| `Keys.js` | Keycode labels, protocol parse, bind catalog, settings normalize |
| `bridge.lua` | Hyprland `input.keyboard.key` observer |
| `scripts/bridge-control` | Inspect / enable / disable the managed Hyprland block |
| `README.md` | This file |

## Tests

```bash
local.keycast/tests/run
```
