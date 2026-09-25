import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import "Keys.js" as Keys

Item {
  id: root

  readonly property string moduleName: "local.keycast"
  property var shell: null
  property var manifest: null

  property bool overlayEnabled: false
  property bool showWhileRecording: false
  property bool captureRecording: false
  property bool openedForRecording: false
  property bool frameEnabled: false
  property bool roundingEnabled: true
  property int rounding: 8
  property string vertical: "bottom"
  property string horizontal: "middle"
  property int padding: 24
  property real scaleFactor: 1
  property bool scaleCustom: false
  readonly property string scaleChoice: Keys.scaleChoice(scaleFactor, scaleCustom)
  property int lingerMs: 600
  property bool actionEnabled: true
  property bool previewEnabled: true
  property string actionPosition: "above"
  property string colorTheme: "shell"
  property string fontFamily: "shell"
  readonly property string overlayTypeface: Keys.resolvedFontFamily(fontFamily, Style.font.family)
  property string backgroundColor: "#1A1A1A"
  property string borderColor: "#6E6E6E"
  property string fontColor: "#F5F5F5"
  property bool mouseEnabled: true
  property bool mouseLeft: true
  property bool mouseRight: true
  property bool mouseMiddle: true
  property bool mouseBack: false
  property bool mouseForward: false
  property bool mouseWheelUp: true
  property bool mouseWheelDown: true
  property bool mouseWheelLeft: false
  property bool mouseWheelRight: false
  property bool mouseRequireKeys: false
  property bool mouseRipple: true
  property bool mouseRippleScroll: false
  property bool mouseRippleFollow: false
  property int mouseRippleFollowMs: 16
  property var pendingRippleMove: null
  property real lastRippleMoveAt: 0
  property bool mouseRippleFade: false
  property int rippleTick: 0
  property string mousePlacement: "inline"
  property string mouseLabelStyle: "short"
  property int mouseLingerMs: 500
  property int mouseRippleSize: 36
  property int mouseRippleMs: 400
  property var pointerHeld: []
  property string pointerPulse: ""
  property var displayedPointerButtons: []
  property var pointerRipples: []
  property int rippleSerial: 0
  readonly property bool useShellColors: colorTheme === "shell"
  readonly property string displayBackgroundColor: useShellColors
    ? Keys.colorToHex(Color.background, backgroundColor) : backgroundColor
  readonly property string displayBorderColor: useShellColors
    ? Keys.colorToHex(Color.popups.border, borderColor) : borderColor
  readonly property string displayFontColor: useShellColors
    ? Keys.colorToHex(Color.popups.text, fontColor) : fontColor
  readonly property color overlayBackground: useShellColors
    ? Color.background
    : Style.colorFromHex(backgroundColor, Color.background)
  readonly property color overlayBorderTone: useShellColors
    ? Color.popups.border
    : Style.colorFromHex(borderColor, Color.popups.border)
  readonly property color overlayFontTone: useShellColors
    ? Color.popups.text
    : Style.colorFromHex(fontColor, Color.popups.text)
  property int colorEpoch: 0
  property var bindCatalog: ({})
  property var heldKeys: []
  property var displayedKeys: []
  property bool previewActive: false
  property var previewKeys: []
  property string previewAction: ""
  property int previewEpoch: 0
  readonly property var overlayLabels: Keys.overlayLabels(displayedKeys, previewActive, previewKeys)
  readonly property var displayedMouseLabels: {
    if (mouseRequireKeys && (!overlayLabels || overlayLabels.length === 0)) return []
    return Keys.mouseLabels(displayedPointerButtons, mouseLabelStyle, mouseSettings())
  }

  function mouseSettings() {
    return {
      mouseEnabled: mouseEnabled,
      mouseLeft: mouseLeft,
      mouseRight: mouseRight,
      mouseMiddle: mouseMiddle,
      mouseBack: mouseBack,
      mouseForward: mouseForward,
      mouseWheelUp: mouseWheelUp,
      mouseWheelDown: mouseWheelDown,
      mouseWheelLeft: mouseWheelLeft,
      mouseWheelRight: mouseWheelRight
    }
  }

  function displayLive() {
    return overlayEnabled || previewActive
  }
  readonly property string displayedAction: {
    if (!actionEnabled) return ""
    if (displayedKeys && displayedKeys.length > 0)
      return Keys.actionForLabels(bindCatalog, displayedKeys)
    if (previewActive) return previewAction
    return ""
  }
  property bool bridgeInstalled: false
  property bool bridgeLive: false
  property bool bridgeBusy: false
  property string pendingMutation: ""
  property string bridgeState: "unknown"
  property string manualSnippet: ""
  property var bridgeDetails: ({})

  function localPath(url) {
    var value = String(url || "")
    if (value.indexOf("file://") === 0) value = decodeURIComponent(value.substring(7))
    return value
  }

  readonly property string controllerPath: localPath(Qt.resolvedUrl("scripts/bridge-control"))

  function settingsEntry() {
    if (root.shell && root.shell.barConfig)
      return Keys.settingsFromBar(root.shell.barConfig, root.moduleName)
    return {}
  }

  function applySettings(entry) {
    var next = Keys.normalizeSettings(entry)
    var colorsChanged = colorTheme !== next.colorTheme
      || backgroundColor !== next.backgroundColor
      || borderColor !== next.borderColor
      || fontColor !== next.fontColor
    overlayEnabled = next.overlayEnabled
    showWhileRecording = next.showWhileRecording
    if (!showWhileRecording) openedForRecording = false
    frameEnabled = next.frameEnabled
    roundingEnabled = next.roundingEnabled
    rounding = next.rounding
    vertical = next.vertical
    horizontal = next.horizontal
    padding = next.padding
    scaleFactor = next.scale
    scaleCustom = next.scaleCustom === true
    lingerMs = next.lingerMs
    actionEnabled = next.actionEnabled
    previewEnabled = next.previewEnabled
    actionPosition = next.actionPosition
    colorTheme = next.colorTheme
    fontFamily = next.fontFamily
    backgroundColor = next.backgroundColor
    borderColor = next.borderColor
    fontColor = next.fontColor
    mouseEnabled = next.mouseEnabled
    mouseLeft = next.mouseLeft
    mouseRight = next.mouseRight
    mouseMiddle = next.mouseMiddle
    mouseBack = next.mouseBack
    mouseForward = next.mouseForward
    mouseWheelUp = next.mouseWheelUp
    mouseWheelDown = next.mouseWheelDown
    mouseWheelLeft = next.mouseWheelLeft
    mouseWheelRight = next.mouseWheelRight
    mouseRequireKeys = next.mouseRequireKeys
    mouseRipple = next.mouseRipple
    mouseRippleScroll = next.mouseRippleScroll
    mouseRippleFollow = next.mouseRippleFollow
    mouseRippleFollowMs = next.mouseRippleFollowMs
    mouseRippleFade = next.mouseRippleFade
    mousePlacement = next.mousePlacement
    mouseLabelStyle = next.mouseLabelStyle
    mouseLingerMs = next.mouseLingerMs
    mouseRippleSize = next.mouseRippleSize
    mouseRippleMs = next.mouseRippleMs
    if (colorsChanged) colorEpoch += 1
    lingerTimer.interval = Math.max(1, next.lingerMs)
    if (!previewEnabled && previewActive) setPreviewActive(false)
    if (!overlayEnabled) {
      lingerTimer.stop()
      displayedKeys = []
    } else if (heldKeys.length > 0) {
      displayedKeys = heldKeys
    }
    if (!displayLive() || !mouseEnabled) {
      clearPointerDisplay()
      pointerHeld = []
    } else publishPointer()
  }

  function persistSettings(changes) {
    var next = {
      id: root.moduleName,
      overlayEnabled: overlayEnabled,
      showWhileRecording: showWhileRecording,
      frameEnabled: frameEnabled,
      roundingEnabled: roundingEnabled,
      rounding: rounding,
      vertical: vertical,
      horizontal: horizontal,
      padding: padding,
      scale: scaleFactor,
      scaleCustom: scaleCustom,
      lingerMs: lingerMs,
      actionEnabled: actionEnabled,
      previewEnabled: previewEnabled,
      actionPosition: actionPosition,
      colorTheme: colorTheme,
      fontFamily: fontFamily,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      fontColor: fontColor,
      mouseEnabled: mouseEnabled,
      mouseLeft: mouseLeft,
      mouseRight: mouseRight,
      mouseMiddle: mouseMiddle,
      mouseBack: mouseBack,
      mouseForward: mouseForward,
      mouseWheelUp: mouseWheelUp,
      mouseWheelDown: mouseWheelDown,
      mouseWheelLeft: mouseWheelLeft,
      mouseWheelRight: mouseWheelRight,
      mouseRequireKeys: mouseRequireKeys,
      mouseRipple: mouseRipple,
      mouseRippleScroll: mouseRippleScroll,
      mouseRippleFollow: mouseRippleFollow,
      mouseRippleFollowMs: mouseRippleFollowMs,
      mouseRippleFade: mouseRippleFade,
      mousePlacement: mousePlacement,
      mouseLabelStyle: mouseLabelStyle,
      mouseLingerMs: mouseLingerMs,
      mouseRippleSize: mouseRippleSize,
      mouseRippleMs: mouseRippleMs
    }
    for (var changed in changes) next[changed] = changes[changed]
    applySettings(next)
    if (!root.shell || typeof root.shell.updateEntryInline !== "function") return false
    return root.shell.updateEntryInline(root.moduleName, next)
  }

  function applyOverlayEnabled(value) {
    var next = Keys.isEnabledFlag(value)
    if (next === overlayEnabled) return false
    return persistSettings({ overlayEnabled: next })
  }

  function setOverlayEnabled(value) {
    openedForRecording = false
    return applyOverlayEnabled(value)
  }

  function setShowWhileRecording(value) {
    var next = Keys.normalizeSettings({ showWhileRecording: value }).showWhileRecording
    if (next === showWhileRecording) return false
    if (!next) openedForRecording = false
    var saved = persistSettings({ showWhileRecording: next })
    if (next) {
      captureRecording = false
      pollCapture()
    }
    return saved
  }

  function pollCapture() {
    if (!showWhileRecording || captureProbe.running) return
    captureProbe.running = true
  }

  function syncCaptureRecording(active) {
    var next = active === true
    if (next === captureRecording) return
    captureRecording = next
    if (!showWhileRecording) return
    if (next) {
      if (!overlayEnabled) {
        openedForRecording = true
        applyOverlayEnabled(true)
      }
    } else if (openedForRecording) {
      openedForRecording = false
      applyOverlayEnabled(false)
    }
  }

  function setFrameEnabled(value) {
    var next = Keys.normalizeSettings({ frameEnabled: value }).frameEnabled
    if (next === frameEnabled) return false
    return persistSettings({ frameEnabled: next })
  }

  function setRoundingEnabled(value) {
    var next = Keys.normalizeSettings({ roundingEnabled: value }).roundingEnabled
    if (next === roundingEnabled) return false
    return persistSettings({ roundingEnabled: next })
  }

  function setRounding(value) {
    var next = Keys.normalizeSettings({ rounding: value }).rounding
    if (next === rounding) return false
    return persistSettings({ rounding: next })
  }

  function setVertical(value) {
    var next = Keys.normalizeSettings({ vertical: value }).vertical
    if (next === vertical) return false
    return persistSettings({ vertical: next })
  }

  function setHorizontal(value) {
    var next = Keys.normalizeSettings({ horizontal: value }).horizontal
    if (next === horizontal) return false
    return persistSettings({ horizontal: next })
  }

  function setPadding(value) {
    var next = Keys.normalizeSettings({ padding: value }).padding
    if (next === padding) return false
    return persistSettings({ padding: next })
  }

  function setScale(value) {
    if (String(value) === "custom") {
      if (scaleCustom) return false
      return persistSettings({ scaleCustom: true, scale: scaleFactor })
    }
    var next = Keys.clampScalePreset(value)
    if (!scaleCustom && next === scaleFactor) return false
    return persistSettings({ scaleCustom: false, scale: next })
  }

  function setCustomScale(value) {
    var next = Keys.clampScale(value)
    if (scaleCustom && next === scaleFactor) return false
    return persistSettings({ scaleCustom: true, scale: next })
  }

  function setLingerMs(value) {
    var next = Keys.normalizeSettings({ lingerMs: value }).lingerMs
    if (next === lingerMs) return false
    return persistSettings({ lingerMs: next })
  }

  function setActionEnabled(value) {
    var next = Keys.normalizeSettings({ actionEnabled: value }).actionEnabled
    if (next === actionEnabled) return false
    return persistSettings({ actionEnabled: next })
  }

  function setPreviewEnabled(value) {
    var next = Keys.normalizeSettings({ previewEnabled: value }).previewEnabled
    if (next === previewEnabled) return false
    return persistSettings({ previewEnabled: next })
  }

  function setActionPosition(value) {
    var next = Keys.normalizeSettings({ actionPosition: value }).actionPosition
    if (next === actionPosition) return false
    return persistSettings({ actionPosition: next })
  }

  function setFontFamily(value) {
    var next = Keys.normalizeFontFamily(value)
    if (next === fontFamily) return false
    return persistSettings({ fontFamily: next })
  }

  function setColorTheme(value) {
    var theme = Keys.normalizeSettings({ colorTheme: value }).colorTheme
    var preset = Keys.presetColors(theme)
    if (preset) {
      return persistSettings({
        colorTheme: theme,
        backgroundColor: preset.background,
        borderColor: preset.border,
        fontColor: preset.font
      })
    }
    if (theme === "shell") {
      return persistSettings({
        colorTheme: "shell",
        backgroundColor: Keys.colorToHex(Color.background, backgroundColor),
        borderColor: Keys.colorToHex(Color.popups.border, borderColor),
        fontColor: Keys.colorToHex(Color.popups.text, fontColor)
      })
    }
    if (theme === colorTheme) return false
    return persistSettings({ colorTheme: theme })
  }

  function setBackgroundColor(value) {
    var next = Keys.normalizeHex(value, displayBackgroundColor)
    if (next === displayBackgroundColor && colorTheme !== "custom") return false
    if (colorTheme === "custom" && next === backgroundColor) return false
    return persistSettings({ colorTheme: "custom", backgroundColor: next })
  }

  function setBorderColor(value) {
    var next = Keys.normalizeHex(value, displayBorderColor)
    if (next === displayBorderColor && colorTheme !== "custom") return false
    if (colorTheme === "custom" && next === borderColor) return false
    return persistSettings({ colorTheme: "custom", borderColor: next })
  }

  function setFontColor(value) {
    var next = Keys.normalizeHex(value, displayFontColor)
    if (next === displayFontColor && colorTheme !== "custom") return false
    if (colorTheme === "custom" && next === fontColor) return false
    return persistSettings({ colorTheme: "custom", fontColor: next })
  }

  function toggleOverlay() {
    return setOverlayEnabled(!overlayEnabled)
  }

  function pickPreview() {
    var picked = Keys.randomPreview(bindCatalog)
    previewKeys = picked.labels
    previewAction = picked.action
    previewEpoch += 1
  }

  function setPreviewActive(value) {
    var next = value === true && previewEnabled
    if (next === previewActive) {
      if (next && (!previewKeys || previewKeys.length === 0)) pickPreview()
      return next
    }
    previewActive = next
    if (next) pickPreview()
    else {
      previewKeys = []
      previewAction = ""
      if (!overlayEnabled) {
        lingerTimer.stop()
        displayedKeys = []
        clearPointerDisplay()
      }
    }
    publishPointer()
    return next
  }

  function withoutButton(list, button) {
    var out = []
    var src = list || []
    for (var i = 0; i < src.length; i++) {
      if (src[i] !== button) out.push(src[i])
    }
    return out
  }

  function clearPointerDisplay() {
    pointerPulse = ""
    displayedPointerButtons = []
    pointerRipples = []
    pendingRippleMove = null
    rippleFollowTimer.stop()
    mouseLinger.stop()
  }

  function publishPointer() {
    if (!displayLive() || !mouseEnabled) {
      displayedPointerButtons = []
      return
    }
    var buttons = pointerHeld.slice()
    if (pointerPulse) buttons.push(pointerPulse)
    displayedPointerButtons = buttons
  }

  function armMouseLinger() {
    if (!displayLive() || mouseLingerMs <= 0) {
      pointerPulse = ""
      if (pointerHeld.length === 0) displayedPointerButtons = []
      else publishPointer()
      return
    }
    mouseLinger.interval = Math.max(1, mouseLingerMs)
    mouseLinger.restart()
  }

  function pushRipple(parsed, held) {
    var next = pointerRipples.slice()
    next.push({
      id: ++rippleSerial,
      button: parsed.button,
      x: parsed.x,
      y: parsed.y,
      born: Date.now(),
      held: held === true
    })
    if (next.length > 8) next = next.slice(next.length - 8)
    pointerRipples = next
  }

  function releaseRipple(button) {
    var next = pointerRipples.slice()
    var changed = false
    var now = Date.now()
    for (var i = 0; i < next.length; i++) {
      if (next[i].button !== button || next[i].held !== true) continue
      next[i] = {
        id: next[i].id,
        button: next[i].button,
        x: next[i].x,
        y: next[i].y,
        born: now,
        held: false
      }
      changed = true
    }
    if (changed) pointerRipples = next
  }

  function placeRipple(parsed) {
    var next = pointerRipples.slice()
    var found = -1
    for (var i = next.length - 1; i >= 0; i--) {
      if (next[i].button === parsed.button && next[i].held === true) {
        found = i
        break
      }
    }
    if (found < 0) return
    var item = next[found]
    if (item.x === parsed.x && item.y === parsed.y) return
    next[found] = {
      id: item.id,
      button: item.button,
      x: parsed.x,
      y: parsed.y,
      born: item.born,
      held: true
    }
    pointerRipples = next
  }

  function moveRipple(parsed) {
    var gap = Math.max(8, mouseRippleFollowMs)
    var now = Date.now()
    if (lastRippleMoveAt <= 0 || now - lastRippleMoveAt >= gap) {
      lastRippleMoveAt = now
      pendingRippleMove = null
      rippleFollowTimer.stop()
      placeRipple(parsed)
      return
    }
    pendingRippleMove = parsed
    if (!rippleFollowTimer.running) {
      rippleFollowTimer.interval = Math.max(1, gap - (now - lastRippleMoveAt))
      rippleFollowTimer.restart()
    }
  }

  function flushRippleMove() {
    var pending = pendingRippleMove
    pendingRippleMove = null
    if (!pending || !mouseRipple || !mouseRippleFollow) return
    lastRippleMoveAt = Date.now()
    placeRipple(pending)
  }

  function handlePointer(parsed) {
    bridgeLive = true
    if (!displayLive()) return
    if (!Keys.pointerEnabled(mouseSettings(), parsed.button)) return
    if (parsed.phase === "down") {
      if (pointerHeld.indexOf(parsed.button) === -1)
        pointerHeld = pointerHeld.concat([parsed.button])
      pointerPulse = ""
      mouseLinger.stop()
      publishPointer()
      if (mouseRipple) {
        releaseRipple(parsed.button)
        pushRipple(parsed, true)
      }
    } else if (parsed.phase === "up") {
      pointerHeld = withoutButton(pointerHeld, parsed.button)
      flushRippleMove()
      releaseRipple(parsed.button)
      if (pointerHeld.length === 0) armMouseLinger()
      else publishPointer()
    } else if (parsed.phase === "pulse") {
      pointerPulse = parsed.button
      publishPointer()
      armMouseLinger()
      if (mouseRipple && mouseRippleScroll) pushRipple(parsed, false)
    } else if (parsed.phase === "move") {
      if (mouseRipple && mouseRippleFollow) moveRipple(parsed)
    }
  }

  function setMouseFlag(key, value) {
    if (!Keys.isMouseFlag(key)) return false
    var patch = {}
    patch[key] = value
    var next = Keys.normalizeSettings(patch)[key]
    if (next === root[key]) return false
    var changes = {}
    changes[key] = next
    return persistSettings(changes)
  }

  function setMousePlacement(value) {
    var next = Keys.normalizeSettings({ mousePlacement: value }).mousePlacement
    if (next === mousePlacement) return false
    return persistSettings({ mousePlacement: next })
  }

  function setMouseLabelStyle(value) {
    var next = Keys.normalizeSettings({ mouseLabelStyle: value }).mouseLabelStyle
    if (next === mouseLabelStyle) return false
    return persistSettings({ mouseLabelStyle: next })
  }

  function setMouseLingerMs(value) {
    var next = Keys.normalizeSettings({ mouseLingerMs: value }).mouseLingerMs
    if (next === mouseLingerMs) return false
    return persistSettings({ mouseLingerMs: next })
  }

  function setMouseRippleSize(value) {
    var next = Keys.normalizeSettings({ mouseRippleSize: value }).mouseRippleSize
    if (next === mouseRippleSize) return false
    return persistSettings({ mouseRippleSize: next })
  }

  function setMouseRippleFollowMs(value) {
    var next = Keys.normalizeSettings({ mouseRippleFollowMs: value }).mouseRippleFollowMs
    if (next === mouseRippleFollowMs) return false
    return persistSettings({ mouseRippleFollowMs: next })
  }

  function setMouseRippleMs(value) {
    var next = Keys.normalizeSettings({ mouseRippleMs: value }).mouseRippleMs
    if (next === mouseRippleMs) return false
    return persistSettings({ mouseRippleMs: next })
  }

  function applyHeldLabels(labels) {
    var nextDisplay = Keys.displayedAfterHeld(heldKeys, labels, displayedKeys)
    heldKeys = labels
    if (!overlayEnabled && !previewActive) {
      lingerTimer.stop()
      displayedKeys = []
      return
    }
    displayedKeys = nextDisplay
    if (labels.length > 0) {
      lingerTimer.stop()
      return
    }
    if (lingerMs <= 0 || displayedKeys.length === 0) {
      displayedKeys = []
      return
    }
    lingerTimer.interval = lingerMs
    lingerTimer.restart()
  }

  function handleProtocolEvent(payload) {
    var text = String(payload || "")
    if (text.indexOf("keycast:v1:pointer:") === 0) {
      var pointer = Keys.parsePointer(text)
      if (!pointer.ok) return false
      handlePointer(pointer)
      return true
    }
    var parsed = Keys.parseProtocol(text)
    if (!parsed.ok) return false
    bridgeLive = true
    applyHeldLabels(parsed.labels)
    return true
  }

  function handleRawEvent(event) {
    if (!event) return
    var name = String(event.name || "")
    if (name === "custom") {
      var payload = String(event.data || "")
      if (payload.indexOf("keycast:") === 0) handleProtocolEvent(payload)
      return
    }
    if (Keys.isCatalogChangeEvent(name)) refreshBinds()
  }

  function applyBinds(raw, exitCode) {
    if (exitCode !== 0) return false
    bindCatalog = Keys.parseBinds(String(raw || ""))
    if (previewActive && (!previewKeys || previewKeys.length === 0)) pickPreview()
    return true
  }

  function refreshBinds() {
    if (bindsProcess.running) return false
    bindsProcess.command = ["hyprctl", "binds"]
    bindsProcess.running = true
    return true
  }

  function applyInspectResult(raw, exitCode) {
    var parsed = null
    try { parsed = JSON.parse(String(raw || "")) } catch (e) {}
    if (exitCode !== 0 || !parsed) {
      bridgeState = "error"
      return false
    }
    bridgeDetails = parsed
    bridgeInstalled = parsed.managedBlockState === "present"
    bridgeState = parsed.managedBlockState === "present" ? "enabled"
      : parsed.safeToPatch === true ? "ready" : "review"
    return true
  }

  function inspectBridge() {
    if (inspectProcess.running || controllerPath === "") return false
    inspectProcess.command = [controllerPath, "inspect"]
    inspectProcess.running = true
    return true
  }

  function mutateBridge(action) {
    if (mutateProcess.running || controllerPath === "") return false
    bridgeBusy = true
    pendingMutation = action
    mutateProcess.command = [controllerPath, action]
    mutateProcess.running = true
    return true
  }

  function enableBridge() {
    return mutateBridge("enable")
  }

  function disableBridge() {
    setOverlayEnabled(false)
    applyHeldLabels([])
    clearPointerDisplay()
    pointerHeld = []
    return mutateBridge("disable")
  }

  Timer {
    id: lingerTimer
    interval: 600
    repeat: false
    onTriggered: {
      if (root.heldKeys.length === 0) root.displayedKeys = []
    }
  }

  Timer {
    id: mouseLinger
    interval: 500
    repeat: false
    onTriggered: {
      root.pointerPulse = ""
      if (root.pointerHeld.length === 0) root.displayedPointerButtons = []
      else root.publishPointer()
    }
  }

  Timer {
    id: rippleFollowTimer
    interval: 16
    repeat: false
    onTriggered: root.flushRippleMove()
  }

  Timer {
    interval: mouseRippleFade ? 16 : 50
    repeat: true
    running: root.pointerRipples.length > 0
    onTriggered: {
      if (root.mouseRippleFade) root.rippleTick = root.rippleTick + 1
      var now = Date.now()
      var life = Math.max(100, root.mouseRippleMs)
      var keep = []
      var list = root.pointerRipples
      for (var i = 0; i < list.length; i++) {
        if (list[i].held === true || now - list[i].born < life) keep.push(list[i])
      }
      if (keep.length !== list.length) root.pointerRipples = keep
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) { root.handleRawEvent(event) }
  }

  Connections {
    target: root.shell
    ignoreUnknownSignals: true
    function onBarConfigChanged() { root.applySettings(root.settingsEntry()) }
  }

  Process {
    id: inspectProcess
    running: false
    stdout: StdioCollector { id: inspectStdout; waitForEnd: true }
    onExited: root.applyInspectResult(inspectStdout.text, exitCode)
  }

  Process {
    id: mutateProcess
    running: false
    stdout: StdioCollector { id: mutateStdout; waitForEnd: true }
    onExited: {
      var action = root.pendingMutation
      root.bridgeBusy = false
      root.pendingMutation = ""
      root.applyInspectResult(mutateStdout.text, exitCode)
      if (exitCode === 0 && action === "enable") root.setOverlayEnabled(true)
      if (exitCode === 0) Qt.callLater(root.inspectBridge)
    }
  }

  Timer {
    interval: 250
    repeat: true
    running: root.showWhileRecording
    triggeredOnStart: true
    onTriggered: root.pollCapture()
  }

  Process {
    id: captureProbe
    running: false
    command: ["pgrep", "--quiet", "-f", "^gpu-screen-recorder"]
    onExited: function(exitCode) {
      if (!root.showWhileRecording) return
      root.syncCaptureRecording(exitCode === 0)
    }
  }

  Process {
    id: bindsProcess
    running: false
    stdout: StdioCollector { id: bindsStdout; waitForEnd: true }
    onExited: root.applyBinds(bindsStdout.text, exitCode)
  }

  Process {
    id: snippetProcess
    running: false
    stdout: StdioCollector { id: snippetStdout; waitForEnd: true }
    onExited: {
      try {
        var parsed = JSON.parse(String(snippetStdout.text || ""))
        if (parsed && typeof parsed.snippet === "string") root.manualSnippet = parsed.snippet
      } catch (e) {}
    }
  }

  IpcHandler {
    target: "local.keycast"
    function show(): string { root.setOverlayEnabled(true); return root.overlayEnabled ? "on" : "off" }
    function hide(): string { root.setOverlayEnabled(false); return "off" }
    function toggle(): string { root.toggleOverlay(); return root.overlayEnabled ? "on" : "off" }
    function state(): string { return root.overlayEnabled ? "on" : "off" }
    function ping(): string { return "ok" }
  }

  Component.onCompleted: Qt.callLater(function() {
    root.applySettings(root.settingsEntry())
    root.inspectBridge()
    root.refreshBinds()
    snippetProcess.command = [root.controllerPath, "manual-snippet"]
    snippetProcess.running = true
  })

  onShellChanged: Qt.callLater(function() { root.applySettings(root.settingsEntry()) })

  Overlay {
    service: root
  }
}
