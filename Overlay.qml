import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Keys.js" as Keys

Item {
  id: root

  property var service: null

  readonly property bool overlayOn: service ? service.overlayEnabled === true : false
  readonly property bool frameOn: service ? service.frameEnabled !== false : true
  readonly property var labels: service && Array.isArray(service.displayedKeys) ? service.displayedKeys : []
  readonly property bool showing: overlayOn && labels.length > 0
  readonly property string vertical: service ? String(service.vertical || "bottom") : "bottom"
  readonly property string horizontal: service ? String(service.horizontal || "left") : "left"
  readonly property int pad: service ? Math.max(0, Number(service.padding || 0)) : 24
  readonly property real overlayScale: service ? Number(service.scaleFactor || 1) : 1
  readonly property int cornerPx: service
    ? Keys.overlayRadius(service.roundingEnabled, service.rounding) : 8
  readonly property int framePadX: frameOn ? Style.space(16) : 0
  readonly property int framePadY: frameOn ? Style.space(12) : 0

  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: overlayWindow
        required property var modelData

        screen: modelData
        visible: root.showing
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }

        WlrLayershell.namespace: "omarchy-keycast"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}

        Item {
          id: card
          visible: root.showing
          width: Math.max(1, keysRow.implicitWidth + root.framePadX)
          height: Math.max(1, keysRow.implicitHeight + root.framePadY)
          x: Keys.overlayX(root.horizontal, width, parent.width, root.pad)
          y: Keys.overlayY(root.vertical, height, parent.height, root.pad)
          scale: root.overlayScale
          transformOrigin: {
            if (root.vertical === "top") {
              if (root.horizontal === "right") return Item.TopRight
              if (root.horizontal === "middle") return Item.Top
              return Item.TopLeft
            }
            if (root.vertical === "bottom") {
              if (root.horizontal === "right") return Item.BottomRight
              if (root.horizontal === "middle") return Item.Bottom
              return Item.BottomLeft
            }
            if (root.horizontal === "right") return Item.Right
            if (root.horizontal === "left") return Item.Left
            return Item.Center
          }
          opacity: root.showing ? 1 : 0

          Behavior on opacity {
            NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
          }

          BorderSurface {
            anchors.fill: parent
            visible: root.frameOn
            color: Util.alpha(Color.background, 0.94)
            borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
            radius: root.cornerPx
          }

          Row {
            id: keysRow
            anchors.centerIn: parent
            spacing: Style.space(6)

            Repeater {
              model: root.labels

              delegate: BorderSurface {
                id: keyCap
                required property var modelData

                implicitWidth: Math.max(Style.space(32), keyLabel.implicitWidth + Style.space(14))
                implicitHeight: Style.space(34)
                color: root.frameOn
                  ? Util.alpha(Color.popups.text, 0.10)
                  : Util.alpha(Color.background, 0.94)
                borderSpec: Border.flat(Util.alpha(Color.popups.text, root.frameOn ? 0.22 : 0.35), 1)
                radius: root.cornerPx

                Text {
                  id: keyLabel
                  anchors.centerIn: parent
                  textFormat: Text.PlainText
                  text: String(keyCap.modelData || "")
                  color: Color.popups.text
                  font.family: Style.font.family
                  font.pixelSize: Style.font.title
                  font.bold: true
                }
              }
            }
          }
        }
      }
    }
  }
}
