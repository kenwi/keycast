import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "Keys.js" as Keys

Panel {
  id: root

  moduleName: "keycast"
  ipcTarget: "keycast-panel"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var service: null
  property string settingsPage: "overlay"
  property bool switchingLayout: false

  readonly property color fg: bar ? bar.barForeground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool bridgeReady: service && service.bridgeInstalled === true
  readonly property bool overlayOn: service && service.overlayEnabled === true
  readonly property bool previewSettingOn: service ? service.previewEnabled !== false : true
  property var fontChoices: []
  readonly property string bridgeSummary: {
    if (!service) return "Service unavailable"
    if (service.bridgeBusy) return "Updating Hyprland configuration…"
    if (service.bridgeInstalled) return "Hyprland bridge is active"
    if (service.bridgeState === "error") return "Could not inspect Hyprland configuration"
    if (service.bridgeState === "review") return "Automatic setup needs review; use the manual snippet"
    return "Install a small local Hyprland bridge to observe currently pressed keys"
  }

  function syncService() {
    service = bar && bar.shell && typeof bar.shell.serviceFor === "function"
      ? bar.shell.serviceFor(moduleName) : null
    syncPreview()
  }

  function syncPreview() {
    if (!service) return
    service.setPreviewActive(opened === true)
  }

  function refreshFontChoices() {
    fontChoices = Keys.fontOptions(Qt.fontFamilies())
  }

  readonly property string settingsLayout: {
    var value = service ? String(service.settingsLayout || "") : "side"
    if (value === "center" || value === "fullscreen") return value
    return "side"
  }
  readonly property bool wideLayout: settingsLayout !== "side"
  readonly property bool fullLayout: settingsLayout === "fullscreen"

  function open() {
    refreshFontChoices()
    if (service && typeof service.inspectBridge === "function") service.inspectBridge()
    var form = formLoader.item
    if (form && form.formScroll) form.formScroll.contentY = 0
    controller.show()
    syncPreview()
    syncPanels()
    // The wide window paints an empty black frame if its form was created
    // while the surface was unmapped. Build the form after the window maps.
    if (wideLayout) {
      formLoader.active = false
      Qt.callLater(root.showForm)
    }
  }

  function close() {
    if (service) service.stopIgnoreRecording()
    controller.hide()
    syncPreview()
    syncPanels()
  }
  function toggle() { if (opened) close(); else open() }
  function closeForPopoutSwitch() { close() }

  function showForm() {
    var slot = wideLayout ? centerSlot : sideSlot
    if (!slot) return
    if (formLoader.parent !== slot) formLoader.active = false
    formLoader.parent = slot
    formLoader.anchors.fill = slot
    var panel = wideLayout ? centerPanel : sidePanel
    if (opened && wideLayout && !panel.backingWindowVisible) {
      showFormTimer.restart()
      return
    }
    formLoader.active = true
  }

  function syncPanels() {
    if (switchingLayout) return
    sidePanel.open = opened === true && !wideLayout
    centerPanel.open = opened === true && wideLayout
  }

  function snapClosePanels() {
    centerPanel.suspendFade = true
    centerPanel.open = false
    centerPanel.suspendFade = false
    if (hostWidget) hostWidget.popoutSwitchClosing = true
    sidePanel.open = false
    if (hostWidget) hostWidget.popoutSwitchClosing = false
  }

  function finishLayoutSwap() {
    if (!opened) {
      switchingLayout = false
      return
    }
    if (centerPanel.visible || sidePanel.visible) {
      layoutSwapTimer.restart()
      return
    }
    var slot = wideLayout ? centerSlot : sideSlot
    formLoader.parent = slot
    formLoader.anchors.fill = slot
    switchingLayout = false
    if (wideLayout) {
      centerPanel.open = true
      Qt.callLater(root.showForm)
      return
    }
    formLoader.active = true
    sidePanel.open = true
  }

  function revealLayout() {
    var form = formLoader.item
    if (form && form.formScroll) form.formScroll.contentY = 0
    if (!opened) {
      showForm()
      syncPanels()
      return
    }
    // Unmap the current window completely, then map the next one the same
    // way a fresh open does. Mapping the next window in the same breath as
    // building its form leaves a black frame that does not recover.
    switchingLayout = true
    formLoader.active = false
    snapClosePanels()
    Qt.callLater(root.finishLayoutSwap)
  }

  onBarChanged: syncService()
  onOpenedChanged: {
    syncPreview()
    syncPanels()
  }
  onServiceChanged: syncPreview()
  onSettingsLayoutChanged: revealLayout()
  onSettingsPageChanged: {
    var form = formLoader.item
    if (form && form.formScroll) form.formScroll.contentY = 0
    if (settingsPage === "overlay") refreshFontChoices()
  }
  Component.onCompleted: {
    syncService()
    refreshFontChoices()
    showForm()
    syncPanels()
  }

  Timer {
    interval: 250
    repeat: true
    running: root.service === null
    onTriggered: root.syncService()
  }


  Component {
    id: formComponent
    SettingsForm {
      host: root
      wide: root.wideLayout
      fullscreen: root.fullLayout
    }
  }

  // Created inside the slot, never moved between the two windows. Moving one
  // item from the side window into the center window left that surface blank.
  Loader {
    id: formLoader
    active: false
    sourceComponent: formComponent
    anchors.fill: parent
  }

  Timer {
    id: showFormTimer
    interval: 16
    repeat: false
    onTriggered: root.showForm()
  }

  Timer {
    id: layoutSwapTimer
    interval: 32
    repeat: false
    onTriggered: root.finishLayoutSwap()
  }

  KeyboardPanel {
    id: sidePanel
    anchorItem: root.hostWidget || root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar || (root.hostWidget ? root.hostWidget.bar : null)
    open: false
    centerOnBar: false
    focusTarget: sideCatcher
    contentWidth: sidePanel.fittedContentWidth(Style.space(400))
    contentHeight: sidePanel.fittedContentHeight(formLoader.item ? formLoader.item.formHeight : 0,
      sidePanel.availableCardHeight > 0 ? sidePanel.availableCardHeight : Style.space(560))

    PanelKeyCatcher {
      id: sideCatcher
      anchors.fill: parent
      blocked: formLoader.item ? formLoader.item.fieldBusy === true : false
      onCloseRequested: root.close()

      Item {
        id: sideSlot
        anchors.fill: parent
      }
    }
  }

  WidePanel {
    id: centerPanel
    anchorItem: root.hostWidget || root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar || (root.hostWidget ? root.hostWidget.bar : null)
    open: false
    fillScreen: root.fullLayout
    focusTarget: centerCatcher
    contentWidth: root.fullLayout
      ? Math.max(1, Math.round(centerPanel.availableCardWidth))
      : centerPanel.fittedContentWidth(centerPanel.centerBoxWidth)
    contentHeight: root.fullLayout
      ? Math.max(1, Math.round(centerPanel.availableCardHeight))
      : centerPanel.fittedContentHeight(centerPanel.centerBoxHeight, centerPanel.centerBoxHeight)

    PanelKeyCatcher {
      id: centerCatcher
      anchors.fill: parent
      blocked: formLoader.item ? formLoader.item.fieldBusy === true : false
      onCloseRequested: root.close()

      Item {
        id: centerSlot
        anchors.fill: parent
      }
    }
  }
}
