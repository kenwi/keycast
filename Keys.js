.pragma library

// Hyprland's input.keyboard.key callback uses XKB keycodes (Linux evdev + 8).
var XKB_OFFSET = 8
var PROTOCOL_PREFIX = "keycast:v1:held:"
var EMPTY_LABELS = []
var VERTICALS = ["top", "middle", "bottom"]
var HORIZONTALS = ["left", "middle", "right"]
var ACTION_POSITIONS = ["above", "below"]
var COLOR_THEMES = ["shell", "dark", "light", "contrast", "nord", "mocha", "gold", "neon", "matrix", "vapor", "cyber", "ember", "ice", "custom"]
var THEME_LABELS = {
  shell: "Shell",
  dark: "Dark",
  light: "Light",
  contrast: "Contrast",
  nord: "Nord",
  mocha: "Mocha",
  gold: "Gold",
  neon: "Neon",
  matrix: "Matrix",
  vapor: "Vapor",
  cyber: "Cyber",
  ember: "Ember",
  ice: "Ice",
  custom: "Custom"
}
var DEFAULT_HEX = {
  background: "#1A1A1A",
  border: "#6E6E6E",
  font: "#F5F5F5"
}
var COLOR_PRESETS = {
  dark: { background: "#1A1A1A", border: "#6E6E6E", font: "#F5F5F5" },
  light: { background: "#F4F4F5", border: "#A1A1AA", font: "#18181B" },
  contrast: { background: "#000000", border: "#FFFFFF", font: "#FFFFFF" },
  nord: { background: "#2E3440", border: "#88C0D0", font: "#ECEFF4" },
  mocha: { background: "#1E1E2E", border: "#CBA6F7", font: "#CDD6F4" },
  gold: { background: "#1A1408", border: "#D4AF37", font: "#F8E7B0" },
  neon: { background: "#0A0018", border: "#FF00AA", font: "#00FFFF" },
  matrix: { background: "#020B05", border: "#00FF41", font: "#C8FFC8" },
  vapor: { background: "#1B0B2E", border: "#FF71CE", font: "#01CDFE" },
  cyber: { background: "#0C0C14", border: "#FCEE09", font: "#E8F4FF" },
  ember: { background: "#140604", border: "#FF4D00", font: "#FFE4C8" },
  ice: { background: "#031018", border: "#5CE1FF", font: "#EAFBFF" }
}
var SCALE_MIN = 0.75
var SCALE_MAX = 2
var SCALE_STEP = 0.25
var SCALE_CUSTOM_MIN = 0.5
var SCALE_CUSTOM_MAX = 5
var SCALE_PRESETS = [1, 1.25, 1.5, 1.75, 2]
var MODIFIER_ORDER = ["Super", "Ctrl", "Alt", "Shift"]
var COMBO_MOD_ORDER = ["SUPER", "CTRL", "ALT", "SHIFT"]
var MODMASK_SUPER = 64
var MODMASK_CTRL = 4
var MODMASK_ALT = 8
var MODMASK_SHIFT = 1
var BIND_KEY_TOKENS = {
  RETURN: "ENTER",
  ESCAPE: "ESC",
  COMMA: ",",
  PERIOD: ".",
  SLASH: "/",
  MINUS: "-",
  EQUAL: "=",
  SEMICOLON: ";",
  APOSTROPHE: "'",
  GRAVE: "`",
  BRACKETLEFT: "[",
  BRACKETRIGHT: "]",
  BACKSLASH: "\\",
  PRIOR: "PAGE UP",
  PAGE_UP: "PAGE UP",
  NEXT: "PAGE DOWN",
  PAGE_DOWN: "PAGE DOWN",
  SPACE: "SPACE",
  TAB: "TAB",
  BACKSPACE: "BACKSPACE",
  DELETE: "DELETE",
  LEFT: "LEFT",
  RIGHT: "RIGHT",
  UP: "UP",
  DOWN: "DOWN",
  HOME: "HOME",
  END: "END",
  INSERT: "INSERT",
  PRINT: "PRINT"
}
var LABEL_TOKENS = {
  Super: "SUPER",
  Ctrl: "CTRL",
  Alt: "ALT",
  Shift: "SHIFT",
  Enter: "ENTER",
  Esc: "ESC",
  "Page Up": "PAGE UP",
  "Page Down": "PAGE DOWN",
  Backspace: "BACKSPACE",
  Tab: "TAB",
  Space: "SPACE",
  Left: "LEFT",
  Right: "RIGHT",
  Up: "UP",
  Down: "DOWN",
  Home: "HOME",
  End: "END",
  Insert: "INSERT",
  Delete: "DELETE",
  Caps: "CAPS",
  Print: "PRINT"
}
var TOKEN_LABELS = {}
for (var _label in LABEL_TOKENS) TOKEN_LABELS[LABEL_TOKENS[_label]] = _label
TOKEN_LABELS.SUPER = "Super"
TOKEN_LABELS.CTRL = "Ctrl"
TOKEN_LABELS.ALT = "Alt"
TOKEN_LABELS.SHIFT = "Shift"

