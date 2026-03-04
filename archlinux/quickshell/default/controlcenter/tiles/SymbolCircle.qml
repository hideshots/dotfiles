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

    Root.SymbolIcon {
        anchors.centerIn: parent
        width: root.symbolSize
        height: root.symbolSize
        svgScale: 1.18
        glyph: root.symbol
        fallbackColor: root.symbolColor
        fallbackFontFamily: Root.Theme.fontFamilySymbol
        pixelSize: root.symbolSize
        fontWeight: Font.Bold
    }
}
