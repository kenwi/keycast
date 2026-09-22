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
  property string settingsPage: "overlay"

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
    if (scroll) scroll.contentY = 0
    controller.show()
  }

  function close() { controller.hide() }
  function toggle() { if (opened) close(); else open() }
  function closeForPopoutSwitch() { close() }

  onBarChanged: syncService()
  onSettingsPageChanged: if (scroll) scroll.contentY = 0
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
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight,
      panel.availableCardHeight > 0 ? panel.availableCardHeight : Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: themeDropdown.popupOpen || bgHex.activeFocus || borderHex.activeFocus || fontHex.activeFocus
      onCloseRequested: root.close()

      Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height

        Column {
          id: contentColumn
          width: scroll.width
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

            ButtonGroup {
              width: parent.width
              foreground: root.fg
              fontFamily: root.fontFamily
              value: root.settingsPage
              options: [
                { value: "overlay", label: "Overlay" },
                { value: "position", label: "Position" },
                { value: "colors", label: "Colors" }
              ]
              onChanged: function(value) { root.settingsPage = value }
            }

            Column {
              visible: root.settingsPage === "overlay"
              width: parent.width
              spacing: Style.space(10)

              Toggle {
                width: parent.width
                label: "Show pressed keys"
                description: "Left-click the bar icon or Super+Shift+K to toggle."
                checked: root.overlayOn
                foreground: root.fg
                fontFamily: root.fontFamily
                onClicked: if (root.service) root.service.setOverlayEnabled(!root.overlayOn)
              }

              Toggle {
                width: parent.width
                label: "Outer box"
                description: "Background and border around the keycaps."
                checked: root.service ? root.service.frameEnabled !== false : true
                foreground: root.fg
                fontFamily: root.fontFamily
                onClicked: if (root.service) root.service.setFrameEnabled(!(root.service.frameEnabled !== false))
              }

              Toggle {
                width: parent.width
                label: "Rounded corners"
                description: "Round the outer box and keycaps."
                checked: root.service ? root.service.roundingEnabled !== false : true
                foreground: root.fg
                fontFamily: root.fontFamily
                onClicked: if (root.service) root.service.setRoundingEnabled(!(root.service.roundingEnabled !== false))
              }

              NumberField {
                width: parent.width
                label: "Corner radius (px)"
                value: root.service ? root.service.rounding : 8
                from: 0
                to: 32
                foreground: root.fg
                fontFamily: root.fontFamily
                onModified: function(value) { if (root.service) root.service.setRounding(value) }
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

              Toggle {
                width: parent.width
                label: "Show shortcut action"
                description: "Hyprland bind description, same source as Super+K."
                checked: root.service ? root.service.actionEnabled !== false : true
                foreground: root.fg
                fontFamily: root.fontFamily
                onClicked: if (root.service) root.service.setActionEnabled(!(root.service.actionEnabled !== false))
              }

              PanelSectionHeader {
                text: "ACTION PLACEMENT"
                foreground: root.fg
                fontFamily: root.fontFamily
              }
              ButtonGroup {
                width: parent.width
                foreground: root.fg
                fontFamily: root.fontFamily
                value: root.service ? root.service.actionPosition : "below"
                options: [
                  { value: "above", label: "Above" },
                  { value: "below", label: "Below" }
                ]
                onChanged: function(value) { if (root.service) root.service.setActionPosition(value) }
              }

              PanelSeparator { width: parent.width; strength: 0.09 }

              Button {
                width: parent.width
                text: service && service.bridgeBusy ? "Working…" : "Remove Hyprland bridge"
                enabled: !!root.service && !root.service.bridgeBusy
                onClicked: if (root.service) root.service.disableBridge()
              }
            }

            Column {
              visible: root.settingsPage === "position"
              width: parent.width
              spacing: Style.space(10)

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
                  { value: "middle", label: "Middle" },
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
                  { value: "middle", label: "Middle" },
                  { value: "right", label: "Right" }
                ]
                onChanged: function(value) { if (root.service) root.service.setHorizontal(value) }
              }

              NumberField {
                width: parent.width
                label: "Edge padding (px)"
                value: root.service ? root.service.padding : 24
                from: 0
                to: 400
                foreground: root.fg
                fontFamily: root.fontFamily
                onModified: function(value) { if (root.service) root.service.setPadding(value) }
              }

              PanelSectionHeader {
                text: "SCALE"
                foreground: root.fg
                fontFamily: root.fontFamily
              }
              ButtonGroup {
                width: parent.width
                foreground: root.fg
                fontFamily: root.fontFamily
                value: root.service ? String(root.service.scaleFactor) : "1"
                options: [
                  { value: "1", label: "1x" },
                  { value: "1.25", label: "1.25x" },
                  { value: "1.5", label: "1.5x" },
                  { value: "1.75", label: "1.75x" },
                  { value: "2", label: "2x" }
                ]
                onChanged: function(value) { if (root.service) root.service.setScale(value) }
              }
            }

            Column {
              visible: root.settingsPage === "colors"
              width: parent.width
              spacing: Style.space(10)

              Dropdown {
                id: themeDropdown
                width: parent.width
                label: "Theme"
                foreground: root.fg
                fontFamily: root.fontFamily
                value: root.service ? root.service.colorTheme : "shell"
                options: [
                  { value: "shell", label: "Shell" },
                  { value: "dark", label: "Dark" },
                  { value: "light", label: "Light" },
                  { value: "contrast", label: "Contrast" },
                  { value: "nord", label: "Nord" },
                  { value: "mocha", label: "Mocha" },
                  { value: "gold", label: "Gold" },
                  { value: "custom", label: "Custom" }
                ]
                onChanged: function(value) { if (root.service) root.service.setColorTheme(value) }
              }
              Text {
                width: parent.width
                textFormat: Text.PlainText
                text: "Shell follows the Omarchy theme. Presets fill the hex fields. Editing a hex switches to Custom."
                color: root.fg
                opacity: 0.78
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }

              Column {
                width: parent.width
                spacing: Style.space(4)

                Text {
                  textFormat: Text.PlainText
                  text: "Background"
                  color: Qt.darker(root.fg, 1.4)
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                }
                Row {
                  width: parent.width
                  spacing: Style.space(8)
                  Rectangle {
                    width: Style.space(28)
                    height: Style.space(28)
                    radius: Style.cornerRadius
                    color: Style.colorFromHex(root.service ? root.service.backgroundColor : "#1A1A1A", Color.background)
                    border.color: root.fg
                    border.width: 1
                  }
                  TextField {
                    id: bgHex
                    width: parent.width - Style.space(36)
                    foreground: root.fg
                    font.family: root.fontFamily
                    onEditingFinished: if (root.service) root.service.setBackgroundColor(text)
                    onAccepted: if (root.service) root.service.setBackgroundColor(text)
                  }
                  Binding {
                    target: bgHex
                    property: "text"
                    value: root.service ? root.service.backgroundColor : "#1A1A1A"
                    when: !bgHex.activeFocus
                  }
                }
              }

              Column {
                width: parent.width
                spacing: Style.space(4)

                Text {
                  textFormat: Text.PlainText
                  text: "Border"
                  color: Qt.darker(root.fg, 1.4)
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                }
                Row {
                  width: parent.width
                  spacing: Style.space(8)
                  Rectangle {
                    width: Style.space(28)
                    height: Style.space(28)
                    radius: Style.cornerRadius
                    color: Style.colorFromHex(root.service ? root.service.borderColor : "#6E6E6E", Color.popups.border)
                    border.color: root.fg
                    border.width: 1
                  }
                  TextField {
                    id: borderHex
                    width: parent.width - Style.space(36)
                    foreground: root.fg
                    font.family: root.fontFamily
                    onEditingFinished: if (root.service) root.service.setBorderColor(text)
                    onAccepted: if (root.service) root.service.setBorderColor(text)
                  }
                  Binding {
                    target: borderHex
                    property: "text"
                    value: root.service ? root.service.borderColor : "#6E6E6E"
                    when: !borderHex.activeFocus
                  }
                }
              }

              Column {
                width: parent.width
                spacing: Style.space(4)

                Text {
                  textFormat: Text.PlainText
                  text: "Font"
                  color: Qt.darker(root.fg, 1.4)
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                }
                Row {
                  width: parent.width
                  spacing: Style.space(8)
                  Rectangle {
                    width: Style.space(28)
                    height: Style.space(28)
                    radius: Style.cornerRadius
                    color: Style.colorFromHex(root.service ? root.service.fontColor : "#F5F5F5", Color.popups.text)
                    border.color: root.fg
                    border.width: 1
                  }
                  TextField {
                    id: fontHex
                    width: parent.width - Style.space(36)
                    foreground: root.fg
                    font.family: root.fontFamily
                    onEditingFinished: if (root.service) root.service.setFontColor(text)
                    onAccepted: if (root.service) root.service.setFontColor(text)
                  }
                  Binding {
                    target: fontHex
                    property: "text"
                    value: root.service ? root.service.fontColor : "#F5F5F5"
                    when: !fontHex.activeFocus
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