// XKB code -> modifier family. Left and right keys collapse to one label.
var MODIFIER_GROUP = {
  37: "Ctrl",
  105: "Ctrl",
  50: "Shift",
  62: "Shift",
  64: "Alt",
  108: "Alt",
  133: "Super",
  134: "Super"
}

// XKB code -> overlay label. Unlisted codes fall back to "Key <evdev>".
var KEY_LABELS = {
  9: "Esc",
  10: "1",
  11: "2",
  12: "3",
  13: "4",
  14: "5",
  15: "6",
  16: "7",
  17: "8",
  18: "9",
  19: "0",
  20: "-",
  21: "=",
  22: "Backspace",
  23: "Tab",
  24: "Q",
  25: "W",
  26: "E",
  27: "R",
  28: "T",
  29: "Y",
  30: "U",
  31: "I",
  32: "O",
  33: "P",
  34: "[",
  35: "]",
  36: "Enter",
  37: "Ctrl",
  38: "A",
  39: "S",
  40: "D",
  41: "F",
  42: "G",
  43: "H",
  44: "J",
  45: "K",
  46: "L",
  47: ";",
  48: "'",
  49: "`",
  50: "Shift",
  51: "\\",
  52: "Z",
  53: "X",
  54: "C",
  55: "V",
  56: "B",
  57: "N",
  58: "M",
  59: ",",
  60: ".",
  61: "/",
  62: "Shift",
  63: "Num *",
  64: "Alt",
  65: "Space",
  66: "Caps",
  67: "F1",
  68: "F2",
  69: "F3",
  70: "F4",
  71: "F5",
  72: "F6",
  73: "F7",
  74: "F8",
  75: "F9",
  76: "F10",
  77: "Num Lock",
  78: "Scroll Lock",
  79: "Num 7",
  80: "Num 8",
  81: "Num 9",
  82: "Num -",
  83: "Num 4",
  84: "Num 5",
  85: "Num 6",
  86: "Num +",
  87: "Num 1",
  88: "Num 2",
  89: "Num 3",
  90: "Num 0",
  91: "Num .",
  94: "\\",
  95: "F11",
  96: "F12",
  104: "Num Enter",
  105: "Ctrl",
  106: "Num /",
  107: "SysRq",
  108: "Alt",
  110: "Home",
  111: "Up",
  112: "Page Up",
  113: "Left",
  114: "Right",
  115: "End",
  116: "Down",
  117: "Page Down",
  118: "Insert",
  119: "Delete",
  121: "Mute",
  122: "Vol -",
  123: "Vol +",
  124: "Power",
  127: "Pause",
  133: "Super",
  134: "Super",
  135: "Menu",
  148: "Calc",
  150: "Sleep",
  151: "Wake",
  158: "Back",
  159: "Forward",
  164: "Play",
  165: "Prev",
  166: "Stop",
  167: "Next",
  172: "Play",
  173: "Prev",
  174: "Stop",
  176: "Rewind",
  209: "Copilot"
}

function isEnabledFlag(value) {
  if (value === true || value === 1) return true
  var text = String(value === undefined || value === null ? "" : value).toLowerCase()
  return text === "true" || text === "on" || text === "1" || text === "yes"
}

function clampInt(value, min, max, fallback) {
  var n = Math.floor(Number(value))
  if (!isFinite(n)) return fallback
  return Math.max(min, Math.min(max, n))
}

function clampScalePreset(value) {
  var n = Number(value)
  if (!isFinite(n)) return 1
  n = Math.round(n / SCALE_STEP) * SCALE_STEP
  if (n < SCALE_MIN) return SCALE_MIN
  if (n > SCALE_MAX) return SCALE_MAX
  return n
}

