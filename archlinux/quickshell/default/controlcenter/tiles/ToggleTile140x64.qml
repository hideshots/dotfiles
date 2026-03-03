import QtQuick

import "." as Tiles
import "../.." as Root

Item {
    id: root

    property bool checked: false
    property string symbol: ""
    property string title: ""
    property string detail: ""
    property color accentColor: Qt.rgba(0.08, 0.44, 1.0, 1.0)

    signal toggled(bool checked)

    implicitWidth: 140
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
        radius: height / 2
        edgeLightEnabled: true
        hovered: hoverHandler.hovered
        pressed: tapHandler.pressed
        tintColor: Qt.rgba(0, 0, 0, 0.20)
        contrastColor: Qt.rgba(1, 1, 1, 0.0)
        borderColor: Qt.rgba(1, 1, 1, 0.12)
        edgeOpacity: 0.78
        edgeTint: Qt.rgba(1, 1, 1, 0.96)

        Row {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 9

            Tiles.SymbolCircle {
                anchors.verticalCenter: parent.verticalCenter
                diameter: 40
                filled: root.checked
                symbol: root.symbol
                symbolSize: 15
                symbolColor: root.checked ? root.accentColor : Qt.rgba(1, 1, 1, 0.98)
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    text: root.title
                    color: Qt.rgba(1, 1, 1, 1.0)
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    renderType: Text.NativeRendering
                    elide: Text.ElideRight
                }

                Text {
                    text: root.detail
                    color: Qt.rgba(1, 1, 1, 84 / 255)
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    renderType: Text.NativeRendering
                    elide: Text.ElideRight
                }
            }
        }
    }
}
