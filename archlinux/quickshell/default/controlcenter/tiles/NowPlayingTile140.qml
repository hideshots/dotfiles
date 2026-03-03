import QtQuick
import Qt5Compat.GraphicalEffects

import "." as Tiles
import "../.." as Root

Item {
    id: root

    property var provider: null
    property color accentColor: Qt.rgba(0.08, 0.44, 1.0, 1.0)

    readonly property bool available: !!provider && provider.available
    readonly property bool playing: !!provider && provider.playing
    readonly property string trackTitle: available
        ? ((provider.title && String(provider.title).trim().length > 0) ? provider.title : "Track")
        : ""
    readonly property string artistName: available
        ? ((provider.artist && String(provider.artist).trim().length > 0) ? provider.artist : "Artist")
        : ""
    readonly property string artSource: _toImageSource(available && provider ? provider.artUrl : "")
    readonly property string playPauseSymbol: playing ? "􀊆" : "􀊄"

    implicitWidth: 140
    implicitHeight: 140
    width: implicitWidth
    height: implicitHeight

    function _toImageSource(source) {
        var text = source === undefined || source === null ? "" : String(source).trim();
        if (text.length === 0) {
            return "";
        }
        if (text.indexOf("/") === 0) {
            return "file://" + text;
        }
        return text;
    }

    function _runAction(actionName) {
        if (!root.available || !root.provider) {
            return;
        }

        if (actionName === "previous" && root.provider.previous) {
            root.provider.previous();
            return;
        }

        if (actionName === "playPause" && root.provider.playPause) {
            root.provider.playPause();
            return;
        }

        if (actionName === "next" && root.provider.next) {
            root.provider.next();
        }
    }

    Tiles.TileSurface {
        anchors.fill: parent
        radius: 34
        tintColor: Qt.rgba(0, 0, 0, 0.20)
        contrastColor: Qt.rgba(1, 1, 1, 0.0)
        borderColor: Qt.rgba(1, 1, 1, 0.12)
        edgeOpacity: 0.78
        edgeTint: Qt.rgba(1, 1, 1, 0.96)

        Rectangle {
            id: artFrame
            x: 14
            y: 14
            width: 50
            height: 50
            radius: 14
            color: "transparent"

            Image {
                id: artImageSource
                anchors.fill: parent
                source: root.artSource
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                cache: true
                visible: false
            }

            Rectangle {
                id: artMask
                anchors.fill: parent
                radius: 14
                color: "black"
                visible: false
            }

            OpacityMask {
                id: maskedArt
                anchors.fill: parent
                source: artImageSource
                maskSource: artMask
                cached: true
                visible: root.artSource.length > 0 && artImageSource.status === Image.Ready
            }

            Rectangle {
                anchors.fill: parent
                visible: !maskedArt.visible
                radius: 14
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0.24, 0.28, 0.34, 0.80) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.10, 0.12, 0.15, 0.86) }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !maskedArt.visible
                text: "􀑪"
                color: Qt.rgba(1, 1, 1, 0.88)
                font.family: Root.Theme.fontFamilySymbol
                font.pixelSize: 17
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
        }

        Text {
            visible: root.available
            x: 16
            y: 66
            width: 110
            text: root.trackTitle
            color: Qt.rgba(1, 1, 1, 0.98)
            font.family: Root.Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
            elide: Text.ElideRight
            renderType: Text.NativeRendering
        }

        Text {
            visible: root.available
            x: 16
            y: 84
            width: 110
            text: root.artistName
            color: Qt.rgba(1, 1, 1, 84 / 255)
            font.family: Root.Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
            elide: Text.ElideRight
            renderType: Text.NativeRendering
        }

        Text {
            visible: !root.available
            x: 15
            y: 74
            width: 110
            text: "Not Playing"
            color: Qt.rgba(1, 1, 1, 191 / 255)
            font.family: Root.Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
            renderType: Text.NativeRendering
        }

        Item {
            id: previousButton
            x: 24
            y: 109
            width: 20
            height: 14

            HoverHandler {
                id: previousHover
                cursorShape: root.available ? Qt.PointingHandCursor : Qt.ForbiddenCursor
            }

            TapHandler {
                id: previousTap
                enabled: root.available
                acceptedButtons: Qt.LeftButton
                onTapped: root._runAction("previous")
            }

            Text {
                anchors.centerIn: parent
                text: "􀊊"
                color: root.available ? Qt.rgba(1, 1, 1, 0.97) : Qt.rgba(1, 1, 1, 64 / 255)
                opacity: root.available ? (previousTap.pressed ? 0.60 : (previousHover.hovered ? 0.80 : 1.0)) : 1.0
                font.family: Root.Theme.fontFamilySymbol
                font.pixelSize: 12
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
        }

        Item {
            id: playPauseButton
            x: 57
            y: 100
            width: 26
            height: 30

            HoverHandler {
                id: playPauseHover
                cursorShape: root.available ? Qt.PointingHandCursor : Qt.ForbiddenCursor
            }

            TapHandler {
                id: playPauseTap
                enabled: root.available
                acceptedButtons: Qt.LeftButton
                onTapped: root._runAction("playPause")
            }

            Text {
                anchors.centerIn: parent
                text: root.playPauseSymbol
                color: root.available ? Qt.rgba(1, 1, 1, 0.97) : Qt.rgba(1, 1, 1, 64 / 255)
                opacity: root.available ? (playPauseTap.pressed ? 0.60 : (playPauseHover.hovered ? 0.80 : 1.0)) : 1.0
                font.family: Root.Theme.fontFamilySymbol
                font.pixelSize: 25
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
        }

        Item {
            id: nextButton
            x: parent.width - 44
            y: 109
            width: 20
            height: 14

            HoverHandler {
                id: nextHover
                cursorShape: root.available ? Qt.PointingHandCursor : Qt.ForbiddenCursor
            }

            TapHandler {
                id: nextTap
                enabled: root.available
                acceptedButtons: Qt.LeftButton
                onTapped: root._runAction("next")
            }

            Text {
                anchors.centerIn: parent
                text: "􀊌"
                color: root.available ? Qt.rgba(1, 1, 1, 0.97) : Qt.rgba(1, 1, 1, 64 / 255)
                opacity: root.available ? (nextTap.pressed ? 0.60 : (nextHover.hovered ? 0.80 : 1.0)) : 1.0
                font.family: Root.Theme.fontFamilySymbol
                font.pixelSize: 12
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
        }
    }
}