function clampScale(value) {
  var n = Number(value)
  if (!isFinite(n)) return 1
  n = Math.round(n * 100) / 100
  if (n < SCALE_CUSTOM_MIN) return SCALE_CUSTOM_MIN
  if (n > SCALE_CUSTOM_MAX) return SCALE_CUSTOM_MAX
  return n
}

function isScalePreset(value) {
  var n = Number(value)
  if (!isFinite(n)) return false
  for (var i = 0; i < SCALE_PRESETS.length; i++) {
    if (Math.abs(SCALE_PRESETS[i] - n) < 0.001) return true
  }
  return false
}

function scaleToken(value) {
  var n = Number(value)
  if (!isFinite(n)) return "1"
  if (Math.abs(n - Math.round(n)) < 0.001) return String(Math.round(n))
  return String(n)
}

function scaleChoice(scale, scaleCustom) {
  if (scaleCustom === true) return "custom"
  if (!isScalePreset(scale)) return "custom"
  return scaleToken(scale)
}

function pickChoice(value, allowed, fallback) {
  var text = String(value === undefined || value === null ? "" : value).toLowerCase()
  return allowed.indexOf(text) !== -1 ? text : fallback
}

function labelFor(code) {
  var n = Math.floor(Number(code))
  if (!isFinite(n) || n < 1) return ""
  if (KEY_LABELS[n]) return KEY_LABELS[n]
  return "Key " + (n - XKB_OFFSET)
}

function labelsForCodes(codes) {
  if (!Array.isArray(codes)) return []
  var seenMod = {}
  var mods = []
  var others = []
  for (var i = 0; i < codes.length; i++) {
    var code = Math.floor(Number(codes[i]))
    if (!isFinite(code) || code < 1) continue
    var group = MODIFIER_GROUP[code]
    if (group) {
      if (seenMod[group]) continue
      seenMod[group] = true
      mods.push(group)
    } else {
      var label = labelFor(code)
      if (label !== "") others.push(label)
    }
  }
  var ordered = []
  for (var m = 0; m < MODIFIER_ORDER.length; m++) {
    if (seenMod[MODIFIER_ORDER[m]]) ordered.push(MODIFIER_ORDER[m])
  }
  return ordered.concat(others)
}

function parseCodes(raw) {
  var text = String(raw || "")
  if (text === "") return []
  var parts = text.split(",")
  var codes = []
  for (var i = 0; i < parts.length; i++) {
    if (!/^[0-9]+$/.test(parts[i])) return null
    var n = parseInt(parts[i], 10)
    if (!isFinite(n) || n < 1) return null
    codes.push(n)
  }
  return codes
}

function parseProtocol(payload) {
  var text = String(payload || "")
  if (text.indexOf(PROTOCOL_PREFIX) !== 0) return { ok: false, error: "prefix" }
  var rest = text.substring(PROTOCOL_PREFIX.length)
  var codes = parseCodes(rest)
  if (codes === null) return { ok: false, error: "codes" }
  return { ok: true, codes: codes, labels: labelsForCodes(codes) }
}

function hasNewLabel(previous, next) {
  if (!Array.isArray(next) || next.length === 0) return false
  if (!Array.isArray(previous) || previous.length === 0) return true
  if (next.length > previous.length) return true
  for (var i = 0; i < next.length; i++) {
    if (previous.indexOf(next[i]) === -1) return true
  }
  return false
}

// Keep the last full chord while any of its keys are still held. Super+Left
// then releasing Left must stay Super+Left, not collapse to Super. A later
// press (Super+Right) replaces the chord.
function displayedAfterHeld(previousHeld, nextHeld, currentDisplayed) {
  var next = Array.isArray(nextHeld) ? nextHeld.slice() : []
  var shown = Array.isArray(currentDisplayed) ? currentDisplayed.slice() : []
  if (next.length === 0) return shown
  if (hasNewLabel(previousHeld, next) || shown.length === 0) return next
  return shown
}

function isComboModifier(token) {
  return token === "SUPER" || token === "CTRL" || token === "ALT" || token === "SHIFT"
}

function labelToken(label) {
  var text = String(label || "")
  if (LABEL_TOKENS[text]) return LABEL_TOKENS[text]
  return text.toUpperCase()
}

