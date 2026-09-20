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
assert(settings.vertical === "top", "vertical")
assert(settings.horizontal === "right", "horizontal")
assert(settings.padding === 80, "padding")
assert(settings.lingerMs === 1200, "linger")

const defaults = Keys.normalizeSettings({})
assert(defaults.overlayEnabled === false, "overlay default")
assert(defaults.vertical === "bottom", "vertical default")
assert(defaults.horizontal === "left", "horizontal default")
assert(defaults.padding === 24, "padding default")

const fromBar = Keys.settingsFromBar({
  layout: { right: [{ id: "local.keycast", padding: 12 }] }
}, "local.keycast")
assert(fromBar.padding === 12, "bar settings")

console.log("keys ok")
