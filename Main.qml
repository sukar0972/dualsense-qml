import QtQuick
import Quickshell

Item {
    id: root
    property var pluginApi: null

    Component.onCompleted: {
        console.log("DualSense QML Plugin loaded!")
    }
}
