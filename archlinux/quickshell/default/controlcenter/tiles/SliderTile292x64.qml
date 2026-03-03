import QtQuick

import "." as Tiles
import "../.." as Root

Item {
    id: root

    property string title: "Display"
    property real value: 0.66
    property string minusSymbol: "􀆬"
    property string plusSymbol: "􀆮"

    signal valueChangedByUser(real value)

    implicitWidth: 292
    implicitHeight: 64
    width: implicitWidth
    height: implicitHeight

    function _clamp(nextValue) {
        return Math.max(0, Math.min(1, Number(nextValue)));
    }

    function _setUserValue(nextValue) {
        var clamped = _clamp(nextValue);
        if (Math.abs(clamped - root.value) < 0.0001) {
            return;
        }
        root.value = clamped;
        root.valueChangedByUser(clamped);
    }

    function _setFromTrackX(trackX, trackWidth) {
        if (trackWidth <= 0) {
            return;
        }
        _setUserValue(trackX / trackWidth);
    }

    onValueChanged: {
        var clamped = _clamp(root.value);
        if (clamped !== root.value) {
            root.value = clamped;
        }
    }

    HoverHandler {
        id: hoverHandler
    }

    Tiles.TileSurface {
        anchors.fill: parent
        radius: 25
        hovered: hoverHandler.hovered
        pressed: minusTap.pressed || plusTap.pressed || sliderTrackMouseArea.pressed
        tintColor: Qt.rgba(0, 0, 0, 0.20)
        contrastColor: Qt.rgba(1, 1, 1, 0.0)
        borderColor: Qt.rgba(1, 1, 1, 0.12)
        edgeOpacity: 0.78
        edgeTint: Qt.rgba(1, 1, 1, 0.96)

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 12
            text: root.title
            color: Qt.rgba(1, 1, 1, 217 / 255)
            font.family: Root.Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
        }

        Item {
            id: controlsRow
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            height: 28

            Item {
                id: minusButton
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 20

                HoverHandler {
                    id: minusHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    id: minusTap
                    acceptedButtons: Qt.LeftButton
                    onTapped: root._setUserValue(root.value - 0.05)
                }

                Text {
                    anchors.centerIn: parent
                    text: root.minusSymbol
                    color: Qt.rgba(1, 1, 1, 0.95)
                    opacity: minusTap.pressed ? 0.62 : (minusHover.hovered ? 0.92 : 1)
                    font.family: Root.Theme.fontFamilySymbol
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                }
            }

            Item {
                id: sliderTrackInput
                anchors.left: minusButton.right
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                width: 218
                height: 20

                MouseArea {
                    id: sliderTrackMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
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
                    opacity: sliderTrackMouseArea.containsMouse ? 0.96 : 0.90
                }

                Rectangle {
                    anchors.left: sliderTrack.left
                    anchors.verticalCenter: sliderTrack.verticalCenter
                    width: sliderTrack.width * root.value
                    height: sliderTrack.height
                    radius: sliderTrack.radius
                    color: Qt.rgba(1, 1, 1, 0.96)
                }

                Rectangle {
                    width: 18
                    height: 15
                    radius: 7.5
                    visible: sliderTrackMouseArea.containsMouse || sliderTrackMouseArea.pressed
                    x: sliderTrack.x + (sliderTrack.width * root.value) - (width / 2)
                    y: sliderTrack.y + (sliderTrack.height / 2) - (height / 2)
                    color: Qt.rgba(1, 1, 1, 1.0)
                }
            }

            Item {
                id: plusButton
                anchors.left: sliderTrackInput.right
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 20

                HoverHandler {
                    id: plusHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    id: plusTap
                    acceptedButtons: Qt.LeftButton
                    onTapped: root._setUserValue(root.value + 0.05)
                }

                Text {
                    anchors.centerIn: parent
                    text: root.plusSymbol
                    color: Qt.rgba(1, 1, 1, 0.95)
                    opacity: plusTap.pressed ? 0.62 : (plusHover.hovered ? 0.92 : 1)
                    font.family: Root.Theme.fontFamilySymbol
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                }
            }
        }
    }
}
