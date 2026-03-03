import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null

  // Required bar widget properties
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  // Bar sizing helpers
  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real barHeight: Style.getBarHeightForScreen(screenName)
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  // Battery state
  property string batteryLevel: "..."

  // Size calculations following Noctalia pattern
  readonly property real contentWidth: isVertical ? root.barHeight - Style.marginL : layout.implicitWidth + Style.marginM * 2
  readonly property real contentHeight: isVertical ? layout.implicitHeight + Style.marginS * 2 : root.capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  // --- Battery poller ---
  Process {
    id: batteryPoller
    command: ["dualsensectl", "battery"]
    running: false
    stdout: StdioCollector {}

    onExited: exitCode => {
      if (exitCode === 0 && stdout.text.trim()) {
        let output = stdout.text.trim().toLowerCase();
        if (output.includes("charging") && !output.includes("discharging")) {
            root.batteryLevel = "Charging";
        } else {
            // Extract the number (e.g., "65 discharging" -> "65%")
            let match = output.match(/(\d+)/);
            if (match && match[1]) {
                root.batteryLevel = match[1] + "%";
            } else {
                root.batteryLevel = stdout.text.trim(); // fallback to original
            }
        }
      }
    }
  }

  Timer {
    interval: 60000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: batteryPoller.running = true
  }

  // --- Visual capsule ---
  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    radius: Style.radiusL
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Item {
        id: layout
        anchors.centerIn: parent
        implicitWidth: isVertical ? (vLayout.visible ? vLayout.implicitWidth : 0) : (hLayout.visible ? hLayout.implicitWidth : 0)
        implicitHeight: isVertical ? (vLayout.visible ? vLayout.implicitHeight : 0) : (hLayout.visible ? hLayout.implicitHeight : 0)

        RowLayout {
          id: hLayout
          anchors.centerIn: parent
          spacing: Style.marginS
          visible: !root.isVertical

          NText {
            id: iconEl
            text: "\uf11b"
            color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
            pointSize: Style.toOdd(root.capsuleHeight * 0.5)
            font.family: "Symbols Nerd Font"
            Layout.alignment: Qt.AlignVCenter
          }

          NText {
            id: batteryText
            text: root.batteryLevel
            color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
            pointSize: root.barFontSize
            applyUiScale: false
            Layout.alignment: Qt.AlignVCenter
          }
        }

        // Vertical bar layout
        ColumnLayout {
          id: vLayout
          anchors.centerIn: parent
          spacing: Style.marginXS
          visible: root.isVertical

          NText {
            text: "\uf11b"
            pointSize: Style.toOdd(root.capsuleHeight * 0.45)
            color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
            font.family: "Symbols Nerd Font"
            Layout.alignment: Qt.AlignHCenter
          }

          NText {
            text: root.batteryLevel
            color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
            pointSize: root.barFontSize * 0.65
            applyUiScale: false
            Layout.alignment: Qt.AlignHCenter
          }
        }
    }
  }

  // --- Mouse area ---
  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: function(mouse) {
      if (pluginApi) {
        if (mouse.button === Qt.LeftButton) {
            pluginApi.openPanel(root.screen, root)
        } else if (mouse.button === Qt.RightButton) {
            BarService.openPluginSettings(root.screen, pluginApi.manifest)
        }
      }
    }

    onEntered: {
      TooltipService.show(root, "DualSense: " + root.batteryLevel, BarService.getTooltipDirection(root.screen?.name))
    }

    onExited: {
      TooltipService.hide()
    }
  }
}
