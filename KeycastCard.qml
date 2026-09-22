import QtQuick
import qs.Commons
import qs.Ui
import "Keys.js" as Keys

Item {
  id: root

  property var labels: []
  property string actionText: ""
  property bool actionVisible: false
  property string actionPlacement: "below"
  property string horizontal: "left"
  property bool frameOn: true
  property int cornerPx: 8
  property color overlayBg: Color.background
  property color overlayBorder: Color.popups.border
  property color overlayFont: Color.popups.text
  property bool useShellColors: true

  readonly property int actionCap: Style.space(360)
  readonly property int framePadX: frameOn ? Style.space(16) : 0
  readonly property int framePadY: frameOn ? Style.space(12) : 0
  readonly property int actionHAlign: {
    if (horizontal === "right") return Text.AlignRight
    if (horizontal === "middle") return Text.AlignHCenter
    return Text.AlignLeft
  }
  readonly property int labelCount: labels && labels.length ? labels.length : 0

  width: Math.max(1, stack.implicitWidth + framePadX)
  height: Math.max(1, stack.implicitHeight + framePadY)

  BorderSurface {
    anchors.fill: parent
    visible: root.frameOn
    color: Util.alpha(root.overlayBg, 0.94)
    borderSpec: root.useShellColors
      ? Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
      : Border.flat(root.overlayBorder, Math.max(1, Style.space(2)))
    radius: root.cornerPx
  }

  Column {
    id: stack
    anchors.centerIn: parent
    width: Math.max(keysRow.implicitWidth, root.actionVisible
      ? Math.min(root.actionCap, actionMetrics.implicitWidth) : 0)
    spacing: root.actionVisible ? Style.space(6) : 0

    Text {
      id: actionMetrics
      visible: false
      text: root.actionText
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }

    Text {
      visible: root.actionVisible && root.actionPlacement === "above"
      width: parent.width
      horizontalAlignment: root.actionHAlign
      textFormat: Text.PlainText
      wrapMode: Text.NoWrap
      elide: Text.ElideRight
      text: root.actionText
      color: root.overlayFont
      opacity: 0.88
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }

    Item {
      width: parent.width
      height: keysRow.implicitHeight

      Row {
        id: keysRow
        x: Keys.alignX(root.horizontal, implicitWidth, parent.width)
        spacing: Style.space(6)

        Repeater {
          model: root.labelCount

          delegate: BorderSurface {
            required property int index

            implicitWidth: Math.max(Style.space(32), keyLabel.implicitWidth + Style.space(14))
            implicitHeight: Style.space(34)
            color: root.frameOn
              ? Util.alpha(root.overlayFont, 0.10)
              : Util.alpha(root.overlayBg, 0.94)
            borderSpec: Border.flat(Util.alpha(root.overlayBorder, root.frameOn ? 0.85 : 1), 1)
            radius: root.cornerPx

            Text {
              id: keyLabel
              anchors.centerIn: parent
              textFormat: Text.PlainText
              text: root.labels && root.labels.length > index ? String(root.labels[index] || "") : ""
              color: root.overlayFont
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              font.bold: true
            }
          }
        }
      }
    }

    Text {
      visible: root.actionVisible && root.actionPlacement === "below"
      width: parent.width
      horizontalAlignment: root.actionHAlign
      textFormat: Text.PlainText
      wrapMode: Text.NoWrap
      elide: Text.ElideRight
      text: root.actionText
      color: root.overlayFont
      opacity: 0.88
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }
  }
}
