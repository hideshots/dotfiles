import QtQuick

import "." as Tiles
import "../.." as Root

Item {
    id: root

    property string sizeMode: "1x1"
    property var tileData: ({})

    readonly property string resolvedSizeMode: _resolveSizeMode(root.sizeMode)
    readonly property bool checked: _boolData("checked", false)
    readonly property string symbol: _stringData("symbol", "")
    readonly property color accentColor: _colorData("accentColor", Qt.rgba(0.08, 0.44, 1.0, 1.0))

    signal toggled(bool checked)
    signal activated()

    implicitWidth: root.resolvedSizeMode === "2x2" ? 140 : (root.resolvedSizeMode === "2x1" ? 140 : 64)
    implicitHeight: root.resolvedSizeMode === "2x2" ? 140 : 64
    width: implicitWidth
    height: implicitHeight

    function _resolveSizeMode(mode) {
        if (mode === "1x1" || mode === "2x1" || mode === "2x2") {
            return mode;
        }

        return "1x1";
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
        onTapped: {
            root.toggled(!root.checked);
            root.activated();
        }
    }

    Tiles.TileSurface {
        anchors.fill: parent
        radius: root.resolvedSizeMode === "1x1" ? (width / 2) : 25
        hovered: hoverHandler.hovered
        pressed: tapHandler.pressed
        tintColor: root.checked ? Qt.rgba(1, 1, 1, 1.0) : Qt.rgba(0, 0, 0, 0.20)
        contrastColor: Qt.rgba(1, 1, 1, 0.0)
        borderColor: Qt.rgba(1, 1, 1, 0.0)

        Root.SymbolIcon {
            anchors.centerIn: parent
            width: root.resolvedSizeMode === "2x2" ? 24 : 19
            height: width
            glyph: root.symbol
            fallbackColor: root.checked ? root.accentColor : Qt.rgba(1, 1, 1, 1.0)
            fallbackFontFamily: Root.Theme.fontFamilySymbol
            pixelSize: width
            fontWeight: Font.Bold
        }
    }
}
