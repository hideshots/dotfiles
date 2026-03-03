import QtQuick

import "." as Tiles
import "../.." as Root

Item {
    id: root

    property bool checked: false
    property string symbol: ""
    property color accentColor: Qt.rgba(0.08, 0.44, 1.0, 1.0)

    signal toggled(bool checked)

    implicitWidth: 64
    implicitHeight: 64
    width: implicitWidth
    height: implicitHeight

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tapHandler
        acceptedButtons: Qt.LeftButton
        onTapped: {
            root.checked = !root.checked;
            root.toggled(root.checked);
        }
    }

    Tiles.TileSurface {
        anchors.fill: parent
        radius: width / 2
        hovered: hoverHandler.hovered
        pressed: tapHandler.pressed
        tintColor: root.checked ? Qt.rgba(1, 1, 1, 1.0) : Qt.rgba(0, 0, 0, 0.20)
        contrastColor: Qt.rgba(1, 1, 1, 0.0)
        borderColor: Qt.rgba(1, 1, 1, 0.0)
        edgeLightEnabled: true
        edgeOpacity: root.checked ? 0.56 : 0.78
        edgeTint: root.checked ? Qt.rgba(0.85, 0.90, 1.0, 0.96) : Qt.rgba(1, 1, 1, 0.96)

        Text {
            anchors.centerIn: parent
            text: root.symbol
            color: root.checked ? root.accentColor : Qt.rgba(1, 1, 1, 1.0)
            font.family: Root.Theme.fontFamilySymbol
            font.pixelSize: 19
            font.weight: Font.Bold
            renderType: Text.NativeRendering
        }
    }
}
