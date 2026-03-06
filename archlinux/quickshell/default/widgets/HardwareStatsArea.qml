pragma ComponentBehavior: Bound

import QtQuick

import ".." as Root

Item {
    id: root

    readonly property var hardware: Root.HardwareStatsService

    property bool showCpu: true
    property bool showGpu: true
    property bool showMem: true

    readonly property bool cpuShown: showCpu && hardware.cpuAvailable
    readonly property bool gpuShown: showGpu && hardware.gpuAvailable
    readonly property bool memShown: showMem && hardware.memAvailable
    readonly property bool anyShown: cpuShown || gpuShown || memShown

    visible: anyShown
    height: parent.height
    width: visible ? contentRow.implicitWidth + leadingPadding + trailingPadding : 0

    property int leadingPadding: Root.Theme.rightWidgetPadding
    property int trailingPadding: Root.Theme.rightWidgetPadding
    property int columnSpacing: 0
    property int labelWidth: 20
    property int valueWidth: 26

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: root.columnSpacing

        Item {
            visible: root.cpuShown
            width: visible ? Math.max(root.labelWidth, root.valueWidth) : 0
            height: 21

            Column {
                anchors.fill: parent
                spacing: -2

                Text {
                    width: root.labelWidth
                    text: "CPU"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Normal
                    color: "#ffffff"
                    opacity: 0.9
                    horizontalAlignment: Text.AlignLeft
                    renderType: Text.NativeRendering
                }

                Text {
                    width: root.valueWidth
                    text: String(root.hardware.cpuPercent) + "%"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Normal
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignLeft
                    renderType: Text.NativeRendering
                }
            }
        }

        Item {
            visible: root.gpuShown
            width: visible ? Math.max(root.labelWidth, root.valueWidth) : 0
            height: 21

            Column {
                anchors.fill: parent
                spacing: -2

                Text {
                    width: root.labelWidth
                    text: "GPU"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Normal
                    color: "#ffffff"
                    opacity: 0.9
                    horizontalAlignment: Text.AlignLeft
                    renderType: Text.NativeRendering
                }

                Text {
                    width: root.valueWidth
                    text: String(root.hardware.gpuPercent) + "%"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Normal
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignLeft
                    renderType: Text.NativeRendering
                }
            }
        }

        Item {
            visible: root.memShown
            width: visible ? Math.max(root.labelWidth, root.valueWidth) : 0
            height: 21

            Column {
                anchors.fill: parent
                spacing: -2

                Text {
                    width: root.labelWidth
                    text: "MEM"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Normal
                    color: "#ffffff"
                    opacity: 0.9
                    horizontalAlignment: Text.AlignLeft
                    renderType: Text.NativeRendering
                }

                Text {
                    width: root.valueWidth
                    text: String(root.hardware.memPercent) + "%"
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Normal
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignLeft
                    renderType: Text.NativeRendering
                }
            }
        }
    }
}
