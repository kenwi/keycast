const fs = require("fs")
const path = require("path")
const src = fs.readFileSync(path.join(__dirname, "..", "Keys.js"), "utf8")
  .replace(".pragma library", "")
const Keys = {}
eval(src + "\nObject.assign(Keys, module.exports)")

function assert(cond, message) {
  if (!cond) throw new Error(message)
}

assert(Keys.labelFor(38) === "A", "A key")
assert(Keys.labelFor(36) === "Enter", "Enter")
assert(Keys.labelFor(133) === "Super", "Super")
assert(Keys.labelFor(9) === "Esc", "Esc")
assert(Keys.labelsForCodes([37, 50, 38]).join(",") === "Ctrl,Shift,A", "chord order")
assert(Keys.labelsForCodes([105, 37]).join(",") === "Ctrl", "duplicate ctrl")
assert(Keys.labelsForCodes([133, 36]).join(",") === "Super,Enter", "super enter")

const empty = Keys.parseProtocol("keycast:v1:held:")
assert(empty.ok && empty.labels.length === 0, "empty snapshot")

const held = Keys.parseProtocol("keycast:v1:held:37,38")
assert(held.ok && held.labels.join(",") === "Ctrl,A", "held snapshot")
assert(!Keys.parseProtocol("omakeez:v1:held:38").ok, "foreign prefix")
assert(!Keys.parseProtocol("keycast:v1:held:38,x").ok, "bad codes")

const settings = Keys.normalizeSettings({
  overlayEnabled: "on",
  vertical: "TOP",
  horizontal: "right",
  padding: 80,
  lingerMs: 1200
})
assert(settings.overlayEnabled === true, "overlay flag")
assert(settings.frameEnabled === false, "frame default when unset")
assert(settings.vertical === "top", "vertical")
assert(settings.horizontal === "right", "horizontal")
assert(settings.padding === 80, "padding")
assert(settings.scale === 1, "scale default when unset")
assert(settings.lingerMs === 1200, "linger")

const defaults = Keys.normalizeSettings({})
assert(defaults.overlayEnabled === false, "overlay default")
assert(defaults.frameEnabled === false, "frame default")
assert(defaults.roundingEnabled === true, "rounding default")
assert(defaults.rounding === 8, "rounding px default")
assert(defaults.vertical === "bottom", "vertical default")
assert(defaults.horizontal === "middle", "horizontal default")
assert(defaults.padding === 24, "padding default")
assert(defaults.scale === 1, "scale default")
assert(defaults.scaleCustom === false, "scaleCustom default")

const fromBar = Keys.settingsFromBar({
  layout: { right: [{ id: "local.keycast", padding: 12 }] }
}, "local.keycast")
assert(fromBar.padding === 12, "bar settings")
assert(Keys.normalizeSettings({ frameEnabled: "off" }).frameEnabled === false, "frame off")
assert(Keys.normalizeSettings({ frameEnabled: false }).frameEnabled === false, "frame false")

assert(Keys.displayedAfterHeld([], ["Super"], []).join(",") === "Super", "super down")
assert(Keys.displayedAfterHeld(["Super"], ["Super", "Left"], ["Super"]).join(",") === "Super,Left", "super+left down")
assert(Keys.displayedAfterHeld(["Super", "Left"], ["Super"], ["Super", "Left"]).join(",") === "Super,Left", "left up keeps chord")
assert(Keys.displayedAfterHeld(["Super"], ["Super", "Right"], ["Super", "Left"]).join(",") === "Super,Right", "next key replaces chord")
assert(Keys.displayedAfterHeld(["Super", "Right"], [], ["Super", "Right"]).join(",") === "Super,Right", "all up keeps chord for linger")

