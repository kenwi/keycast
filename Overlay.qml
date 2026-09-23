import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Keys.js" as Keys

Item {
  id: root

  property Item service: null

  readonly property bool overlayOn: service ? service.overlayEnabled === true : false
  readonly property bool previewOn: service ? service.previewActive === true : false
  readonly property bool frameOn: service ? service.frameEnabled === true : false
  readonly property int previewEpoch: service ? Number(service.previewEpoch || 0) : 0
  readonly property var labels: {
    var _epoch = root.previewEpoch
    if (!service) return []
    return Keys.overlayLabels(service.displayedKeys, service.previewActive, service.previewKeys)
  }
  readonly property var mouseLabels: service ? service.displayedMouseLabels : []
  readonly property string mousePlacement: service ? String(service.mousePlacement || "inline") : "inline"
  readonly property bool cardOn: (labels.length > 0 || mouseLabels.length > 0) && (overlayOn || previewOn)
  readonly property bool rippleOn: service && service.pointerRipples && service.pointerRipples.length > 0
  readonly property bool showing: cardOn || rippleOn
  readonly property string vertical: service ? String(service.vertical || "bottom") : "bottom"
  readonly property string horizontal: service ? String(service.horizontal || "middle") : "middle"
  readonly property int pad: service ? Math.max(0, Number(service.padding || 0)) : 24
  readonly property real overlayScale: service ? Number(service.scaleFactor || 1) : 1
  readonly property int cornerPx: service
    ? Keys.overlayRadius(service.roundingEnabled, service.rounding) : 8
  readonly property bool actionOn: service ? service.actionEnabled !== false : true
  readonly property string actionPlacement: service ? String(service.actionPosition || "above") : "above"
  readonly property string actionText: service ? String(service.displayedAction || "") : ""
  readonly property bool actionVisible: actionOn && actionText !== ""
  readonly property bool useShellColors: service ? service.useShellColors === true : true
  readonly property color overlayBg: service ? service.overlayBackground : Color.background
  readonly property color overlayBorder: service ? service.overlayBorderTone : Color.popups.border
  readonly property color overlayFont: service ? service.overlayFontTone : Color.popups.text
  readonly property string typeface: service ? String(service.overlayTypeface || Style.font.family) : Style.font.family
  readonly property int colorEpoch: service ? Number(service.colorEpoch || 0) : 0

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

        Repeater {
          model: root.service ? root.service.pointerRipples : []

          delegate: Rectangle {
            required property var modelData
            readonly property real sx: overlayWindow.screen ? Number(overlayWindow.screen.x) || 0 : 0
            readonly property real sy: overlayWindow.screen ? Number(overlayWindow.screen.y) || 0 : 0
            readonly property real sw: overlayWindow.screen ? Number(overlayWindow.screen.width) || 0 : 0
            readonly property real sh: overlayWindow.screen ? Number(overlayWindow.screen.height) || 0 : 0
            readonly property int diameter: root.service ? root.service.mouseRippleSize : 36
            visible: modelData.x >= sx && modelData.x <= sx + sw && modelData.y >= sy && modelData.y <= sy + sh
            x: modelData.x - sx - diameter / 2
            y: modelData.y - sy - diameter / 2
            width: diameter
            height: diameter
            radius: diameter / 2
            color: "transparent"
            border.width: 2
            border.color: root.overlayBorder
            opacity: {
              var _tick = root.service ? root.service.rippleTick : 0
              if (!root.service || root.service.mouseRippleFade !== true || modelData.held === true)
                return 0.9
              var life = Math.max(100, Number(root.service.mouseRippleMs) || 400)
              var age = Date.now() - Number(modelData.born || 0)
              return 0.9 * Math.max(0, 1 - age / life)
            }
          }
        }

        KeycastCard {
          id: card
          visible: root.cardOn
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
          labels: root.labels
          mouseLabels: root.mouseLabels
          mousePlacement: root.mousePlacement
          actionText: root.actionText
          actionVisible: root.actionVisible
          actionPlacement: root.actionPlacement
          horizontal: root.horizontal
          frameOn: root.frameOn
          cornerPx: root.cornerPx
          overlayBg: {
            var _tick = root.colorEpoch
            return root.overlayBg
          }
          overlayBorder: {
            var _tick = root.colorEpoch
            return root.overlayBorder
          }
          overlayFont: {
            var _tick = root.colorEpoch
            return root.overlayFont
          }
          typeface: root.typeface
          useShellColors: {
            var _tick = root.colorEpoch
            return root.useShellColors
          }

          Behavior on opacity {
            NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
          }
        }
      }
    }
  }
}
