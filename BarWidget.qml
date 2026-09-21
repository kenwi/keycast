import QtQuick
import qs.Commons
import qs.Ui
import "Keys.js" as Keys

BarWidget {
  id: root
  moduleName: "local.keycast"

  property var service: null
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool overlayOn: service ? service.overlayEnabled === true
    : Keys.normalizeSettings(root.settings).overlayEnabled
  readonly property bool bridgeReady: service ? service.bridgeInstalled === true : false

  function syncService() {
    service = bar && bar.shell && typeof bar.shell.serviceFor === "function"
      ? bar.shell.serviceFor(moduleName) : null
    pushSettings()
  }

  function pushSettings() {
    if (service && typeof service.applySettings === "function")
      service.applySettings(root.settings)
  }

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    close()
  }

  function handlePress(button) {
    if (button === Qt.RightButton || button === Qt.MiddleButton) {
      open()
      return
    }
    if (service && typeof service.toggleOverlay === "function") service.toggleOverlay()
    else pushSettings()
  }

  onBarChanged: syncService()
  onSettingsChanged: pushSettings()
  onServiceChanged: {
    if (panelLoader.item) panelLoader.item.service = service
    pushSettings()
  }
  Component.onCompleted: syncService()

  Timer {
    interval: 250
    repeat: true
    running: root.service === null
    onTriggered: root.syncService()
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      item.bar = root.bar
      item.anchorItem = root
      item.hostWidget = root
      item.service = root.service
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰌌"
    active: root.overlayOn
    tooltipText: !root.bridgeReady
      ? "Keycast · right-click to install the Hyprland bridge"
      : root.overlayOn
        ? "Keycast on · click to disable, right-click for settings"
        : "Keycast off · click to enable, right-click for settings"
    onPressed: function(buttonCode) { root.handlePress(buttonCode) }
  }
}
