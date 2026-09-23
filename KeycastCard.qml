import QtQuick
import qs.Commons
import qs.Ui
import "Keys.js" as Keys

Item {
  id: root

  property var labels: []
  property string actionText: ""
  property bool actionVisible: false
  property string actionPlacement: "above"
  property string horizontal: "middle"
  property bool frameOn: false
  property int cornerPx: 8
  property color overlayBg: Color.background
  property color overlayBorder: Color.popups.border
  property color overlayFont: Color.popups.text
  property string typeface: Style.font.family
  property bool useShellColors: true
  property var mouseLabels: []
  property string mousePlacement: "inline"

  readonly property var inlineCaps: {
    if (mousePlacement !== "inline") return labels
    var out = []
    var keys = labels || []
    var extra = mouseLabels || []
    for (var i = 0; i < keys.length; i++) out.push(keys[i])
    for (var j = 0; j < extra.length; j++) out.push(extra[j])
    return out
  }

  component KeycapRow: Item {
    id: capRoot
    property var caps: []
    property string align: "middle"
    property bool framed: false
    property color capBg: "transparent"
    property color capBorder: "white"
    property color capFont: "white"
    property int capRadius: 8
    property string capFamily: ""
    readonly property int count: caps && caps.length ? caps.length : 0
    implicitWidth: capRow.implicitWidth
    implicitHeight: count > 0 ? capRow.implicitHeight : 0
    visible: count > 0
    width: parent ? parent.width : implicitWidth
    height: implicitHeight

    Row {
      id: capRow
      x: Keys.alignX(capRoot.align, implicitWidth, capRoot.width)
      spacing: Style.space(6)

      Repeater {
        model: capRoot.count

        delegate: BorderSurface {
          required property int index
          implicitWidth: Math.max(Style.space(32), capText.implicitWidth + Style.space(14))
          implicitHeight: Style.space(34)
          color: capRoot.framed
            ? Util.alpha(capRoot.capFont, 0.10)
            : Util.alpha(capRoot.capBg, 0.94)
          borderSpec: Border.flat(Util.alpha(capRoot.capBorder, capRoot.framed ? 0.85 : 1), 1)
          radius: capRoot.capRadius

          Text {
            id: capText
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: capRoot.caps && capRoot.caps.length > index ? String(capRoot.caps[index] || "") : ""
            color: capRoot.capFont
            font.family: capRoot.capFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }
        }
      }
    }
  }

  readonly property int actionCap: Style.space(360)
  readonly property int framePadX: frameOn ? Style.space(16) : 0
  readonly property int framePadY: frameOn ? Style.space(12) : 0
  readonly property int actionHAlign: {
    if (horizontal === "right") return Text.AlignRight
    if (horizontal === "middle") return Text.AlignHCenter
    return Text.AlignLeft
  }
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
    width: Math.max(keysRow.implicitWidth, mouseAbove.implicitWidth, mouseBelow.implicitWidth,
      root.actionVisible ? Math.min(root.actionCap, actionMetrics.implicitWidth) : 0)
    spacing: Style.space(6)

    Text {
      id: actionMetrics
      visible: false
      text: root.actionText
      font.family: root.typeface
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
      font.family: root.typeface
      font.pixelSize: Style.font.body
    }

    KeycapRow {
      id: mouseAbove
      width: parent.width
      caps: root.mousePlacement === "above" ? root.mouseLabels : []
      align: root.horizontal
      framed: root.frameOn
      capBg: root.overlayBg
      capBorder: root.overlayBorder
      capFont: root.overlayFont
      capRadius: root.cornerPx
      capFamily: root.typeface
    }

    KeycapRow {
      id: keysRow
      width: parent.width
      caps: root.mousePlacement === "inline" ? root.inlineCaps : root.labels
      align: root.horizontal
      framed: root.frameOn
      capBg: root.overlayBg
      capBorder: root.overlayBorder
      capFont: root.overlayFont
      capRadius: root.cornerPx
      capFamily: root.typeface
    }

    KeycapRow {
      id: mouseBelow
      width: parent.width
      caps: root.mousePlacement === "below" ? root.mouseLabels : []
      align: root.horizontal
      framed: root.frameOn
      capBg: root.overlayBg
      capBorder: root.overlayBorder
      capFont: root.overlayFont
      capRadius: root.cornerPx
      capFamily: root.typeface
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
      font.family: root.typeface
      font.pixelSize: Style.font.body
    }
  }
}
