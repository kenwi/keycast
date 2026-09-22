# Keycast (`local.keycast`)

On-screen overlay of currently pressed keys, for screen recordings.

The overlay is a click-through box of keycaps. It defaults to the lower-left
corner. Position, padding, scale, outer box, corner rounding, colors, and an
optional shortcut action label are configurable.

![Key overlay](screenshots/overlay.png)

*Overlay - currently held keys as keycaps, with the Hyprland bind description
underneath. Super+W shows Close window, the same text Super+K lists for that
shortcut. The box is click-through so it does not steal clicks in a recording.*

![Settings panel](screenshots/configuration.png)

*Configuration - right-click the bar icon to open this panel. Turn the overlay
on, choose outer box and rounding, place it on an edge or in the middle, set
padding and scale, linger after release, and optionally show the shortcut
action above or below the keys. The first-time Hyprland bridge install lives
here too.*

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
- Color themes (Shell, Dark, Light, Contrast, Nord, Mocha, Gold) plus custom hex for background, border, and font
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

## Hotkey

Add a bind in `~/.config/hypr/bindings.lua` so you can show or hide the overlay
without clicking the bar. Super+K already opens the keybindings list; Super+Shift+K
is free in Omarchy defaults and stays next to that:

```lua
o.bind("SUPER + SHIFT + K", "Toggle keycast", "omarchy-shell local.keycast toggle")
```

Reload Hyprland after saving. The description appears in Super+K. Pick any unused
combo if you already bound that one. One-way variants:

```lua
o.bind("SUPER + SHIFT + K", "Show keycast", "omarchy-shell local.keycast show")
o.bind("SUPER + SHIFT + L", "Hide keycast", "omarchy-shell local.keycast hide")
```

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
  "actionPosition": "below",
  "colorTheme": "shell",
  "backgroundColor": "#1A1A1A",
  "borderColor": "#6E6E6E",
  "fontColor": "#F5F5F5"
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
| `colorTheme` | `shell` / `dark` / `light` / `contrast` / `nord` / `mocha` / `gold` / `custom` | `shell` |
| `backgroundColor` | `#RRGGBB` | `#1A1A1A` |
| `borderColor` | `#RRGGBB` | `#6E6E6E` |
| `fontColor` | `#RRGGBB` | `#F5F5F5` |

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
omarchy bar set local.keycast colorTheme mocha
omarchy bar set local.keycast backgroundColor "#1A1A1A"
omarchy bar set local.keycast borderColor "#6E6E6E"
omarchy bar set local.keycast fontColor "#F5F5F5"
omarchy-shell local.keycast toggle
```

## Layout

| File | Role |
|------|------|
| `manifest.json` | Plugin id, service + bar-widget entry points, settings schema |
| `Service.qml` | Bridge events, overlay state, IPC, settings |
| `Overlay.qml` | Click-through corner box on every monitor |
| `BarWidget.qml` | Toggle + settings panel host |
| `Panel.qml` | Bridge setup, position, look, colors, linger, action label |
| `Keys.js` | Keycode labels, protocol parse, bind catalog, settings normalize |
| `bridge.lua` | Hyprland `input.keyboard.key` observer |
| `scripts/bridge-control` | Inspect / enable / disable the managed Hyprland block |
| `screenshots/` | Overlay and settings panel images for this README |
| `README.md` | This file |

## Tests

```bash
local.keycast/tests/run
```