function bindNameToken(name) {
  var text = String(name || "").trim()
  if (text === "") return ""
  var upper = text.toUpperCase()
  if (BIND_KEY_TOKENS[upper]) return BIND_KEY_TOKENS[upper]
  return upper
}

function bindKeyToken(key) {
  var text = String(key || "").trim()
  if (text === "") return ""
  if (/^mouse:/.test(text) || /^mouse_/.test(text) || /^switch:/.test(text)) return ""
  var codeMatch = text.match(/code:(\d+)\s*$/)
  if (codeMatch) {
    var code = parseInt(codeMatch[1], 10)
    var fromCode = labelFor(code)
    if (fromCode.indexOf("Key ") === 0) return "CODE:" + code
    return labelToken(fromCode)
  }
  if (text.indexOf(" + ") !== -1) {
    var parts = text.split(" + ")
    text = parts[parts.length - 1]
  }
  return bindNameToken(text)
}

function comboFromModsAndToken(seenMods, token) {
  if (!token) return ""
  var ordered = []
  for (var i = 0; i < COMBO_MOD_ORDER.length; i++) {
    if (seenMods[COMBO_MOD_ORDER[i]]) ordered.push(COMBO_MOD_ORDER[i])
  }
  return ordered.concat([token]).join("+")
}

function comboFromModmaskAndKey(modmask, key) {
  var mask = Math.floor(Number(modmask))
  if (!isFinite(mask)) mask = 0
  var seen = {}
  if (mask & MODMASK_SUPER) seen.SUPER = true
  if (mask & MODMASK_CTRL) seen.CTRL = true
  if (mask & MODMASK_ALT) seen.ALT = true
  if (mask & MODMASK_SHIFT) seen.SHIFT = true
  return comboFromModsAndToken(seen, bindKeyToken(key))
}

function comboFromLabels(labels) {
  if (!Array.isArray(labels) || labels.length === 0) return ""
  var seen = {}
  var keys = []
  for (var i = 0; i < labels.length; i++) {
    var token = labelToken(labels[i])
    if (token === "") continue
    if (isComboModifier(token)) {
      seen[token] = true
      continue
    }
    keys.push(token)
  }
  if (keys.length === 0) return ""
  return comboFromModsAndToken(seen, keys[keys.length - 1])
}

function parseBindRecords(text) {
  var records = []
  var current = null
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i]
    if (/^bind/.test(line)) {
      if (current) records.push(current)
      current = {}
      continue
    }
    var match = line.match(/^\t([^:]+):\s?(.*)$/)
    if (match && current) current[match[1]] = match[2]
  }
  if (current) records.push(current)
  return records
}

function parseBinds(text) {
  var catalog = {}
  var records = parseBindRecords(text)
  for (var i = 0; i < records.length; i++) {
    var record = records[i]
    var description = String(record.description || "").trim()
    if (description === "") continue
    var combo = comboFromModmaskAndKey(record.modmask, record.key)
    if (combo === "") continue
    if (!catalog[combo]) catalog[combo] = description
  }
  return catalog
}

function actionForLabels(catalog, labels) {
  if (!catalog || typeof catalog !== "object") return ""
  var combo = comboFromLabels(labels)
  if (combo === "") return ""
  return catalog[combo] || ""
}

function tokenToLabel(token) {
  var text = String(token || "")
  if (text === "") return ""
  if (TOKEN_LABELS[text]) return TOKEN_LABELS[text]
  if (/^F([1-9]|1[0-2])$/.test(text)) return text
  if (text.length === 1) return text
  return text.charAt(0) + text.substring(1).toLowerCase()
}

function comboToLabels(combo) {
  var parts = String(combo || "").split("+")
  var labels = []
  for (var i = 0; i < parts.length; i++) {
    var label = tokenToLabel(parts[i])
    if (label !== "") labels.push(label)
  }
  return labels
}

function catalogCombos(catalog) {
  var combos = []
  if (!catalog || typeof catalog !== "object") return combos
  for (var combo in catalog) {
    if (catalog[combo]) combos.push(combo)
  }
  return combos
}

