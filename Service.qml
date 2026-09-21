import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "Keys.js" as Keys

Item {
  id: root

  readonly property string moduleName: "local.keycast"
  property var shell: null
  property var manifest: null

  property bool overlayEnabled: false
  property bool frameEnabled: true
  property bool roundingEnabled: true
  property int rounding: 8
  property string vertical: "bottom"
  property string horizontal: "left"
  property int padding: 24
  property real scaleFactor: 1
  property int lingerMs: 600
  property bool actionEnabled: true
  property string actionPosition: "below"
  property var bindCatalog: ({})
  property var heldKeys: []
  property var displayedKeys: []
  readonly property string displayedAction: {
    if (!actionEnabled) return ""
    return Keys.actionForLabels(bindCatalog, displayedKeys)
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
    overlayEnabled = next.overlayEnabled
    frameEnabled = next.frameEnabled
    roundingEnabled = next.roundingEnabled
    rounding = next.rounding
    vertical = next.vertical
    horizontal = next.horizontal
    padding = next.padding
    scaleFactor = next.scale
    lingerMs = next.lingerMs
    actionEnabled = next.actionEnabled
    actionPosition = next.actionPosition
    lingerTimer.interval = Math.max(1, next.lingerMs)
    if (!overlayEnabled) {
      lingerTimer.stop()
      displayedKeys = []
    } else if (heldKeys.length > 0) {
      displayedKeys = heldKeys
    }
  }

  function persistSettings(changes) {
    var next = {
      id: root.moduleName,
      overlayEnabled: overlayEnabled,
      frameEnabled: frameEnabled,
      roundingEnabled: roundingEnabled,
      rounding: rounding,
      vertical: vertical,
      horizontal: horizontal,
      padding: padding,
      scale: scaleFactor,
      lingerMs: lingerMs,
      actionEnabled: actionEnabled,
      actionPosition: actionPosition
    }
    for (var changed in changes) next[changed] = changes[changed]
    applySettings(next)
    if (!root.shell || typeof root.shell.updateEntryInline !== "function") return false
    return root.shell.updateEntryInline(root.moduleName, next)
  }

  function setOverlayEnabled(value) {
    var next = Keys.isEnabledFlag(value)
    if (next === overlayEnabled) return false
    return persistSettings({ overlayEnabled: next })
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
    var next = Keys.normalizeSettings({ scale: value }).scale
    if (next === scaleFactor) return false
    return persistSettings({ scale: next })
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

  function setActionPosition(value) {
    var next = Keys.normalizeSettings({ actionPosition: value }).actionPosition
    if (next === actionPosition) return false
    return persistSettings({ actionPosition: next })
  }

  function toggleOverlay() {
    return setOverlayEnabled(!overlayEnabled)
  }

  function applyHeldLabels(labels) {
    var nextDisplay = Keys.displayedAfterHeld(heldKeys, labels, displayedKeys)
    heldKeys = labels
    if (!overlayEnabled) {
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
    var parsed = Keys.parseProtocol(payload)
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
