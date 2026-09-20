import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root

  moduleName: "local.keycast"
  ipcTarget: "local.keycast-panel"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var service: null

  readonly property color fg: bar ? bar.barForeground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool bridgeReady: service && service.bridgeInstalled === true
  readonly property bool overlayOn: service && service.overlayEnabled === true
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
  }

  function open() {
    if (service && typeof service.inspectBridge === "function") service.inspectBridge()
    controller.show()
  }

  function close() { controller.hide() }
  function toggle() { if (opened) close(); else open() }
  function closeForPopoutSwitch() { close() }

  onBarChanged: syncService()
  Component.onCompleted: syncService()

  Timer {
    interval: 250
    repeat: true
    running: root.service === null
    onTriggered: root.syncService()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.hostWidget || root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar || (root.hostWidget ? root.hostWidget.bar : null)
    open: root.opened
    centerOnBar: false
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()

      Column {
        id: contentColumn
        width: parent.width
        spacing: Style.space(12)

      Column {
        width: parent.width
        spacing: Style.space(3)

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: "KEYCAST"
          color: root.fg
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          font.bold: true
        }
        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: root.bridgeSummary
          color: root.fg
          opacity: 0.78
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }
      }

      Column {
        visible: !root.bridgeReady
        width: parent.width
        spacing: Style.space(8)

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: "Keycast needs a three-line observer in your Hyprland config. It reports currently held keycodes to the shell. The overlay displays them only while it is enabled, and nothing is written to disk."
          color: root.fg
          opacity: 0.78
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Button {
          width: parent.width
          text: service && service.bridgeBusy ? "Working…" : "Enable Hyprland bridge"
          selected: true
          enabled: !!root.service && !root.service.bridgeBusy && root.service.bridgeState !== "review"
          onClicked: if (root.service) root.service.enableBridge()
        }

        Button {
          width: parent.width
          visible: !!root.service && root.service.manualSnippet !== ""
          text: "Copy manual snippet"
          onClicked: Quickshell.execDetached(["bash", "-c", "printf %s " + Util.shellQuote(root.service.manualSnippet) + " | wl-copy"])
        }
      }

      Column {
        visible: root.bridgeReady
        width: parent.width
        spacing: Style.space(10)

        Toggle {
          width: parent.width
          label: "Show pressed keys"
          description: "Corner overlay for screen recordings. Left-click the bar icon to toggle."
          checked: root.overlayOn
          foreground: root.fg
          fontFamily: root.fontFamily
          onClicked: if (root.service) root.service.setOverlayEnabled(!root.overlayOn)
        }

        PanelSeparator { width: parent.width; strength: 0.09 }

        PanelSectionHeader {
          text: "VERTICAL"
          foreground: root.fg
          fontFamily: root.fontFamily
        }
        ButtonGroup {
          width: parent.width
          foreground: root.fg
          fontFamily: root.fontFamily
          value: root.service ? root.service.vertical : "bottom"
          options: [
            { value: "top", label: "Top" },
            { value: "bottom", label: "Bottom" }
          ]
          onChanged: function(value) { if (root.service) root.service.setVertical(value) }
        }

        PanelSectionHeader {
          text: "HORIZONTAL"
          foreground: root.fg
          fontFamily: root.fontFamily
        }
        ButtonGroup {
          width: parent.width
          foreground: root.fg
          fontFamily: root.fontFamily
          value: root.service ? root.service.horizontal : "left"
          options: [
            { value: "left", label: "Left" },
            { value: "right", label: "Right" }
          ]
          onChanged: function(value) { if (root.service) root.service.setHorizontal(value) }
        }

        NumberField {
          width: parent.width
          label: "Corner padding (px)"
          value: root.service ? root.service.padding : 24
          from: 0
          to: 400
          foreground: root.fg
          fontFamily: root.fontFamily
          onModified: function(value) { if (root.service) root.service.setPadding(value) }
        }

        NumberField {
          width: parent.width
          label: "Linger after release (ms)"
          value: root.service ? root.service.lingerMs : 600
          from: 0
          to: 2000
          stepSize: 50
          foreground: root.fg
          fontFamily: root.fontFamily
          onModified: function(value) { if (root.service) root.service.setLingerMs(value) }
        }

        PanelSeparator { width: parent.width; strength: 0.09 }

        Button {
          width: parent.width
          text: service && service.bridgeBusy ? "Working…" : "Remove Hyprland bridge"
          enabled: !!root.service && !root.service.bridgeBusy
          onClicked: if (root.service) root.service.disableBridge()
        }
      }
      }
    }
  }
}
