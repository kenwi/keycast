import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "Keys.js" as Keys

Item {
  id: form

  property var host: null
  property bool wide: false
  property bool fullscreen: false

  property alias formScroll: scroll
  readonly property int formHeight: contentColumn.implicitHeight
  readonly property bool fieldBusy: fontDropdown.popupOpen || bgHex.activeFocus || borderHex.activeFocus || fontHex.activeFocus || scaleField.field.activeFocus

  function colWidth(columns) {
    var cols = wide ? Math.max(1, columns) : 1
    var gap = Style.space(16)
    var span = Math.max(0, width)
    if (cols <= 1) return span
    return Math.max(1, Math.floor((span - gap * (cols - 1)) / cols))
  }

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
        color: host.fg
        font.family: host.fontFamily
        font.pixelSize: Style.font.title
        font.bold: true
      }
      Text {
        width: parent.width
        textFormat: Text.PlainText
        text: host.bridgeSummary
        color: host.fg
        opacity: 0.78
        font.family: host.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }
    }

    ButtonGroup {
      width: parent.width
      foreground: host.fg
      fontFamily: host.fontFamily
      value: host ? host.settingsLayout : "side"
      options: [
        { value: "side", label: "Side" },
        { value: "center", label: "Center" },
        { value: "fullscreen", label: "Fullscreen" }
      ]
      onChanged: function(value) { if (host && host.service) host.service.setSettingsLayout(value) }
    }

    Column {
      visible: !host.bridgeReady
      width: parent.width
      spacing: Style.space(8)

      Text {
        width: parent.width
        textFormat: Text.PlainText
        text: "Keycast needs a three-line observer in your Hyprland config. It reports currently held keycodes to the shell. The overlay displays them only while it is enabled, and nothing is written to disk."
        color: host.fg
        opacity: 0.78
        font.family: host.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }

      Button {
        width: parent.width
        text: host.service && host.service.bridgeBusy ? "Working…" : "Enable Hyprland bridge"
        selected: true
        enabled: !!host.service && !host.service.bridgeBusy && host.service.bridgeState !== "review"
        onClicked: if (host.service) host.service.enableBridge()
      }

      Button {
        width: parent.width
        visible: !!host.service && host.service.manualSnippet !== ""
        text: "Copy manual snippet"
        onClicked: Quickshell.execDetached(["bash", "-c", "printf %s " + Util.shellQuote(host.service.manualSnippet) + " | wl-copy"])
      }
    }

    Column {
      visible: host.bridgeReady
      width: parent.width
      spacing: Style.space(10)

      Flow {
        width: parent.width
        spacing: Style.spacing.md

        Repeater {
          model: [
            { value: "overlay", label: "Overlay" },
            { value: "position", label: "Position" },
            { value: "colors", label: "Colors" },
            { value: "mouse", label: "Mouse" },
            { value: "ignore", label: "Ignore" }
          ]

          delegate: Button {
            required property var modelData
            text: modelData.label
            selected: host.settingsPage === modelData.value
            bordered: true
            foreground: host.fg
            fontFamily: host.fontFamily
            onClicked: host.settingsPage = modelData.value
          }
        }
      }

      Flow {
      visible: host.settingsPage === "overlay"
      width: parent.width
      spacing: Style.space(16)

      Column {
        width: form.colWidth(2)
        spacing: Style.space(10)

        Toggle {
          width: parent.width
          label: "Show pressed keys"
          description: "Left-click the bar icon or Super+Shift+K to toggle. Super+Shift+L opens settings."
          checked: host.overlayOn
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setOverlayEnabled(!host.overlayOn)
        }

        Toggle {
          width: parent.width
          label: "Show typed characters"
          description: "! instead of Shift+1, using this keyboard's layout. Super, Ctrl, and left Alt stay as key names."
          checked: host.service ? host.service.showTyped === true : false
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setShowTyped(!(host.service.showTyped === true))
        }

        Toggle {
          width: parent.width
          label: "Always show uppercase"
          description: "With typed characters on, letters show as A instead of a. Symbols such as ! stay as typed."
          checked: host.service ? host.service.showUppercase === true : false
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setShowUppercase(!(host.service.showUppercase === true))
        }

        Toggle {
          width: parent.width
          label: "Show while recording"
          description: "Turn the overlay on with Omarchy's screen recorder, and off again when that take ends."
          checked: host.service ? host.service.showWhileRecording === true : false
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setShowWhileRecording(!(host.service.showWhileRecording === true))
        }

        Toggle {
          width: parent.width
          label: "Preview keypress"
          description: "Show a sample hotkey on the overlay while this panel is open."
          checked: host.previewSettingOn
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: {
            if (!host.service) return
            host.service.setPreviewEnabled(!host.previewSettingOn)
            host.syncPreview()
          }
        }

        Toggle {
          width: parent.width
          label: "Outer box"
          description: "Background and border around the keycaps."
          checked: host.service ? host.service.frameEnabled === true : false
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setFrameEnabled(!(host.service.frameEnabled === true))
        }

        }

      Column {
        width: form.colWidth(2)
        spacing: Style.space(10)

        Toggle {
          width: parent.width
          label: "Rounded corners"
          description: "Round the outer box and keycaps."
          checked: host.service ? host.service.roundingEnabled !== false : true
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setRoundingEnabled(!(host.service.roundingEnabled !== false))
        }

        NumberField {
          width: parent.width
          label: "Corner radius (px)"
          value: host.service ? host.service.rounding : 8
          from: 0
          to: 32
          foreground: host.fg
          fontFamily: host.fontFamily
          onModified: function(value) { if (host.service) host.service.setRounding(value) }
        }

        FontDropdown {
          id: fontDropdown
          width: parent.width
          label: "Font"
          placeholderText: "Search fonts"
          emptyText: "No matching fonts"
          foreground: host.fg
          fontFamily: host.fontFamily
          value: host.service ? host.service.fontFamily : "shell"
          options: host.fontChoices
          onChanged: function(value) { if (host.service) host.service.setFontFamily(value) }
        }
        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: "Shell uses the Omarchy UI font. Other entries are fonts installed on this system."
          color: host.fg
          opacity: 0.78
          font.family: host.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        NumberField {
          width: parent.width
          label: "Linger after release (ms)"
          value: host.service ? host.service.lingerMs : 600
          from: 0
          to: 2000
          stepSize: 50
          foreground: host.fg
          fontFamily: host.fontFamily
          onModified: function(value) { if (host.service) host.service.setLingerMs(value) }
        }

        Toggle {
          width: parent.width
          label: "Show shortcut action"
          description: "Hyprland bind description, same source as Super+K."
          checked: host.service ? host.service.actionEnabled !== false : true
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setActionEnabled(!(host.service.actionEnabled !== false))
        }

        PanelSectionHeader {
          text: "ACTION PLACEMENT"
          foreground: host.fg
          fontFamily: host.fontFamily
        }
        ButtonGroup {
          width: parent.width
          foreground: host.fg
          fontFamily: host.fontFamily
          value: host.service ? host.service.actionPosition : "above"
          options: [
            { value: "above", label: "Above" },
            { value: "below", label: "Below" }
          ]
          onChanged: function(value) { if (host.service) host.service.setActionPosition(value) }
        }

        PanelSeparator { width: parent.width; strength: 0.09 }

        Button {
          width: parent.width
          text: host.service && host.service.bridgeBusy ? "Working…" : "Remove Hyprland bridge"
          enabled: !!host.service && !host.service.bridgeBusy
          onClicked: if (host.service) host.service.disableBridge()
        }
      }
    }

    Column {
      visible: host.settingsPage === "position"
      width: parent.width
      spacing: Style.space(16)

      Flow {
        width: parent.width
        spacing: Style.space(16)

      Column {
        id: monitorColumn
        width: form.wide ? implicitWidth : parent.width
        spacing: Style.space(10)

        PanelSectionHeader {
          text: "MONITOR"
          foreground: host.fg
          fontFamily: host.fontFamily
        }
        ButtonGroup {
          id: monitorModes
          width: form.wide ? implicitWidth : parent.width
          foreground: host.fg
          fontFamily: host.fontFamily
          value: host.service ? host.service.overlayMonitor : "all"
          options: [
            { value: "all", label: "All" },
            { value: "focused", label: "Focused" },
            { value: "specific", label: "Specific" }
          ]
          onChanged: function(value) { if (host.service) host.service.setOverlayMonitor(value) }
        }
        Text {
          width: form.wide ? monitorModes.implicitWidth : parent.width
          textFormat: Text.PlainText
          text: {
            var mode = host.service ? String(host.service.overlayMonitor || "all") : "all"
            if (mode === "focused") return "Only the monitor Hyprland has focused."
            if (mode === "specific") return "Only the monitor you pick. That choice stays if the display is unplugged."
            return "Every connected monitor."
          }
          color: host.fg
          opacity: 0.78
          font.family: host.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }
        Text {
          width: form.wide ? monitorModes.implicitWidth : parent.width
          textFormat: Text.PlainText
          text: {
            var live = Keys.monitorOptions(host.service ? host.service.monitorChoices : [], "")
            if (live.length === 0) return "No monitors detected yet."
            var names = []
            for (var i = 0; i < live.length; i++) names.push(live[i].name)
            return "Connected: " + names.join(", ")
          }
          color: host.fg
          opacity: 0.78
          font.family: host.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }
        Flow {
          width: form.wide ? monitorModes.implicitWidth : parent.width
          spacing: Style.spacing.md
          visible: host.service && host.service.overlayMonitor === "specific"

          Repeater {
            model: Keys.monitorOptions(
              host.service ? host.service.monitorChoices : [],
              host.service ? host.service.overlayMonitorName : "")

            Button {
              required property var modelData
              text: modelData.label
              selected: host.service && host.service.overlayMonitorName === String(modelData.name)
              bordered: true
              foreground: host.fg
              fontFamily: host.fontFamily
              onClicked: if (host.service) host.service.setOverlayMonitorName(modelData.name)
            }
          }
        }

      }

      Column {
        id: verticalColumn
        width: form.wide ? implicitWidth : parent.width
        spacing: Style.space(10)

        PanelSectionHeader {
          text: "VERTICAL"
          foreground: host.fg
          fontFamily: host.fontFamily
        }
        ButtonGroup {
          width: form.wide ? implicitWidth : parent.width
          foreground: host.fg
          fontFamily: host.fontFamily
          value: host.service ? host.service.vertical : "bottom"
          options: [
            { value: "top", label: "Top" },
            { value: "middle", label: "Middle" },
            { value: "bottom", label: "Bottom" }
          ]
          onChanged: function(value) { if (host.service) host.service.setVertical(value) }
        }
      }

      Column {
        id: horizontalColumn
        width: form.wide ? implicitWidth : parent.width
        spacing: Style.space(10)

        PanelSectionHeader {
          text: "HORIZONTAL"
          foreground: host.fg
          fontFamily: host.fontFamily
        }
        ButtonGroup {
          width: form.wide ? implicitWidth : parent.width
          foreground: host.fg
          fontFamily: host.fontFamily
          value: host.service ? host.service.horizontal : "middle"
          options: [
            { value: "left", label: "Left" },
            { value: "middle", label: "Middle" },
            { value: "right", label: "Right" }
          ]
          onChanged: function(value) { if (host.service) host.service.setHorizontal(value) }
        }
      }

      Column {
        id: paddingColumn
        width: form.wide ? implicitWidth : parent.width
        spacing: Style.space(10)

        PanelSectionHeader {
          text: "EDGE PADDING"
          foreground: host.fg
          fontFamily: host.fontFamily
        }
        NumberField {
          width: form.wide ? implicitWidth : parent.width
          label: ""
          value: host.service ? host.service.padding : 24
          from: 0
          to: 400
          foreground: host.fg
          fontFamily: host.fontFamily
          onModified: function(value) { if (host.service) host.service.setPadding(value) }
        }
      }
      }

      Column {
        width: parent.width
        spacing: Style.space(10)

        PanelSectionHeader {
          text: "SCALE"
          foreground: host.fg
          fontFamily: host.fontFamily
        }
        ButtonGroup {
          width: parent.width
          foreground: host.fg
          fontFamily: host.fontFamily
          value: host.service ? host.service.scaleChoice : "1"
          options: [
            { value: "1", label: "1x" },
            { value: "1.25", label: "1.25x" },
            { value: "1.5", label: "1.5x" },
            { value: "1.75", label: "1.75x" },
            { value: "2", label: "2x" },
            { value: "custom", label: "Custom" }
          ]
          onChanged: function(value) { if (host.service) host.service.setScale(value) }
        }
        ScaleField {
          id: scaleField
          width: parent.width
          visible: host.service && host.service.scaleCustom === true
          label: "Custom scale"
          value: host.service ? host.service.scaleFactor : 1
          from: 0.5
          to: 5
          foreground: host.fg
          fontFamily: host.fontFamily
          onModified: function(value) { if (host.service) host.service.setCustomScale(value) }
        }
      }
    }

    Flow {
      visible: host.settingsPage === "mouse"
      width: parent.width
      spacing: Style.space(16)

      Column {
        width: form.colWidth(4)
        spacing: Style.space(10)

        Item {
          width: parent.width
          height: form.wide ? mouseColumnHeader.implicitHeight : 0
          PanelSectionHeader {
            id: mouseColumnHeader
            text: "BUTTONS"
            opacity: 0
            foreground: host.fg
            fontFamily: host.fontFamily
          }
        }

        Toggle {
          width: parent.width
          label: "Show mouse"
          description: "Clicks and scroll stay on screen with the keys. They still reach the window."
          checked: host.service ? host.service.mouseEnabled !== false : true
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setMouseFlag("mouseEnabled", !(host.service.mouseEnabled !== false))
        }

        PanelSectionHeader {
          text: "PLACEMENT"
          foreground: host.fg
          fontFamily: host.fontFamily
        }
        ButtonGroup {
          width: parent.width
          foreground: host.fg
          fontFamily: host.fontFamily
          value: host.service ? host.service.mousePlacement : "inline"
          options: [
            { value: "inline", label: "Inline" },
            { value: "above", label: "Above" },
            { value: "below", label: "Below" }
          ]
          onChanged: function(value) { if (host.service) host.service.setMousePlacement(value) }
        }

        PanelSectionHeader {
          text: "LABELS"
          foreground: host.fg
          fontFamily: host.fontFamily
        }
        ButtonGroup {
          width: parent.width
          foreground: host.fg
          fontFamily: host.fontFamily
          value: host.service ? host.service.mouseLabelStyle : "short"
          options: [
            { value: "short", label: "Short" },
            { value: "name", label: "Name" }
          ]
          onChanged: function(value) { if (host.service) host.service.setMouseLabelStyle(value) }
        }

        Toggle {
          width: parent.width
          label: "Only with keys"
          description: "Hide mouse labels unless a keyboard chord is on screen."
          checked: host.service ? host.service.mouseRequireKeys === true : false
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setMouseFlag("mouseRequireKeys", !(host.service.mouseRequireKeys === true))
        }

        NumberField {
          width: parent.width
          label: "Mouse linger (ms)"
          value: host.service ? host.service.mouseLingerMs : 500
          from: 0
          to: 2000
          stepSize: 50
          foreground: host.fg
          fontFamily: host.fontFamily
          onModified: function(value) { if (host.service) host.service.setMouseLingerMs(value) }
        }

      }

      Column {
        width: form.colWidth(4)
        spacing: Style.space(10)

        PanelSectionHeader {
          text: "BUTTONS"
          foreground: host.fg
          fontFamily: host.fontFamily
        }
        Toggle {
          width: parent.width
          label: "Left"
          checked: host.service ? host.service.mouseLeft !== false : true
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setMouseFlag("mouseLeft", !(host.service.mouseLeft !== false))
        }
        Toggle {
          width: parent.width
          label: "Right"
          checked: host.service ? host.service.mouseRight !== false : true
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setMouseFlag("mouseRight", !(host.service.mouseRight !== false))
        }
        Toggle {
          width: parent.width
          label: "Middle"
          checked: host.service ? host.service.mouseMiddle !== false : true
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setMouseFlag("mouseMiddle", !(host.service.mouseMiddle !== false))
        }
        Toggle {
          width: parent.width
          label: "Back"
          checked: host.service ? host.service.mouseBack === true : false
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setMouseFlag("mouseBack", !(host.service.mouseBack === true))
        }
        Toggle {
          width: parent.width
          label: "Forward"
          checked: host.service ? host.service.mouseForward === true : false
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setMouseFlag("mouseForward", !(host.service.mouseForward === true))
        }

      }

      Column {
        width: form.colWidth(4)
        spacing: Style.space(10)

        PanelSectionHeader {
          text: "SCROLL"
          foreground: host.fg
          fontFamily: host.fontFamily
        }
        Toggle {
          width: parent.width
          label: "Scroll up"
          checked: host.service ? host.service.mouseWheelUp !== false : true
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setMouseFlag("mouseWheelUp", !(host.service.mouseWheelUp !== false))
        }
        Toggle {
          width: parent.width
          label: "Scroll down"
          checked: host.service ? host.service.mouseWheelDown !== false : true
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setMouseFlag("mouseWheelDown", !(host.service.mouseWheelDown !== false))
        }
        Toggle {
          width: parent.width
          label: "Scroll left"
          checked: host.service ? host.service.mouseWheelLeft === true : false
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setMouseFlag("mouseWheelLeft", !(host.service.mouseWheelLeft === true))
        }
        Toggle {
          width: parent.width
          label: "Scroll right"
          checked: host.service ? host.service.mouseWheelRight === true : false
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setMouseFlag("mouseWheelRight", !(host.service.mouseWheelRight === true))
        }

      }

      Column {
        width: form.colWidth(4)
        spacing: Style.space(10)

        PanelSectionHeader {
          text: "RIPPLE"
          foreground: host.fg
          fontFamily: host.fontFamily
        }
        Toggle {
          width: parent.width
          label: "Ripple at cursor"
          description: "A ring where you click. Scroll ripples are separate."
          checked: host.service ? host.service.mouseRipple !== false : true
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setMouseFlag("mouseRipple", !(host.service.mouseRipple !== false))
        }
        Toggle {
          width: parent.width
          label: "Ripple on scroll"
          checked: host.service ? host.service.mouseRippleScroll === true : false
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setMouseFlag("mouseRippleScroll", !(host.service.mouseRippleScroll === true))
        }
        Toggle {
          width: parent.width
          label: "Follow a drag"
          description: "Move the click ripple with the cursor while the button is held. Follow rate is how often it catches up. Lower is smoother."
          checked: host.service ? host.service.mouseRippleFollow === true : false
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setMouseFlag("mouseRippleFollow", !(host.service.mouseRippleFollow === true))
        }
        Row {
          id: rippleMeasures
          width: parent.width
          spacing: Style.space(8)

          NumberField {
            width: (rippleMeasures.width - rippleMeasures.spacing) / 2
            fieldWidth: width
            label: "Follow rate (ms)"
            value: host.service ? host.service.mouseRippleFollowMs : 16
            from: 8
            to: 64
            stepSize: 8
            foreground: host.fg
            fontFamily: host.fontFamily
            onModified: function(value) { if (host.service) host.service.setMouseRippleFollowMs(value) }
          }
          NumberField {
            width: (rippleMeasures.width - rippleMeasures.spacing) / 2
            fieldWidth: width
            label: "Ripple size (px)"
            value: host.service ? host.service.mouseRippleSize : 36
            from: 8
            to: 160
            foreground: host.fg
            fontFamily: host.fontFamily
            onModified: function(value) { if (host.service) host.service.setMouseRippleSize(value) }
          }
        }
        Toggle {
          width: parent.width
          label: "Fade out"
          description: "Lower the ring's opacity across the ripple linger. Off, it stays solid until it disappears."
          checked: host.service ? host.service.mouseRippleFade === true : false
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.setMouseFlag("mouseRippleFade", !(host.service.mouseRippleFade === true))
        }
        NumberField {
          width: parent.width
          label: "Ripple linger (ms)"
          value: host.service ? host.service.mouseRippleMs : 400
          from: 100
          to: 2000
          stepSize: 50
          foreground: host.fg
          fontFamily: host.fontFamily
          onModified: function(value) { if (host.service) host.service.setMouseRippleMs(value) }
        }
      }
    }

    Column {
      visible: host.settingsPage === "ignore"
      width: parent.width
      spacing: Style.space(10)

      Text {
        width: parent.width
        textFormat: Text.PlainText
        text: "Record a chord and hold it for half a second. That exact combination stays off the overlay. A shorter hold, or a different set of keys, still shows."
        color: host.fg
        opacity: 0.78
        font.family: host.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }
      Button {
        text: host.service && host.service.recordingIgnore ? "Stop" : "Record"
        selected: host.service ? host.service.recordingIgnore === true : false
        bordered: true
        foreground: host.fg
        fontFamily: host.fontFamily
        onClicked: if (host.service) host.service.toggleIgnoreRecording()
      }
      Text {
        width: parent.width
        visible: host.service ? host.service.recordingIgnore === true : false
        textFormat: Text.PlainText
        text: {
          var key = host.service ? host.service.recordingChordKey : ""
          if (key) return "Holding " + Keys.chordLabel(key) + ". Keep it down."
          return "Waiting for keys. Hold the chord for half a second."
        }
        color: host.fg
        font.family: host.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }
      PanelSectionHeader { text: "IGNORED" }
      Text {
        width: parent.width
        visible: !host.service || !host.service.ignoredChords || host.service.ignoredChords.length === 0
        textFormat: Text.PlainText
        text: "None yet."
        color: host.fg
        opacity: 0.78
        font.family: host.fontFamily
        font.pixelSize: Style.font.caption
      }
      Repeater {
        model: host.service ? host.service.ignoredChords : []
        delegate: Button {
          required property string modelData
          width: parent.width
          text: Keys.chordLabel(modelData)
          selected: host.service && host.service.selectedIgnore === modelData
          bordered: true
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.selectedIgnore = modelData
        }
      }
      Row {
        spacing: Style.space(8)

        Button {
          text: "Remove"
          bordered: true
          enabled: !!host.service && host.service.selectedIgnore !== ""
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.removeIgnoredChord(host.service.selectedIgnore)
        }
        Button {
          text: "Remove all"
          bordered: true
          enabled: !!host.service && host.service.ignoredChords && host.service.ignoredChords.length > 0
          foreground: host.fg
          fontFamily: host.fontFamily
          onClicked: if (host.service) host.service.clearIgnoredChords()
        }
      }
    }

    Column {
      visible: host.settingsPage === "colors"
      width: parent.width
      spacing: Style.space(10)

        Column {
          width: parent.width
          spacing: Style.spacing.md

          PanelSectionHeader {
            text: "THEME"
            foreground: host.fg
            fontFamily: host.fontFamily
          }
          Flow {
            width: parent.width
            spacing: Style.spacing.md

            Repeater {
              model: Keys.themeOptions()

              Button {
                required property var modelData
                text: modelData.label
                selected: host.service && host.service.colorTheme === String(modelData.value)
                bordered: true
                foreground: host.fg
                fontFamily: host.fontFamily
                onClicked: if (host.service) host.service.setColorTheme(modelData.value)
              }
            }
          }
        }
        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: "Shell follows the Omarchy theme and fills the hex fields with those colors. Presets fill the hex fields. Editing a hex switches to Custom."
          color: host.fg
          opacity: 0.78
          font.family: host.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Flow {
          width: parent.width
          spacing: Style.space(16)

        Column {
          width: form.colWidth(3)
          spacing: Style.space(4)

          PanelSectionHeader {
            text: "BACKGROUND"
            foreground: host.fg
            fontFamily: host.fontFamily
          }
          Row {
            width: parent.width
            spacing: Style.space(8)
            Rectangle {
              width: Style.space(28)
              height: Style.space(28)
              radius: Style.cornerRadius
              color: Style.colorFromHex(host.service ? host.service.displayBackgroundColor : "#1A1A1A", Color.background)
              border.color: host.fg
              border.width: 1
            }
            TextField {
              id: bgHex
              width: parent.width - Style.space(36)
              foreground: host.fg
              font.family: host.fontFamily
              onEditingFinished: if (host.service) host.service.setBackgroundColor(text)
              onAccepted: if (host.service) host.service.setBackgroundColor(text)
            }
            Binding {
              target: bgHex
              property: "text"
              value: host.service ? host.service.displayBackgroundColor : "#1A1A1A"
              when: !bgHex.activeFocus
            }
          }
        }

        Column {
          width: form.colWidth(3)
          spacing: Style.space(4)

          PanelSectionHeader {
            text: "BORDER"
            foreground: host.fg
            fontFamily: host.fontFamily
          }
          Row {
            width: parent.width
            spacing: Style.space(8)
            Rectangle {
              width: Style.space(28)
              height: Style.space(28)
              radius: Style.cornerRadius
              color: Style.colorFromHex(host.service ? host.service.displayBorderColor : "#6E6E6E", Color.popups.border)
              border.color: host.fg
              border.width: 1
            }
            TextField {
              id: borderHex
              width: parent.width - Style.space(36)
              foreground: host.fg
              font.family: host.fontFamily
              onEditingFinished: if (host.service) host.service.setBorderColor(text)
              onAccepted: if (host.service) host.service.setBorderColor(text)
            }
            Binding {
              target: borderHex
              property: "text"
              value: host.service ? host.service.displayBorderColor : "#6E6E6E"
              when: !borderHex.activeFocus
            }
          }
        }

        Column {
          width: form.colWidth(3)
          spacing: Style.space(4)

          PanelSectionHeader {
            text: "FONT"
            foreground: host.fg
            fontFamily: host.fontFamily
          }
          Row {
            width: parent.width
            spacing: Style.space(8)
            Rectangle {
              width: Style.space(28)
              height: Style.space(28)
              radius: Style.cornerRadius
              color: Style.colorFromHex(host.service ? host.service.displayFontColor : "#F5F5F5", Color.popups.text)
              border.color: host.fg
              border.width: 1
            }
            TextField {
              id: fontHex
              width: parent.width - Style.space(36)
              foreground: host.fg
              font.family: host.fontFamily
              onEditingFinished: if (host.service) host.service.setFontColor(text)
              onAccepted: if (host.service) host.service.setFontColor(text)
            }
            Binding {
              target: fontHex
              property: "text"
              value: host.service ? host.service.displayFontColor : "#F5F5F5"
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
