.pragma library

// Hyprland's input.keyboard.key callback uses XKB keycodes (Linux evdev + 8).
var XKB_OFFSET = 8
var PROTOCOL_PREFIX = "keycast:v1:held:"
var VERTICALS = ["top", "middle", "bottom"]
var HORIZONTALS = ["left", "middle", "right"]
var SCALE_MIN = 0.75
var SCALE_MAX = 2
var SCALE_STEP = 0.25
var MODIFIER_ORDER = ["Super", "Ctrl", "Alt", "Shift"]

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

function clampScale(value) {
  var n = Number(value)
  if (!isFinite(n)) return 1
  n = Math.round(n / SCALE_STEP) * SCALE_STEP
  if (n < SCALE_MIN) return SCALE_MIN
  if (n > SCALE_MAX) return SCALE_MAX
  return n
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
    scale: clampScale(src.scale),
    lingerMs: clampInt(src.lingerMs, 0, 2000, 600)
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

function overlayY(vertical, height, parentHeight, padding) {
  return axisPosition(vertical, "bottom", height, parentHeight, padding)
}

function overlayRadius(roundingEnabled, rounding) {
  var enabled = roundingEnabled === undefined || roundingEnabled === null || roundingEnabled === ""
    ? true : isEnabledFlag(roundingEnabled)
  if (!enabled) return 0
  return clampInt(rounding, 0, 32, 8)
}

if (typeof module !== "undefined") {
  module.exports = {
    XKB_OFFSET: XKB_OFFSET,
    PROTOCOL_PREFIX: PROTOCOL_PREFIX,
    labelFor: labelFor,
    labelsForCodes: labelsForCodes,
    parseProtocol: parseProtocol,
    displayedAfterHeld: displayedAfterHeld,
    overlayX: overlayX,
    overlayY: overlayY,
    overlayRadius: overlayRadius,
    clampScale: clampScale,
    normalizeSettings: normalizeSettings,
    settingsFromBar: settingsFromBar
  }
}
