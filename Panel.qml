import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    // Plugin API (injected by PluginPanelSlot)
    property var pluginApi: null

    // SmartPanel properties (required for panel behavior)
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    readonly property bool panelAnchorRight: true

    property real contentPreferredWidth: 420 * Style.uiScaleRatio
    property real contentPreferredHeight: 700 * Style.uiScaleRatio

    anchors.fill: parent

    // UI state variables
    property string batteryText: "Loading..."
    property string infoText: "Loading..."

    property int speakerVolume: 0
    property int micVolume: 0
    property bool micMuted: false
    
    property bool lightbarOn: false
    property int lightbarR: 0
    property int lightbarG: 0
    property int lightbarB: 255
    property int playerLeds: 0
    
    // Tab State
    property int activeTabIdx: 0

    // Flag to avoid firing commands on initial bind
    property bool isInitialized: false

    Component.onCompleted: {
        pollState();
    }

    function pollState() {
        procBattery.running = true;
        procInfo.running = true;
        
        procSpeakerVol.running = true;
        procMicVol.running = true;
        procMicState.running = true;
        procLightbarState.running = true;
        procPlayerLedsState.running = true;
    }

    function cmd(args) {
        if (!isInitialized) return;
        var p = genericProc.createObject(root, { command: ["dualsensectl"].concat(args) })
        p.running = true;
    }

    Component {
        id: genericProc
        Process {
            onExited: this.destroy()
        }
    }

    Process { id: procBattery; command: ["dualsensectl", "battery"]; stdout: StdioCollector { onStreamFinished: { if (text) root.batteryText = text.trim() } } }
    Process { id: procInfo;    command: ["dualsensectl", "info"];    stdout: StdioCollector { onStreamFinished: { if (text) root.infoText = text.trim()    } } }
    
    // Getters
    Process { 
        id: procSpeakerVol; command: ["dualsensectl", "volume"]; 
        stdout: StdioCollector { 
            onStreamFinished: { 
                if (text && !isNaN(parseInt(text))) root.speakerVolume = Math.round(parseInt(text) * 100 / 255);
                checkInit();
            } 
        } 
    }
    Process { 
        id: procMicVol; command: ["dualsensectl", "microphone-volume"]; 
        stdout: StdioCollector { 
            onStreamFinished: { 
                if (text && !isNaN(parseInt(text))) root.micVolume = Math.round(parseInt(text) * 100 / 255);
                checkInit();
            } 
        } 
    }
    Process { 
        id: procMicState; command: ["dualsensectl", "microphone"]; 
        stdout: StdioCollector { 
            onStreamFinished: { 
                if (text) root.micMuted = (text.trim() === "on");
                checkInit();
            } 
        } 
    }
    Process { 
        id: procLightbarState; command: ["dualsensectl", "lightbar"]; 
        stdout: StdioCollector { 
            onStreamFinished: { 
                if (text) {
                    if (text.trim() === "on") root.lightbarOn = true;
                    else if (text.trim() === "off") root.lightbarOn = false;
                }
                checkInit();
            } 
        } 
    }
    Process { 
        id: procPlayerLedsState; command: ["dualsensectl", "player-leds"]; 
        stdout: StdioCollector { 
            onStreamFinished: { 
                if (text && !isNaN(parseInt(text))) root.playerLeds = parseInt(text);
                checkInit();
            } 
        } 
    }

    property int initCount: 0
    function checkInit() {
        initCount++;
        if (initCount >= 5) isInitialized = true;
    }
    Timer {
        interval: 1000
        running: true
        onTriggered: isInitialized = true;
    }

    ColumnLayout {
        id: panelContainer
        anchors.fill: parent
        anchors.margins: Style.marginL
        spacing: Style.marginL

        // Header
        NBox {
            Layout.fillWidth: true
            Layout.preferredHeight: headerRow.implicitHeight + (Style.marginM * 2)

            RowLayout {
                id: headerRow
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                NText {
                    text: "\uf11b"
                    pointSize: Style.fontSizeXXL
                    color: Color.mPrimary
                    font.family: "Symbols Nerd Font"
                }

                NText {
                    text: "DualSense"
                    pointSize: Style.fontSizeL
                    font.weight: Style.fontWeightBold
                    color: Color.mOnSurface
                    Layout.fillWidth: true
                }

                NIconButton {
                    icon: "close"
                    tooltipText: "Close"
                    baseSize: Style.baseWidgetSize * 0.8
                    onClicked: {
                        pluginApi?.withCurrentScreen(screen => {
                            pluginApi?.closePanel(screen);
                        })
                    }
                }
            }
        }

        NTabBar {
            id: tabs
            Layout.fillWidth: true
            currentIndex: activeTabIdx
            onCurrentIndexChanged: root.activeTabIdx = currentIndex

            NTabButton {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "Controls"
                tabIndex: 0
                checked: tabs.currentIndex === tabIndex
            }
            NTabButton {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "Information"
                tabIndex: 1
                checked: tabs.currentIndex === tabIndex
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.activeTabIdx

            // Tab 0: Controls
            NScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalPolicy: ScrollBar.AlwaysOff
                verticalPolicy: ScrollBar.AsNeeded
                clip: true
                contentWidth: availableWidth

                ColumnLayout {
                    width: parent.width
                    spacing: Style.marginM

                    // Audio & Microphone
                    NBox {
                        Layout.fillWidth: true
                        Layout.preferredHeight: audioCol.implicitHeight + (Style.marginM * 2)

                        ColumnLayout {
                            id: audioCol
                            anchors.fill: parent
                            anchors.margins: Style.marginM
                            spacing: Style.marginS

                            NText {
                                text: "Audio & Microphone"
                                pointSize: Style.fontSizeM
                                font.weight: Style.fontWeightBold
                                color: Color.mPrimary
                            }

                            NText { text: "Speaker Volume"; color: Color.mOnSurfaceVariant }
                            NValueSlider {
                                Layout.fillWidth: true
                                from: 0; to: 100; stepSize: 1
                                value: root.speakerVolume
                                text: Math.round(value) + "%"
                                onMoved: value => { root.speakerVolume = value; root.cmd(["volume", Math.round(value * 255 / 100)]) }
                            }

                            NText { text: "Microphone Volume"; color: Color.mOnSurfaceVariant; Layout.topMargin: Style.marginS }
                            NValueSlider {
                                Layout.fillWidth: true
                                from: 0; to: 100; stepSize: 1
                                value: root.micVolume
                                text: Math.round(value) + "%"
                                onMoved: value => { root.micVolume = value; root.cmd(["microphone-volume", Math.round(value * 255 / 100)]) }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: Style.marginS
                                NText { text: "Microphone Mute"; color: Color.mOnSurfaceVariant; Layout.fillWidth: true }
                                NToggle {
                                    checked: root.micMuted
                                    onToggled: isChecked => {
                                        root.micMuted = isChecked;
                                        root.cmd(["microphone", isChecked ? "on" : "off"]);
                                    }
                                }
                            }
                        }
                    }

                    // Lighting & LEDs
                    NBox {
                        Layout.fillWidth: true
                        Layout.preferredHeight: ledCol.implicitHeight + (Style.marginM * 2)

                        ColumnLayout {
                            id: ledCol
                            anchors.fill: parent
                            anchors.margins: Style.marginM
                            spacing: Style.marginS

                            NText {
                                text: "Lighting & LEDs"
                                pointSize: Style.fontSizeM
                                font.weight: Style.fontWeightBold
                                color: Color.mPrimary
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                NText { text: "Lightbar State"; color: Color.mOnSurfaceVariant; Layout.fillWidth: true }
                                NToggle {
                                    checked: root.lightbarOn
                                    onToggled: isChecked => {
                                        root.lightbarOn = isChecked;
                                        root.cmd(["lightbar", isChecked ? "on" : "off"]);
                                    }
                                }
                            }

                            NText { text: "Lightbar RGB Color"; color: Color.mOnSurfaceVariant; Layout.topMargin: Style.marginS }
                            RowLayout {
                                Layout.fillWidth: true
                                NValueSlider {
                                    Layout.fillWidth: true
                                    from: 0; to: 255; stepSize: 1
                                    value: root.lightbarR
                                    text: "R:" + Math.round(value)
                                    onMoved: val => { root.lightbarR = val; root.cmd(["lightbar", root.lightbarR, root.lightbarG, root.lightbarB]) }
                                }
                                NValueSlider {
                                    Layout.fillWidth: true
                                    from: 0; to: 255; stepSize: 1
                                    value: root.lightbarG
                                    text: "G:" + Math.round(value)
                                    onMoved: val => { root.lightbarG = val; root.cmd(["lightbar", root.lightbarR, root.lightbarG, root.lightbarB]) }
                                }
                                NValueSlider {
                                    Layout.fillWidth: true
                                    from: 0; to: 255; stepSize: 1
                                    value: root.lightbarB
                                    text: "B:" + Math.round(value)
                                    onMoved: val => { root.lightbarB = val; root.cmd(["lightbar", root.lightbarR, root.lightbarG, root.lightbarB]) }
                                }
                            }

                            NText { text: "Player LEDs (0-7)"; color: Color.mOnSurfaceVariant; Layout.topMargin: Style.marginS }
                            NValueSlider {
                                Layout.fillWidth: true
                                from: 0; to: 7; stepSize: 1
                                value: root.playerLeds
                                text: Math.round(value)
                                onMoved: value => { root.playerLeds = value; root.cmd(["player-leds", value]) }
                            }
                        }
                    }

                    // Trigger Haptics
                NBox {
                    Layout.fillWidth: true
                    Layout.preferredHeight: hapticCol.implicitHeight + (Style.marginM * 2)

                    ColumnLayout {
                        id: hapticCol
                        anchors.fill: parent
                        anchors.margins: Style.marginM
                        spacing: Style.marginS

                        NText {
                            text: "Trigger Haptics"
                            pointSize: Style.fontSizeM
                            font.weight: Style.fontWeightBold
                            color: Color.mPrimary
                        }

                        component TriggerConfig: ColumnLayout {
                            id: tcRoot
                            property string side: "left"
                            property string title: "Left Trigger (L2)"
                            
                            property string mode: "reset"
                            property bool useDefaults: true
                            
                            property int startVal: 0
                            property int endVal: 0
                            property int strengthVal: 0
                            property int snapVal: 0
                            
                            property int posVal: 0
                            property int freqVal: 0

                            spacing: Style.marginS

                            NComboBox {
                                Layout.fillWidth: true
                                label: tcRoot.title
                                description: "Select haptic feedback mode"
                                model: [
                                    { key: "reset", name: "Reset / Off" },
                                    { key: "feedback", name: "Feedback" },
                                    { key: "weapon", name: "Weapon" },
                                    { key: "bow", name: "Bow" }
                                ]
                                currentKey: tcRoot.mode
                                onSelected: key => {
                                    tcRoot.mode = key;
                                    // Set some initial good defaults based on mode bounds
                                    if (key === "weapon") { tcRoot.startVal = 2; tcRoot.endVal = 7; }
                                    else { tcRoot.startVal = 0; tcRoot.endVal = 8; }
                                    tcRoot.sendCmd();
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: tcRoot.mode !== "reset"
                                NText { text: "Use Default Values"; color: Color.mOnSurfaceVariant; Layout.fillWidth: true }
                                NToggle {
                                    checked: tcRoot.useDefaults
                                    onToggled: isChecked => {
                                        tcRoot.useDefaults = isChecked;
                                        tcRoot.sendCmd();
                                    }
                                }
                            }
                            
                            function sendCmd() {
                                if (tcRoot.mode === "reset") {
                                    root.cmd(["trigger", tcRoot.side, "reset"])
                                } else if (tcRoot.mode === "feedback") {
                                    if (tcRoot.useDefaults) root.cmd(["trigger", tcRoot.side, "feedback", 1, 4, 6, 1]);
                                    else root.cmd(["trigger", tcRoot.side, "feedback", tcRoot.posVal, tcRoot.strengthVal, tcRoot.freqVal, 0]);
                                } else if (tcRoot.mode === "weapon") {
                                    if (tcRoot.useDefaults) root.cmd(["trigger", tcRoot.side, "weapon", 2, 4, 6, 1]);
                                    else root.cmd(["trigger", tcRoot.side, "weapon", Math.max(2, tcRoot.startVal), Math.max(2, tcRoot.endVal), tcRoot.strengthVal, tcRoot.snapVal]);
                                } else if (tcRoot.mode === "bow") {
                                    if (tcRoot.useDefaults) root.cmd(["trigger", tcRoot.side, "bow", 2, 7, 6, 1]);
                                    else root.cmd(["trigger", tcRoot.side, "bow", tcRoot.startVal, tcRoot.endVal, tcRoot.strengthVal, tcRoot.snapVal]);
                                }
                            }

                            // Mode: Feedback controls
                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: tcRoot.mode === "feedback" && !tcRoot.useDefaults
                                spacing: Style.marginXS
                                NText { text: "Position (0-9)"; color: Color.mOnSurfaceVariant; pointSize: Style.fontSizeS }
                                NValueSlider { Layout.fillWidth: true; from: 0; to: 9; stepSize: 1; value: tcRoot.posVal; text: Math.round(value); onMoved: val => { tcRoot.posVal = val; tcRoot.sendCmd() } }
                                NText { text: "Strength (0-8)"; color: Color.mOnSurfaceVariant; pointSize: Style.fontSizeS }
                                NValueSlider { Layout.fillWidth: true; from: 0; to: 8; stepSize: 1; value: tcRoot.strengthVal; text: Math.round(value); onMoved: val => { tcRoot.strengthVal = val; tcRoot.sendCmd() } }
                                NText { text: "Frequency (0-8)"; color: Color.mOnSurfaceVariant; pointSize: Style.fontSizeS }
                                NValueSlider { Layout.fillWidth: true; from: 0; to: 8; stepSize: 1; value: tcRoot.freqVal; text: Math.round(value); onMoved: val => { tcRoot.freqVal = val; tcRoot.sendCmd() } }
                            }

                            // Mode: Weapon or Bow controls
                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: (tcRoot.mode === "weapon" || tcRoot.mode === "bow") && !tcRoot.useDefaults
                                spacing: Style.marginXS
                                NText { text: "Start" + (tcRoot.mode === "weapon" ? " (2-7)" : " (0-8)"); color: Color.mOnSurfaceVariant; pointSize: Style.fontSizeS }
                                NValueSlider { Layout.fillWidth: true; from: (tcRoot.mode === "weapon" ? 2 : 0); to: (tcRoot.mode === "weapon" ? 7 : 8); stepSize: 1; value: tcRoot.startVal; text: Math.round(value); onMoved: val => { tcRoot.startVal = val; tcRoot.sendCmd() } }
                                NText { text: "End" + (tcRoot.mode === "weapon" ? " (2-7)" : " (0-8)"); color: Color.mOnSurfaceVariant; pointSize: Style.fontSizeS }
                                NValueSlider { Layout.fillWidth: true; from: (tcRoot.mode === "weapon" ? 2 : 0); to: (tcRoot.mode === "weapon" ? 7 : 8); stepSize: 1; value: tcRoot.endVal; text: Math.round(value); onMoved: val => { tcRoot.endVal = val; tcRoot.sendCmd() } }
                                NText { text: "Strength (0-8)"; color: Color.mOnSurfaceVariant; pointSize: Style.fontSizeS }
                                NValueSlider { Layout.fillWidth: true; from: 0; to: 8; stepSize: 1; value: tcRoot.strengthVal; text: Math.round(value); onMoved: val => { tcRoot.strengthVal = val; tcRoot.sendCmd() } }
                                NText { text: "Snap (0-1)"; color: Color.mOnSurfaceVariant; pointSize: Style.fontSizeS }
                                NValueSlider { Layout.fillWidth: true; from: 0; to: 1; stepSize: 1; value: tcRoot.snapVal; text: Math.round(value); onMoved: val => { tcRoot.snapVal = val; tcRoot.sendCmd() } }
                            }
                        }

                        TriggerConfig {
                            Layout.fillWidth: true
                            side: "left"
                            title: "Left Trigger (L2)"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Color.mOutline
                            Layout.topMargin: Style.marginM
                            Layout.bottomMargin: Style.marginM
                        }

                        TriggerConfig {
                            Layout.fillWidth: true
                            side: "right"
                            title: "Right Trigger (R2)"
                        }
                    }
                }
                }
            }
            
            // Tab 1: Information
            NScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalPolicy: ScrollBar.AlwaysOff
                verticalPolicy: ScrollBar.AsNeeded
                clip: true
                contentWidth: availableWidth

                ColumnLayout {
                    width: parent.width
                    spacing: Style.marginM

                    // Device Info
                    NBox {
                        Layout.fillWidth: true
                        Layout.preferredHeight: infoCol.implicitHeight + (Style.marginM * 2)

                        ColumnLayout {
                            id: infoCol
                            anchors.fill: parent
                            anchors.margins: Style.marginM
                            spacing: Style.marginM

                            NText {
                                text: "Device Information"
                                pointSize: Style.fontSizeM
                                font.weight: Style.fontWeightBold
                                color: Color.mPrimary
                            }

                            NText {
                                text: "Battery: " + root.batteryText
                                color: Color.mOnSurface
                            }
                            NText {
                                text: "Info: " + root.infoText
                                color: Color.mOnSurface
                            }

                            NButton {
                                Layout.fillWidth: true
                                text: "Power Off"
                                icon: "power"
                                onClicked: {
                                    root.cmd(["power-off"]);
                                    pluginApi?.withCurrentScreen(screen => {
                                        pluginApi?.closePanel(screen);
                                    })
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
