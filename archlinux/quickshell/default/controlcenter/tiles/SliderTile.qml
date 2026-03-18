import QtQuick

import "." as Tiles
import "../.." as Root

Item {
    id: root

    property string sizeMode: "4x1"
    property var tileData: ({})
    property real openFlashOpacity: 0.0
    property bool interactive: true

    readonly property string resolvedSizeMode: _resolveSizeMode(root.sizeMode)
    readonly property bool compactMode: root.resolvedSizeMode === "2x1"
    readonly property string title: _stringData("title", "Display")
    readonly property string detailText: _stringData("detailText", "")
    readonly property string minusSymbol: _stringData("minusSymbol", "􀆬")
    readonly property string plusSymbol: _stringData("plusSymbol", "􀆮")
    readonly property bool sliderEnabled: _boolData("enabled", true)
    readonly property bool sliderInteractive: root.sliderEnabled && root.interactive
    readonly property real value: _clamp(_numberData("value", 0.66))
    property real pendingValue: root.value
    property bool hasPendingValue: false
    readonly property real presentedValue: root.hasPendingValue ? root.pendingValue : root.value

    signal valueChangedByUser(real value)

    implicitWidth: root.compactMode ? 140 : 292
    implicitHeight: 64
    width: implicitWidth
    height: implicitHeight

    function _resolveSizeMode(mode) {
        if (mode === "2x1" || mode === "4x1") {
            return mode;
        }

        return "4x1";
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

    function _numberData(key, fallback) {
        var number = Number(_rawDataValue(key, fallback));
        if (!isFinite(number)) {
            return Number(fallback);
        }

        return number;
    }

    function _clamp(nextValue) {
        return Math.max(0, Math.min(1, Number(nextValue)));
    }

    function _setUserValue(nextValue) {
        if (!root.sliderEnabled) {
            return;
        }

        var clamped = _clamp(nextValue);
        if (Math.abs(clamped - root.presentedValue) < 0.0001) {
            return;
        }

        root.pendingValue = clamped;
        root.hasPendingValue = true;
        root.valueChangedByUser(clamped);
    }

    function _setFromTrackX(trackX, trackWidth) {
        if (!root.sliderEnabled || trackWidth <= 0) {
            return;
        }

        root._setUserValue(trackX / trackWidth);
    }

    onValueChanged: {
        if (!root.hasPendingValue) {
            root.pendingValue = root.value;
            return;
        }

        if (Math.abs(root.value - root.pendingValue) < 0.005) {
            root.pendingValue = root.value;
            root.hasPendingValue = false;
        }
    }

    HoverHandler {
        id: hoverHandler
        enabled: root.sliderInteractive
    }

    Tiles.TileSurface {
        anchors.fill: parent
        flashOverlayOpacity: root.openFlashOpacity
        radius: root.compactMode ? (height / 2) : 25
        hovered: root.sliderInteractive && hoverHandler.hovered
        pressed: root.sliderInteractive && (minusTap.pressed || plusTap.pressed || sliderTrackMouseArea.pressed)
        tintColor: Qt.rgba(0, 0, 0, 0.20)
        contrastColor: Qt.rgba(1, 1, 1, 0.0)
        borderColor: Qt.rgba(1, 1, 1, 0.0)
        opacity: root.sliderEnabled ? 1.0 : 0.48

        Text {
            id: titleLabel
            anchors.left: parent.left
            anchors.leftMargin: root.compactMode ? 12 : 16
            anchors.top: parent.top
            anchors.topMargin: root.compactMode ? 11 : 12
            text: root.title
            color: Qt.rgba(1, 1, 1, 217 / 255)
            font.family: Root.Theme.fontFamily
            font.pixelSize: root.compactMode ? 11 : 12
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
        }

        Text {
            visible: root.sliderEnabled && root.detailText.length > 0
            anchors.right: parent.right
            anchors.rightMargin: root.compactMode ? 12 : 16
            anchors.verticalCenter: titleLabel.verticalCenter
            text: root.detailText
            color: Qt.rgba(1, 1, 1, root.sliderEnabled ? 0.60 : 0.72)
            font.family: Root.Theme.fontFamily
            font.pixelSize: root.compactMode ? 10 : 11
            font.weight: Font.Medium
            renderType: Text.NativeRendering
            elide: Text.ElideRight
        }

        Item {
            id: controlsRow
            anchors.left: parent.left
            anchors.leftMargin: root.compactMode ? 10 : 16
            anchors.right: parent.right
            anchors.rightMargin: root.compactMode ? 10 : 20
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.compactMode ? 7 : 8
            height: 28

            Item {
                id: minusButton
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 20

                HoverHandler {
                    id: minusHover
                    enabled: root.sliderInteractive
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    id: minusTap
                    enabled: root.sliderInteractive
                    acceptedButtons: Qt.LeftButton
                    onTapped: root._setUserValue(root.presentedValue - 0.05)
                }

                Root.SymbolIcon {
                    svgScale: 1.18
                    anchors.centerIn: parent
                    width: 15
                    height: 15
                    glyph: root.minusSymbol
                    fallbackColor: Qt.rgba(1, 1, 1, 0.95)
                    opacity: !root.sliderEnabled ? 0.68 : (minusTap.pressed ? 0.62 : (minusHover.hovered ? 0.92 : 1.0))
                    fallbackFontFamily: Root.Theme.fontFamilySymbol
                    pixelSize: 15
                    fontWeight: Font.Bold
                }
            }

            Item {
                id: sliderTrackInput
                anchors.left: minusButton.right
                anchors.leftMargin: 15
                anchors.right: plusButton.left
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                height: 20

                MouseArea {
                    id: sliderTrackMouseArea
                    anchors.fill: parent
                    enabled: root.sliderInteractive
                    hoverEnabled: root.sliderInteractive
                    cursorShape: root.sliderInteractive ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onPressed: function (mouse) {
                        root._setFromTrackX(mouse.x - sliderTrack.x, sliderTrack.width);
                    }
                    onPositionChanged: function (mouse) {
                        if (!pressed) {
                            return;
                        }
                        root._setFromTrackX(mouse.x - sliderTrack.x, sliderTrack.width);
                    }
                    onClicked: function (mouse) {
                        root._setFromTrackX(mouse.x - sliderTrack.x, sliderTrack.width);
                    }
                }

                Rectangle {
                    id: sliderTrack
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 4
                    radius: 999
                    color: Qt.rgba(1, 1, 1, 0.25)
                    opacity: root.sliderEnabled && sliderTrackMouseArea.containsMouse ? 0.96 : 0.90
                }

                Rectangle {
                    anchors.left: sliderTrack.left
                    anchors.verticalCenter: sliderTrack.verticalCenter
                    width: sliderTrack.width * root.presentedValue
                    height: sliderTrack.height
                    radius: sliderTrack.radius
                    color: Qt.rgba(1, 1, 1, 0.96)
                }

                Rectangle {
                    width: 18
                    height: 15
                    radius: 7.5
                    visible: root.sliderInteractive && (sliderTrackMouseArea.containsMouse || sliderTrackMouseArea.pressed)
                    x: sliderTrack.x + (sliderTrack.width * root.presentedValue) - (width / 2)
                    y: sliderTrack.y + (sliderTrack.height / 2) - (height / 2)
                    color: Qt.rgba(1, 1, 1, 1.0)
                }
            }

            Item {
                id: plusButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 20

                HoverHandler {
                    id: plusHover
                    enabled: root.sliderInteractive
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    id: plusTap
                    enabled: root.sliderInteractive
                    acceptedButtons: Qt.LeftButton
                    onTapped: root._setUserValue(root.presentedValue + 0.05)
                }

                Root.SymbolIcon {
                    svgScale: 1.18
                    anchors.centerIn: parent
                    width: 15
                    height: 15
                    glyph: root.plusSymbol
                    fallbackColor: Qt.rgba(1, 1, 1, 0.95)
                    opacity: !root.sliderEnabled ? 0.68 : (plusTap.pressed ? 0.62 : (plusHover.hovered ? 0.92 : 1.0))
                    fallbackFontFamily: Root.Theme.fontFamilySymbol
                    pixelSize: 15
                    fontWeight: Font.Bold
                }
            }
        }
    }
}
