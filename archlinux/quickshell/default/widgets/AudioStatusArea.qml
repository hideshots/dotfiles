pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects

import ".." as Root
import "../menu" as Menu

Rectangle {
    id: root

    property var highlightState: null
    readonly property var audio: Root.AudioService
    readonly property var _audioSvgWarmupNames: [
        "speaker.slash.fill",
        "speaker.wave.3.fill.0",
        "speaker.wave.3.fill.1",
        "speaker.wave.3.fill.2",
        "speaker.wave.3.fill.3"
    ]

    visible: audio.visible
    height: parent.height
    width: visible ? audioIcon.width + (Root.Theme.itemPadding * 2) : 0
    color: "transparent"
    radius: Root.Theme.borderRadius

    function syncHighlight() {
        if (!root.highlightState) {
            return;
        }

        if (audioMenu.visible) {
            root.highlightState.activeTarget = root;
            return;
        }

        if (root.highlightState.activeTarget === root) {
            root.highlightState.activeTarget = null;
        }
    }

    onVisibleChanged: {
        if (!visible && audioMenu.visible) {
            audioMenu.closeTopMenu();
        }
    }

    Item {
        id: audioSvgWarmup
        visible: false

        Repeater {
            model: root._audioSvgWarmupNames

            Image {
                required property string modelData
                source: Qt.resolvedUrl("../" + Root.Symbols.svgDir + "/" + modelData + ".svg")
                asynchronous: true
                cache: true
                sourceSize.width: Root.Theme.iconSize
                sourceSize.height: Root.Theme.iconSize
            }
        }
    }

    Root.SymbolIcon {
        id: audioIcon
        anchors.centerIn: parent
        width: Root.Theme.iconSize
        height: Root.Theme.iconSize
        fallbackWhileSvgLoading: false
        glyph: root.audio.iconGlyph
        svgNameOverride: root.audio.iconSvgName
        fallbackFontFamily: Root.Theme.fontFamily
        pixelSize: Root.Theme.iconSize
        fallbackColor: Root.Theme.textSecondary
    }

    DropShadow {
        anchors.fill: audioIcon
        source: audioIcon
        visible: Root.Theme.isDark
        horizontalOffset: Root.Theme.shadowHorizontalOffset
        verticalOffset: Root.Theme.shadowVerticalOffset
        radius: Root.Theme.shadowRadius
        samples: 16
        spread: 0
        color: Root.Theme.shadowColor
    }

    MouseArea {
        id: audioMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: function (mouse) {
            if (mouse.button === Qt.MiddleButton) {
                root.audio.setMuted(!root.audio.muted);
                return;
            }

            if (mouse.button === Qt.LeftButton) {
                audioMenu.toggle();
            }
        }
        onWheel: function (wheel) {
            var delta = wheel.angleDelta.y;
            if (delta === 0) {
                return;
            }

            var step = 0.05;
            var direction = delta > 0 ? 1 : -1;
            root.audio.setVolume(root.audio.value + (step * direction));
            wheel.accepted = true;
        }
    }

    Menu.MenuPopup {
        id: audioMenu
        anchorItem: root
        anchorPointX: root.width - implicitWidth
        anchorPointY: root.height + yOffset
        yOffset: 8
        adaptiveWidth: true
        openEffectEnabled: true

        model: [
            {
                type: "custom",
                component: volumeSliderRow
            }
        ]
    }

    Component {
        id: volumeSliderRow

        Item {
            id: volumeRow
            implicitWidth: 280
            implicitHeight: 46
            opacity: root.audio.sliderEnabled ? 1.0 : 0.45

            function setFromX(localX) {
                if (!root.audio.sliderEnabled || sliderTrack.width <= 0) {
                    return;
                }
                var value = Math.max(0, Math.min(1, localX / sliderTrack.width));
                root.audio.setVolume(value);
            }

            Text {
                id: volumeLabel
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.top: parent.top
                anchors.topMargin: 2
                text: "Sound"
                font.family: Root.Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Root.Theme.menuText
                renderType: Text.NativeRendering
            }

            Root.SymbolIcon {
                id: minusIcon
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 3
                width: 14
                height: 14
                glyph: "􀊡"
                fallbackColor: Root.Theme.menuText
                fallbackFontFamily: Root.Theme.fontFamily
                pixelSize: 14
            }

            Root.SymbolIcon {
                id: plusIcon
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 3
                width: 14
                height: 14
                glyph: "􀊩"
                fallbackColor: Root.Theme.menuText
                fallbackFontFamily: Root.Theme.fontFamily
                pixelSize: 14
            }

            Item {
                id: sliderArea
                anchors.left: minusIcon.right
                anchors.leftMargin: 10
                anchors.right: plusIcon.left
                anchors.rightMargin: 10
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 1
                height: 18

                Rectangle {
                    id: sliderTrack
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 4
                    radius: 99
                    color: Qt.rgba(Root.Theme.menuText.r, Root.Theme.menuText.g, Root.Theme.menuText.b, 0.22)
                }

                Rectangle {
                    anchors.left: sliderTrack.left
                    anchors.verticalCenter: sliderTrack.verticalCenter
                    width: sliderTrack.width * root.audio.value
                    height: sliderTrack.height
                    radius: sliderTrack.radius
                    color: Qt.rgba(Root.Theme.menuText.r, Root.Theme.menuText.g, Root.Theme.menuText.b, 0.92)
                }

                Rectangle {
                    width: 18
                    height: 15
                    radius: 7.5
                    x: sliderTrack.x + (sliderTrack.width * root.audio.value) - (width / 2)
                    y: sliderTrack.y + (sliderTrack.height / 2) - (height / 2)
                    color: Qt.rgba(1, 1, 1, 1.0)
                    visible: sliderMouseArea.containsMouse || sliderMouseArea.pressed
                }

                MouseArea {
                    id: sliderMouseArea
                    anchors.fill: parent
                    enabled: root.audio.sliderEnabled
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: function (mouse) {
                        volumeRow.setFromX(mouse.x - sliderTrack.x);
                    }
                    onPositionChanged: function (mouse) {
                        if (pressed) {
                            volumeRow.setFromX(mouse.x - sliderTrack.x);
                        }
                    }
                    onClicked: function (mouse) {
                        volumeRow.setFromX(mouse.x - sliderTrack.x);
                    }
                }
            }
        }
    }

    Connections {
        target: audioMenu
        function onVisibleChanged() {
            root.syncHighlight();
        }
    }

    Component.onDestruction: {
        if (root.highlightState && root.highlightState.activeTarget === root) {
            root.highlightState.activeTarget = null;
        }
    }
}
