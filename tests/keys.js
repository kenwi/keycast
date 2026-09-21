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
assert(settings.frameEnabled === true, "frame default when unset")
assert(settings.vertical === "top", "vertical")
assert(settings.horizontal === "right", "horizontal")
assert(settings.padding === 80, "padding")
assert(settings.scale === 1, "scale default when unset")
assert(settings.lingerMs === 1200, "linger")

const defaults = Keys.normalizeSettings({})
assert(defaults.overlayEnabled === false, "overlay default")
assert(defaults.frameEnabled === true, "frame default")
assert(defaults.roundingEnabled === true, "rounding default")
assert(defaults.rounding === 8, "rounding px default")
assert(defaults.vertical === "bottom", "vertical default")
assert(defaults.horizontal === "left", "horizontal default")
assert(defaults.padding === 24, "padding default")
assert(defaults.scale === 1, "scale default")

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
assert(Keys.clampScale(1.25) === 1.25, "scale 1.25")
assert(Keys.clampScale("1.5") === 1.5, "scale string")
assert(Keys.clampScale(1.3) === 1.25, "scale snaps")
assert(Keys.clampScale(3) === 2, "scale max")
assert(Keys.clampScale(0) === 0.75, "scale min")
assert(Keys.normalizeSettings({ scale: 1.75 }).scale === 1.75, "settings scale")
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
assert(Keys.comboFromLabels(["Super", "Left"]) === "SUPER+LEFT", "combo super left")
assert(Keys.comboFromLabels(["Super", "1"]) === "SUPER+1", "combo workspace")
assert(Keys.comboFromLabels(["Super"]) === "", "modifiers only")
assert(Keys.actionForLabels(catalog, ["Super", "K"]) === "Keybindings", "action super k")
assert(Keys.actionForLabels(catalog, ["Super", "Left"]) === "Focus on left window", "action super left")
assert(Keys.actionForLabels(catalog, ["Super", "Shift", "Left"]) === "Swap window to the left", "action super shift left")
assert(Keys.actionForLabels(catalog, ["Super", "1"]) === "Switch to workspace 1", "action code key")
assert(Keys.actionForLabels(catalog, ["Super"]) === "", "no action for super only")
assert(Keys.actionForLabels(catalog, ["Super", "Enter"]) === "", "skip empty description")
assert(catalog["SUPER+MOUSE:272"] === undefined, "skip mouse binds")
assert(Keys.isCatalogChangeEvent("configreloaded") === true, "reload event")
assert(Keys.isCatalogChangeEvent("custom") === false, "ignore custom")
assert(Keys.normalizeSettings({}).actionEnabled === true, "action default on")
assert(Keys.normalizeSettings({}).actionPosition === "below", "action below default")
assert(Keys.normalizeSettings({ actionEnabled: false, actionPosition: "ABOVE" }).actionEnabled === false, "action off")
assert(Keys.normalizeSettings({ actionEnabled: false, actionPosition: "ABOVE" }).actionPosition === "above", "action above")

console.log("keys ok")
