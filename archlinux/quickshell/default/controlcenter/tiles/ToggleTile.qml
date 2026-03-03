import QtQuick

import "." as Tiles
import "../.." as Root

Item {
    id: root

    property string sizeMode: "2x2"
    property var tileData: ({})

    readonly property string resolvedSizeMode: _resolveSizeMode(root.sizeMode)
    readonly property bool compactMode: root.resolvedSizeMode === "2x1"
    readonly property bool iconOnlyMode: root.resolvedSizeMode === "1x1"

    readonly property bool checked: _boolData("checked", false)
    readonly property string symbol: _stringData("symbol", "")
    readonly property string title: _stringData("title", "")
    readonly property string detailOn: _stringData("detailOn", "On")
    readonly property string detailOff: _stringData("detailOff", "Off")
    readonly property string detail: _stringData("detail", root.checked ? root.detailOn : root.detailOff)
    readonly property color accentColor: _colorData("accentColor", Qt.rgba(0.08, 0.44, 1.0, 1.0))
    readonly property bool compactTitleWrap: _boolData("compactTitleWrap", false)

    signal toggled(bool checked)

    implicitWidth: root.iconOnlyMode ? 64 : 140
    implicitHeight: root.resolvedSizeMode === "2x2" ? 140 : 64
    width: implicitWidth
    height: implicitHeight

    function _resolveSizeMode(mode) {
        if (mode === "1x1" || mode === "2x1" || mode === "2x2") {
            return mode;
        }

        return "2x2";
    }

    function _rawDataValue(key, fallback) {
        var data = root.tileData;
        if (!data || typeof data !== "object") {
            return fallback;
        }

        var value = data[key];
        return value === undefined ? fallback : value;
    }

    function _stringData(key, fallback) {
        var value = _rawDataValue(key, fallback);
        return value === undefined || value === null ? String(fallback) : String(value);
    }

    function _boolData(key, fallback) {
        return !!_rawDataValue(key, fallback);
    }

    function _colorData(key, fallback) {
        return _rawDataValue(key, fallback);
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tapHandler
        acceptedButtons: Qt.LeftButton
        onTapped: root.toggled(!root.checked)
    }

    Tiles.TileSurface {
        anchors.fill: parent
        radius: root.resolvedSizeMode === "2x2" ? 34 : (height / 2)
        hovered: hoverHandler.hovered
        pressed: tapHandler.pressed
        tintColor: root.iconOnlyMode
            ? (root.checked ? Qt.rgba(1, 1, 1, 1.0) : Qt.rgba(0, 0, 0, 0.20))
            : Qt.rgba(0, 0, 0, 0.20)
        contrastColor: Qt.rgba(1, 1, 1, 0.0)
        borderColor: root.iconOnlyMode ? Qt.rgba(1, 1, 1, 0.0) : Qt.rgba(1, 1, 1, 0.12)
        edgeOpacity: root.iconOnlyMode ? (root.checked ? 0.56 : 0.78) : 0.78
        edgeTint: root.iconOnlyMode
            ? (root.checked ? Qt.rgba(0.85, 0.90, 1.0, 0.96) : Qt.rgba(1, 1, 1, 0.96))
            : Qt.rgba(1, 1, 1, 0.96)

        Tiles.SymbolCircle {
            visible: root.resolvedSizeMode === "2x2"
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 15
            anchors.topMargin: 14
            diameter: 35
            filled: root.checked
            symbol: root.symbol
            symbolSize: 15
            symbolColor: root.checked ? root.accentColor : Qt.rgba(1, 1, 1, 0.98)
        }

        Text {
            visible: root.resolvedSizeMode === "2x2"
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 13
            anchors.rightMargin: 13
            anchors.top: parent.top
            anchors.topMargin: 68
            text: root.title
            color: Qt.rgba(1, 1, 1, 0.85)
            font.family: Root.Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
            renderType: Text.NativeRendering
            elide: Text.ElideRight
        }

        Text {
            visible: root.resolvedSizeMode === "2x2"
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 13
            anchors.rightMargin: 13
            anchors.top: parent.top
            anchors.topMargin: 90
            text: root.detail
            color: Qt.rgba(1, 1, 1, 84 / 255)
            font.family: Root.Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
            lineHeight: 18
            lineHeightMode: Text.FixedHeight
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            renderType: Text.NativeRendering
        }

        Row {
            visible: root.compactMode
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 14
            spacing: 5

            Tiles.SymbolCircle {
                anchors.verticalCenter: parent.verticalCenter
                diameter: 35
                filled: root.checked
                symbol: root.symbol
                symbolSize: 15
                symbolColor: root.checked ? root.accentColor : Qt.rgba(1, 1, 1, 0.98)
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, parent.width - 40 - parent.spacing)
                spacing: 0

                Text {
                    text: root.title
                    color: Qt.rgba(1, 1, 1, 0.85)
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                    width: parent.width
                    wrapMode: root.compactTitleWrap ? Text.WordWrap : Text.NoWrap
                    maximumLineCount: root.compactTitleWrap ? 2 : 1
                    elide: root.compactTitleWrap ? Text.ElideNone : Text.ElideRight
                }

                Text {
                    text: root.detail
                    color: Qt.rgba(1, 1, 1, 0.75)
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                    elide: Text.ElideRight
                }
            }
        }

        Text {
            visible: root.iconOnlyMode
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
