import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  property var service: null

  readonly property bool overlayOn: service ? service.overlayEnabled === true : false
  readonly property var labels: service && Array.isArray(service.displayedKeys) ? service.displayedKeys : []
  readonly property bool showing: overlayOn && labels.length > 0
  readonly property string vertical: service ? String(service.vertical || "bottom") : "bottom"
  readonly property string horizontal: service ? String(service.horizontal || "left") : "left"
  readonly property int pad: service ? Math.max(0, Number(service.padding || 0)) : 24

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

        BorderSurface {
          id: card
          visible: root.showing
          anchors.left: root.horizontal === "left" ? parent.left : undefined
          anchors.right: root.horizontal === "right" ? parent.right : undefined
          anchors.top: root.vertical === "top" ? parent.top : undefined
          anchors.bottom: root.vertical === "bottom" ? parent.bottom : undefined
          anchors.leftMargin: root.pad
          anchors.rightMargin: root.pad
          anchors.topMargin: root.pad
          anchors.bottomMargin: root.pad
          implicitWidth: keysRow.implicitWidth + Style.space(16)
          implicitHeight: keysRow.implicitHeight + Style.space(12)
          color: Util.alpha(Color.background, 0.94)
          borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
          radius: Style.cornerRadius
          opacity: root.showing ? 1 : 0

          Behavior on opacity {
            NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
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
                color: Util.alpha(Color.popups.text, 0.10)
                borderSpec: Border.flat(Util.alpha(Color.popups.text, 0.22), 1)
                radius: Math.max(4, Style.cornerRadius - 2)

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
