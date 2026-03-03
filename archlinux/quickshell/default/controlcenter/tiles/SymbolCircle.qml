import QtQuick

import "../.." as Root

Item {
    id: root

    property int diameter: 40
    property bool filled: false
    property string symbol: ""
    property int symbolSize: 17
    property color symbolColor: filled ? Qt.rgba(0.08, 0.44, 1.0, 1.0) : Qt.rgba(1, 1, 1, 0.97)
    property color filledColor: Qt.rgba(1, 1, 1, 1.0)
    property color unfilledColor: Qt.rgba(1, 1, 1, 0.2)
    property color borderColor: Qt.rgba(1, 1, 1, 0.0)

    implicitWidth: diameter
    implicitHeight: diameter
    width: diameter
    height: diameter

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.filled ? root.filledColor : root.unfilledColor
        border.width: root.filled ? 1 : 0
        border.color: root.borderColor
        antialiasing: true
    }

    Text {
        anchors.centerIn: parent
        text: root.symbol
        color: root.symbolColor
        font.family: Root.Theme.fontFamilySymbol
        font.pixelSize: root.symbolSize
        font.weight: Font.Bold
        renderType: Text.NativeRendering
    }
}
