import QtQuick
import Qt5Compat.GraphicalEffects

import "." as Tiles
import "../.." as Root

Item {
    id: root

    property string sizeMode: "2x2"
    property var tileData: ({})

    readonly property var provider: _rawDataValue("provider", null)
    readonly property color accentColor: _colorData("accentColor", Qt.rgba(0.08, 0.44, 1.0, 1.0))

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

    function _rawDataValue(key, fallback) {
        var data = root.tileData;
        if (!data || typeof data !== "object") {
            return fallback;
        }

        var value = data[key];
        return value === undefined ? fallback : value;
    }

    function _colorData(key, fallback) {
        return _rawDataValue(key, fallback);
    }

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
        borderColor: Qt.rgba(1, 1, 1, 0.0)

        Rectangle {
            id: artFrame
            x: 14
            y: 14
            width: 40
            height: width
            radius: 10
            color: "transparent"
            readonly property bool artReady: root.artSource.length > 0 && artImageSource.status === Image.Ready

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
                radius: artFrame.radius
                color: "white"
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                source: artImageSource
                maskSource: artMask
                visible: artFrame.artReady
            }

            Rectangle {
                anchors.fill: parent
                visible: !artFrame.artReady
                radius: artFrame.radius
                color: Qt.rgba(1, 1, 1, 0.10)
            }
        }

        Text {
            visible: root.available
            x: 16
            y: 64
            width: 110
            text: root.trackTitle
            color: Qt.rgba(1, 1, 1, 0.85)
            font.family: Root.Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
            elide: Text.ElideRight
            renderType: Text.NativeRendering
        }

        Text {
            visible: root.available
            x: 16
            y: 80
            width: 110
            text: root.artistName
            color: Qt.rgba(1, 1, 1, 84 / 255)
            font.family: Root.Theme.fontFamily
            font.pixelSize: 12
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
            font.pixelSize: 12
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