function randomPreview(catalog) {
  var combos = catalogCombos(catalog)
  if (combos.length === 0) {
    return { labels: ["Super", "K"], action: "Keybindings", combo: "SUPER+K" }
  }
  var combo = combos[Math.floor(Math.random() * combos.length)]
  return {
    labels: comboToLabels(combo),
    action: catalog[combo],
    combo: combo
  }
}

function overlayLabels(displayedKeys, previewEnabled, previewKeys) {
  if (displayedKeys && displayedKeys.length > 0) return displayedKeys
  if (previewEnabled && previewKeys && previewKeys.length > 0) return previewKeys
  return EMPTY_LABELS
}

function isCatalogChangeEvent(name) {
  var text = String(name || "")
  return text === "configreloaded" || text === "configreloadedv2"
}

function settingsFromBar(barConfig, pluginId) {
  var id = String(pluginId || "")
  var layout = barConfig && barConfig.layout ? barConfig.layout : null
  if (!layout || id === "") return {}
  var sections = ["left", "center", "right"]
  for (var s = 0; s < sections.length; s++) {
    var arr = layout[sections[s]] || []
    for (var i = 0; i < arr.length; i++) {
      if (arr[i] && String(arr[i].id || "") === id) return arr[i]
    }
  }
  return {}
}

function normalizeSettings(entry) {
  var src = entry && typeof entry === "object" ? entry : {}
  var frameRaw = src.frameEnabled
  var rawScale = Number(src.scale)
  if (!isFinite(rawScale)) rawScale = 1
  rawScale = Math.round(rawScale * 100) / 100
  var customRaw = src.scaleCustom
  var scaleCustom = customRaw === undefined || customRaw === null || customRaw === ""
    ? !isScalePreset(rawScale)
    : isEnabledFlag(customRaw)
  var scale = scaleCustom ? clampScale(rawScale) : clampScalePreset(rawScale)
  if (!scaleCustom && !isScalePreset(scale)) scaleCustom = true
  return {
    overlayEnabled: isEnabledFlag(src.overlayEnabled),
    frameEnabled: frameRaw === undefined || frameRaw === null || frameRaw === ""
      ? true : isEnabledFlag(frameRaw),
    roundingEnabled: src.roundingEnabled === undefined || src.roundingEnabled === null || src.roundingEnabled === ""
      ? true : isEnabledFlag(src.roundingEnabled),
    rounding: clampInt(src.rounding, 0, 32, 8),
    vertical: pickChoice(src.vertical, VERTICALS, "bottom"),
    horizontal: pickChoice(src.horizontal, HORIZONTALS, "left"),
    padding: clampInt(src.padding, 0, 400, 24),
    scale: scale,
    scaleCustom: scaleCustom,
    lingerMs: clampInt(src.lingerMs, 0, 2000, 600),
    actionEnabled: src.actionEnabled === undefined || src.actionEnabled === null || src.actionEnabled === ""
      ? true : isEnabledFlag(src.actionEnabled),
    previewEnabled: src.previewEnabled === undefined || src.previewEnabled === null || src.previewEnabled === ""
      ? true : isEnabledFlag(src.previewEnabled),
    actionPosition: pickChoice(src.actionPosition, ACTION_POSITIONS, "below"),
    colorTheme: pickChoice(src.colorTheme, COLOR_THEMES, "shell"),
    backgroundColor: normalizeHex(src.backgroundColor, DEFAULT_HEX.background),
    borderColor: normalizeHex(src.borderColor, DEFAULT_HEX.border),
    fontColor: normalizeHex(src.fontColor, DEFAULT_HEX.font)
  }
}

function axisPosition(edge, endEdge, size, parentSize, padding) {
  var box = Math.max(0, Number(size) || 0)
  var span = Math.max(0, Number(parentSize) || 0)
  var pad = Math.max(0, Number(padding) || 0)
  if (edge === "middle") return Math.max(0, Math.round((span - box) / 2))
  if (edge === endEdge) return Math.max(0, span - box - pad)
  return Math.max(0, pad)
}

function overlayX(horizontal, width, parentWidth, padding) {
  return axisPosition(horizontal, "right", width, parentWidth, padding)
}

// Place a child on the same edge as overlayX, inside a wider parent (padding 0).
function alignX(horizontal, childWidth, parentWidth) {
  return overlayX(horizontal, childWidth, parentWidth, 0)
}

function overlayY(vertical, height, parentHeight, padding) {
  return axisPosition(vertical, "bottom", height, parentHeight, padding)
}