assert(Keys.normalizeSettings({ vertical: "middle", horizontal: "MIDDLE" }).vertical === "middle", "vertical middle")
assert(Keys.normalizeSettings({ vertical: "middle", horizontal: "MIDDLE" }).horizontal === "middle", "horizontal middle")
assert(Keys.overlayX("left", 100, 1000, 24) === 24, "x left uses padding")
assert(Keys.overlayX("right", 100, 1000, 24) === 876, "x right uses padding")
assert(Keys.overlayX("middle", 100, 1000, 24) === 450, "x middle ignores padding")
assert(Keys.alignX("left", 80, 200) === 0, "align left in wider box")
assert(Keys.alignX("right", 80, 200) === 120, "align right in wider box")
assert(Keys.alignX("middle", 80, 200) === 60, "align middle in wider box")
function keysScreenX(horizontal, keysWidth, boxWidth, parentWidth, padding) {
  return Keys.overlayX(horizontal, boxWidth, parentWidth, padding)
    + Keys.alignX(horizontal, keysWidth, boxWidth)
}
assert(keysScreenX("left", 80, 200, 1000, 24) === Keys.overlayX("left", 80, 1000, 24), "left keys ignore caption width")
assert(keysScreenX("right", 80, 200, 1000, 24) === Keys.overlayX("right", 80, 1000, 24), "right keys ignore caption width")
assert(keysScreenX("middle", 80, 200, 1000, 24) === Keys.overlayX("middle", 80, 1000, 24), "middle keys ignore caption width")
assert(Keys.overlayY("top", 40, 800, 24) === 24, "y top uses padding")
assert(Keys.overlayY("bottom", 40, 800, 24) === 736, "y bottom uses padding")
assert(Keys.overlayY("middle", 40, 800, 24) === 380, "y middle ignores padding")
assert(Keys.clampScalePreset(1.25) === 1.25, "scale 1.25")
assert(Keys.clampScalePreset("1.5") === 1.5, "scale string")
assert(Keys.clampScalePreset(1.3) === 1.25, "scale snaps")
assert(Keys.clampScalePreset(3) === 2, "scale max")
assert(Keys.clampScalePreset(0) === 0.75, "scale min")
assert(Keys.clampScale(1.3) === 1.3, "custom scale keeps tenths")
assert(Keys.clampScale(1.333) === 1.33, "custom scale two decimals")
assert(Keys.clampScale(9) === 5, "custom scale max")
assert(Keys.clampScale(0) === 0.5, "custom scale min")
assert(Keys.isScalePreset(1.25) === true, "1.25 is preset")
assert(Keys.isScalePreset(1.3) === false, "1.3 is custom")
assert(Keys.scaleChoice(1.25, false) === "1.25", "choice preset")
assert(Keys.scaleChoice(1, true) === "custom", "choice custom flag")
assert(Keys.scaleChoice(1.3, false) === "custom", "choice inferred custom")
assert(Keys.normalizeSettings({ scale: 1.75 }).scale === 1.75, "settings scale")
assert(Keys.normalizeSettings({ scale: 1.75 }).scaleCustom === false, "preset not custom")
assert(Keys.normalizeSettings({ scale: 1.3 }).scale === 1.3, "custom scale persist")
assert(Keys.normalizeSettings({ scale: 1.3 }).scaleCustom === true, "infer custom")
assert(Keys.normalizeSettings({ scale: 1, scaleCustom: true }).scaleCustom === true, "flag custom")
assert(Keys.overlayRadius(true, 12) === 12, "radius on")
assert(Keys.overlayRadius(false, 12) === 0, "radius off")
assert(Keys.overlayRadius("off", 8) === 0, "radius flag off")
assert(Keys.normalizeSettings({ roundingEnabled: false, rounding: 20 }).roundingEnabled === false, "rounding disabled")
assert(Keys.normalizeSettings({ rounding: 40 }).rounding === 32, "rounding max")

const binds = [
  "bindd",
  "\tmodmask: 64",
  "\tkey: K",
  "\tdescription: Keybindings",
  "\tdispatcher: __lua",
  "bindd",
  "\tmodmask: 64",
  "\tkey: LEFT",
  "\tdescription: Focus on left window",
  "bindd",
  "\tmodmask: 64",
  "\tkey: SUPER + code:10",
  "\tdescription: Switch to workspace 1",
  "bindd",
  "\tmodmask: 64",
  "\tkey: mouse:272",
  "\tdescription: Left click",
  "bindd",
  "\tmodmask: 64",
  "\tkey: RETURN",
  "\tdescription: ",
  "bindd",
  "\tmodmask: 65",
  "\tkey: LEFT",
  "\tdescription: Swap window to the left"
].join("\n")
const catalog = Keys.parseBinds(binds)
assert(Keys.comboFromLabels(["Super", "K"]) === "SUPER+K", "combo super k")
assert(Keys.comboFromLabels(["Super", "Left arrow"]) === "SUPER+LEFT", "combo super left")
assert(Keys.comboFromLabels(["Super", "Left"]) === "SUPER+LEFT", "combo super left alias")
assert(Keys.comboFromLabels(["Super", "1"]) === "SUPER+1", "combo workspace")
assert(Keys.comboFromLabels(["Super"]) === "", "modifiers only")
assert(Keys.actionForLabels(catalog, ["Super", "K"]) === "Keybindings", "action super k")
assert(Keys.actionForLabels(catalog, ["Super", "Left arrow"]) === "Focus on left window", "action super left")
assert(Keys.actionForLabels(catalog, ["Super", "Shift", "Left arrow"]) === "Swap window to the left", "action super shift left")
assert(Keys.actionForLabels(catalog, ["Super", "1"]) === "Switch to workspace 1", "action code key")
assert(Keys.actionForLabels(catalog, ["Super"]) === "", "no action for super only")
assert(Keys.actionForLabels(catalog, ["Super", "Enter"]) === "", "skip empty description")
assert(catalog["SUPER+MOUSE:272"] === undefined, "skip mouse binds")
assert(Keys.isCatalogChangeEvent("configreloaded") === true, "reload event")
assert(Keys.isCatalogChangeEvent("custom") === false, "ignore custom")
assert(Keys.normalizeSettings({}).actionEnabled === true, "action default on")
assert(Keys.normalizeSettings({}).previewEnabled === true, "preview default on")
assert(Keys.normalizeSettings({ previewEnabled: false }).previewEnabled === false, "preview off")
assert(Keys.normalizeSettings({}).actionPosition === "above", "action above default")
assert(Keys.normalizeSettings({ actionEnabled: false, actionPosition: "ABOVE" }).actionEnabled === false, "action off")
assert(Keys.normalizeSettings({ actionEnabled: false, actionPosition: "ABOVE" }).actionPosition === "above", "action above")

