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

  readonly property string settingsLayout: service && service.settingsLayout === "center" ? "center" : "side"
  readonly property bool wideLayout: settingsLayout === "center"

  function open() {
    refreshFontChoices()
    if (service && typeof service.inspectBridge === "function") service.inspectBridge()
    if (settingsForm.formScroll) settingsForm.formScroll.contentY = 0
    controller.show()
    syncPreview()
    syncPanels()
  }

  function close() {
    if (service) service.stopIgnoreRecording()
    controller.hide()
    syncPreview()
    syncPanels()
  }
  function toggle() { if (opened) close(); else open() }
  function closeForPopoutSwitch() { close() }

  function syncPanels() {
    sidePanel.open = opened === true && !wideLayout
    centerPanel.open = opened === true && wideLayout
  }

  onBarChanged: syncService()
  onOpenedChanged: {
    syncPreview()
    syncPanels()
  }
  onServiceChanged: syncPreview()
  onWideLayoutChanged: {
    syncPanels()
    if (settingsForm.formScroll) settingsForm.formScroll.contentY = 0
  }
  onSettingsPageChanged: {
    if (settingsForm.formScroll) settingsForm.formScroll.contentY = 0
    if (settingsPage === "overlay") refreshFontChoices()
  }
  Component.onCompleted: {
    syncService()
    refreshFontChoices()
    syncPanels()
  }

  Timer {
    interval: 250
    repeat: true
    running: root.service === null
    onTriggered: root.syncService()
  }


  SettingsForm {
    id: settingsForm
    parent: root.wideLayout ? centerSlot : sideSlot
    anchors.fill: parent
    host: root
    wide: root.wideLayout
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
    contentHeight: sidePanel.fittedContentHeight(settingsForm.formHeight,
      sidePanel.availableCardHeight > 0 ? sidePanel.availableCardHeight : Style.space(560))

    PanelKeyCatcher {
      id: sideCatcher
      anchors.fill: parent
      blocked: settingsForm.fieldBusy
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
    focusTarget: centerCatcher
    contentWidth: centerPanel.fittedContentWidth(centerPanel.centerBoxWidth)
    contentHeight: centerPanel.fittedContentHeight(centerPanel.centerBoxHeight, centerPanel.centerBoxHeight)

    PanelKeyCatcher {
      id: centerCatcher
      anchors.fill: parent
      blocked: settingsForm.fieldBusy
      onCloseRequested: root.close()

      Item {
        id: centerSlot
        anchors.fill: parent
      }
    }
  }
}