function overlayRadius(roundingEnabled, rounding) {
  var enabled = roundingEnabled === undefined || roundingEnabled === null || roundingEnabled === ""
    ? true : isEnabledFlag(roundingEnabled)
  if (!enabled) return 0
  return clampInt(rounding, 0, 32, 8)
}

function normalizeHex(value, fallback) {
  var fb = String(fallback || DEFAULT_HEX.background)
  var text = String(value === undefined || value === null ? "" : value).trim()
  if (text === "") return fb
  if (text.charAt(0) !== "#") text = "#" + text
  var shortMatch = text.match(/^#([0-9A-Fa-f]{3})$/)
  if (shortMatch) {
    var s = shortMatch[1].toUpperCase()
    return "#" + s.charAt(0) + s.charAt(0) + s.charAt(1) + s.charAt(1) + s.charAt(2) + s.charAt(2)
  }
  var longMatch = text.match(/^#([0-9A-Fa-f]{6})([0-9A-Fa-f]{2})?$/)
  if (longMatch) return "#" + longMatch[1].toUpperCase()
  return fb
}

function byteHex(n) {
  var v = Math.round(Math.max(0, Math.min(255, Number(n) || 0)))
  var hex = v.toString(16).toUpperCase()
  return hex.length < 2 ? "0" + hex : hex
}

function colorToHex(value, fallback) {
  var fb = normalizeHex(fallback, DEFAULT_HEX.background)
  if (value === undefined || value === null || value === "") return fb
  if (typeof value === "string") return normalizeHex(value, fb)
  if (typeof value === "object" && value.r !== undefined && value.g !== undefined && value.b !== undefined)
    return "#" + byteHex(value.r * 255) + byteHex(value.g * 255) + byteHex(value.b * 255)
  var text = String(value)
  var hash = text.indexOf("#")
  if (hash >= 0) return normalizeHex(text.substring(hash, hash + 7), fb)
  return fb
}

function presetColors(theme) {
  var key = String(theme || "")
  return COLOR_PRESETS[key] || null
}

function resolvedOverlayColors(settings) {
  var src = settings && typeof settings === "object" ? settings : {}
  var theme = pickChoice(src.colorTheme, COLOR_THEMES, "shell")
  if (theme === "shell") return { theme: "shell", source: "shell" }
  var preset = presetColors(theme)
  if (preset) {
    return {
      theme: theme,
      source: "preset",
      background: preset.background,
      border: preset.border,
      font: preset.font
    }
  }
  return {
    theme: "custom",
    source: "custom",
    background: normalizeHex(src.backgroundColor, DEFAULT_HEX.background),
    border: normalizeHex(src.borderColor, DEFAULT_HEX.border),
    font: normalizeHex(src.fontColor, DEFAULT_HEX.font)
  }
}

function themeOptions() {
  var out = []
  for (var i = 0; i < COLOR_THEMES.length; i++) {
    var value = COLOR_THEMES[i]
    out.push({ value: value, label: THEME_LABELS[value] || value })
  }
  return out
}

if (typeof module !== "undefined") {
  module.exports = {
    XKB_OFFSET: XKB_OFFSET,
    PROTOCOL_PREFIX: PROTOCOL_PREFIX,
    labelFor: labelFor,
    labelsForCodes: labelsForCodes,
    parseProtocol: parseProtocol,
    displayedAfterHeld: displayedAfterHeld,
    comboFromLabels: comboFromLabels,
    parseBinds: parseBinds,
    actionForLabels: actionForLabels,
    comboToLabels: comboToLabels,
    randomPreview: randomPreview,
    overlayLabels: overlayLabels,
    isCatalogChangeEvent: isCatalogChangeEvent,
    overlayX: overlayX,
    alignX: alignX,
    overlayY: overlayY,
    overlayRadius: overlayRadius,
    normalizeHex: normalizeHex,
    colorToHex: colorToHex,
    presetColors: presetColors,
    resolvedOverlayColors: resolvedOverlayColors,
    themeOptions: themeOptions,
    clampScale: clampScale,
    clampScalePreset: clampScalePreset,
    isScalePreset: isScalePreset,
    scaleChoice: scaleChoice,
    normalizeSettings: normalizeSettings,
    settingsFromBar: settingsFromBar
  }
}