assert(Keys.normalizeHex("#abc") === "#AABBCC", "short hex")
assert(Keys.normalizeHex("1a1a1a") === "#1A1A1A", "hex without hash")
assert(Keys.normalizeHex("#1a1a1aff") === "#1A1A1A", "hex with alpha")
assert(Keys.normalizeHex("nope", "#111111") === "#111111", "bad hex fallback")
assert(Keys.normalizeSettings({}).colorTheme === "shell", "theme default shell")
assert(Keys.normalizeSettings({ colorTheme: "NORD" }).colorTheme === "nord", "theme nord")
assert(Keys.resolvedOverlayColors({ colorTheme: "shell" }).source === "shell", "shell source")
assert(Keys.resolvedOverlayColors({ colorTheme: "mocha" }).background === "#1E1E2E", "mocha bg")
assert(Keys.resolvedOverlayColors({ colorTheme: "mocha" }).font === "#CDD6F4", "mocha font")
assert(Keys.resolvedOverlayColors({
  colorTheme: "custom",
  backgroundColor: "#112233",
  borderColor: "#445566",
  fontColor: "#778899"
}).background === "#112233", "custom bg")
assert(Keys.colorToHex({ r: 1, g: 0, b: 0 }) === "#FF0000", "color object red")
assert(Keys.colorToHex({ r: 0, g: 0, b: 0 }) === "#000000", "color object black")
assert(Keys.colorToHex("#abc") === "#AABBCC", "color string short")
assert(Keys.presetColors("dark").border === "#6E6E6E", "dark preset")
assert(Keys.resolvedOverlayColors({ colorTheme: "gold" }).border === "#D4AF37", "gold border")
assert(Keys.resolvedOverlayColors({ colorTheme: "neon" }).border === "#FF00AA", "neon border")
assert(Keys.resolvedOverlayColors({ colorTheme: "matrix" }).font === "#C8FFC8", "matrix font")
assert(Keys.resolvedOverlayColors({ colorTheme: "vapor" }).background === "#1B0B2E", "vapor bg")
assert(Keys.resolvedOverlayColors({ colorTheme: "cyber" }).border === "#FCEE09", "cyber border")
assert(Keys.resolvedOverlayColors({ colorTheme: "ember" }).border === "#FF4D00", "ember border")
assert(Keys.resolvedOverlayColors({ colorTheme: "ice" }).border === "#5CE1FF", "ice border")
assert(Keys.themeOptions().length === 14, "theme option count")
assert(Keys.themeOptions()[7].value === "neon", "theme neon slot")
assert(Keys.themeOptions()[13].value === "custom", "theme custom last")
assert(Keys.normalizeFontFamily("") === "shell", "font default empty")
assert(Keys.normalizeFontFamily("SHELL") === "shell", "font shell token")
assert(Keys.normalizeFontFamily(" JetBrains Mono ") === "JetBrains Mono", "font trim")
assert(Keys.resolvedFontFamily("shell", "CaskaydiaCove Nerd Font") === "CaskaydiaCove Nerd Font", "font shell resolve")
assert(Keys.resolvedFontFamily("Inter", "mono") === "Inter", "font custom resolve")
assert(Keys.normalizeSettings({}).fontFamily === "shell", "settings font default")
const fonts = Keys.fontOptions(["Zed", "Inter", "inter", "", "Noto Sans"])
assert(fonts[0].value === "shell" && fonts[0].label === "Shell", "font list shell first")
assert(fonts.length === 4, "font list unique")
assert(fonts[1].value === "Inter" && fonts[2].value === "Noto Sans" && fonts[3].value === "Zed", "font list sort")

assert(Keys.comboToLabels("SUPER+K").join(",") === "Super,K", "labels super k")
assert(Keys.comboToLabels("SUPER+LEFT").join(",") === "Super,Left arrow", "labels super left")
assert(Keys.comboToLabels("SUPER+SHIFT+LEFT").join(",") === "Super,Shift,Left arrow", "labels super shift left")
assert(Keys.comboToLabels("SUPER+1").join(",") === "Super,1", "labels super 1")
assert(Keys.comboToLabels("CTRL+ALT+T").join(",") === "Ctrl,Alt,T", "labels ctrl alt t")
assert(Keys.comboToLabels("SUPER+PAGE UP").join(",") === "Super,Page Up", "labels page up")

const fallbackPreview = Keys.randomPreview({})
assert(fallbackPreview.combo === "SUPER+K", "empty catalog combo")
assert(fallbackPreview.action === "Keybindings", "empty catalog action")
assert(fallbackPreview.labels.join(",") === "Super,K", "empty catalog labels")

const livePreview = Keys.randomPreview(catalog)
assert(Array.isArray(livePreview.labels) && livePreview.labels.length > 0, "preview labels")
assert(catalog[livePreview.combo] === livePreview.action, "preview is a real bind")
assert(Keys.comboFromLabels(livePreview.labels) === livePreview.combo, "preview roundtrip")
assert(Keys.overlayLabels(["A"], true, ["Super", "K"]).join(",") === "A", "held keys win preview")
assert(Keys.overlayLabels([], true, ["Super", "K"]).join(",") === "Super,K", "preview when idle")
assert(Keys.overlayLabels([], false, ["Super", "K"]).join(",") === "", "preview off")

const pointer = Keys.parsePointer("keycast:v1:pointer:down:left:10,20")
assert(pointer.ok && pointer.phase === "down" && pointer.button === "left", "pointer parse")
assert(pointer.x === 10 && pointer.y === 20, "pointer position")
assert(Keys.parsePointer("keycast:v1:pointer:side:left:1,2").ok === false, "pointer phase")
assert(Keys.parsePointer("keycast:v1:held:10").ok === false, "pointer prefix")
const mouseDefaults = Keys.normalizeSettings({})
assert(mouseDefaults.mouseEnabled === true, "mouse default on")
assert(mouseDefaults.mouseBack === false, "back default off")
assert(mouseDefaults.mouseWheelDown === true, "wheel down default")
assert(mouseDefaults.mouseWheelLeft === false, "wheel left default")
assert(mouseDefaults.mousePlacement === "inline", "mouse placement default")
assert(mouseDefaults.mouseLabelStyle === "short", "mouse label default")
assert(mouseDefaults.mouseLingerMs === 500, "mouse linger default")
assert(mouseDefaults.mouseRippleSize === 36, "ripple size default")
assert(mouseDefaults.mouseRippleMs === 400, "ripple ms default")
assert(mouseDefaults.mouseRippleFollow === false, "ripple follow default")
assert(mouseDefaults.mouseRippleFade === false, "ripple fade default")
assert(Keys.parsePointer("keycast:v1:pointer:move:left:12,24").phase === "move", "pointer move")
assert(Keys.normalizeSettings({ mousePlacement: "ABOVE" }).mousePlacement === "above", "mouse placement")
assert(Keys.normalizeSettings({ mouseRippleSize: 4 }).mouseRippleSize === 8, "ripple size min")
assert(Keys.isMouseFlag("mouseLeft") === true, "mouse flag")
assert(Keys.isMouseFlag("scale") === false, "not mouse flag")
assert(Keys.labelFor(113) === "Left arrow", "left arrow label")
assert(Keys.labelFor(111) === "Up arrow", "up arrow label")
assert(Keys.pointerLabel("left", "short") === "LMB", "short left")
assert(Keys.pointerLabel("left", "name") === "Left mouse", "name left")
assert(Keys.pointerLabel("wheel-down", "name") === "Scroll down", "name wheel")
assert(Keys.mouseLabels(["right", "left"], "short", mouseDefaults).join(",") === "LMB,RMB", "mouse order")
assert(Keys.mouseLabels(["back", "left"], "name", mouseDefaults).join(",") === "Left mouse", "back filtered")
assert(Keys.pointerEnabled({ mouseEnabled: false, mouseLeft: true }, "left") === false, "mouse master off")

console.log("keys ok")
