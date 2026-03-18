import QtQuick

import "../controlcenter/tiles" as Tiles

Item {
    id: root

    property bool requestedVisible: false
    property bool brightnessVisible: false
    property bool volumeVisible: false
    property real brightnessValue: 0.0
    property real volumeValue: 0.0
    property string brightnessDetailText: ""
    property string volumeDetailText: ""
    property string brightnessIconGlyph: "􀆮"
    property string volumeIconGlyph: "􀊩"
    property int cardSpacing: 12
    property real popinStartScale: 0.97
    property int openDuration: 350
    property int closeDuration: 100
    property int openEasing: Easing.OutBack
    property int closeEasing: Easing.OutCirc
    property real flashPeakOpacity: 0.54
    property int flashRiseDuration: 0
    property int flashFallDuration: 350
    property int flashEasing: Easing.OutCirc

    property bool overlayVisible: false
    property real revealProgress: 0.0
    property real flashOpacity: 0.0
    property bool presentedBrightnessVisible: false
    property bool presentedVolumeVisible: false
    property real presentedBrightnessValue: 0.0
    property real presentedVolumeValue: 0.0
    property string presentedBrightnessDetailText: ""
    property string presentedVolumeDetailText: ""
    property string presentedBrightnessIconGlyph: "􀆮"
    property string presentedVolumeIconGlyph: "􀊩"

    readonly property bool hasCards: root.presentedBrightnessVisible || root.presentedVolumeVisible
    readonly property real clampedBrightnessValue: Math.max(0, Math.min(1, Number(root.presentedBrightnessValue)))
    readonly property real clampedVolumeValue: Math.max(0, Math.min(1, Number(root.presentedVolumeValue)))

    implicitWidth: cardsColumn.implicitWidth
    implicitHeight: cardsColumn.implicitHeight
    width: implicitWidth
    height: implicitHeight
    visible: root.overlayVisible
    opacity: root.revealProgress
    scale: closeAnimation.running ? 1.0 : (root.popinStartScale + ((1.0 - root.popinStartScale) * root.revealProgress))
    transformOrigin: Item.Center

    onRequestedVisibleChanged: {
        var reopeningWhileVisible = root.overlayVisible;

        if (root.requestedVisible) {
            root._syncPresentedState();
        }

        if (root.requestedVisible && root.hasCards) {
            if (closeAnimation.running) {
                closeAnimation.stop();
            }
            root.overlayVisible = true;
            root.flashOpacity = 0.0;
            openAnimation.restart();
            if (reopeningWhileVisible) {
                if (flashAnimation.running) {
                    flashAnimation.stop();
                }
            } else {
                flashAnimation.restart();
            }
            return;
        }

        if (openAnimation.running) {
            openAnimation.stop();
        }
        if (flashAnimation.running) {
            flashAnimation.stop();
        }
        root.flashOpacity = 0.0;

        if (root.overlayVisible) {
            closeAnimation.restart();
        } else {
            root.revealProgress = 0.0;
        }
    }

    Component.onCompleted: {
        if (root.requestedVisible) {
            root._syncPresentedState();
        }

        if (root.requestedVisible && root.hasCards) {
            root.overlayVisible = true;
            root.revealProgress = 1.0;
            return;
        }

        root.overlayVisible = false;
        root.revealProgress = 0.0;
    }

    onBrightnessDetailTextChanged: {
        root._maybeSyncPresentedState();
    }
    onBrightnessIconGlyphChanged: {
        root._maybeSyncPresentedState();
    }
    onBrightnessValueChanged: {
        root._maybeSyncPresentedState();
    }
    onBrightnessVisibleChanged: {
        root._maybeSyncPresentedState();
    }
    onVolumeDetailTextChanged: {
        root._maybeSyncPresentedState();
    }
    onVolumeIconGlyphChanged: {
        root._maybeSyncPresentedState();
    }
    onVolumeValueChanged: {
        root._maybeSyncPresentedState();
    }
    onVolumeVisibleChanged: {
        root._maybeSyncPresentedState();
    }

    function _syncPresentedState() {
        root.presentedBrightnessVisible = root.brightnessVisible;
        root.presentedVolumeVisible = root.volumeVisible;
        root.presentedBrightnessValue = root.brightnessValue;
        root.presentedVolumeValue = root.volumeValue;
        root.presentedBrightnessDetailText = root.brightnessDetailText;
        root.presentedVolumeDetailText = root.volumeDetailText;
        root.presentedBrightnessIconGlyph = root.brightnessIconGlyph;
        root.presentedVolumeIconGlyph = root.volumeIconGlyph;
    }

    function _maybeSyncPresentedState() {
        if (!root.requestedVisible) {
            return;
        }

        if (!root.brightnessVisible && !root.volumeVisible) {
            return;
        }

        root._syncPresentedState();
    }

    NumberAnimation {
        id: openAnimation
        target: root
        property: "revealProgress"
        to: 1.0
        duration: root.openDuration
        easing.type: root.openEasing
    }

    NumberAnimation {
        id: closeAnimation
        target: root
        property: "revealProgress"
        to: 0.0
        duration: root.closeDuration
        easing.type: root.closeEasing
        onStopped: {
            if (!root.requestedVisible && root.revealProgress <= 0.0001) {
                root.overlayVisible = false;
                root.presentedBrightnessVisible = false;
                root.presentedVolumeVisible = false;
            }
        }
    }

    SequentialAnimation {
        id: flashAnimation

        NumberAnimation {
            target: root
            property: "flashOpacity"
            to: root.flashPeakOpacity
            duration: root.flashRiseDuration
            easing.type: Easing.OutQuad
        }

        NumberAnimation {
            target: root
            property: "flashOpacity"
            to: 0.0
            duration: root.flashFallDuration
            easing.type: root.flashEasing
        }
    }

    Column {
        id: cardsColumn
        spacing: root.cardSpacing

        Tiles.SliderTile {
            visible: root.presentedBrightnessVisible
            interactive: false
            openFlashOpacity: root.flashOpacity
            tileData: ({
                    title: "Display",
                    minusSymbol: "􀆬",
                    plusSymbol: "􀆮",
                    value: root.clampedBrightnessValue,
                    detailText: root.presentedBrightnessDetailText,
                    enabled: true
                })
        }

        Tiles.SliderTile {
            visible: root.presentedVolumeVisible
            interactive: false
            openFlashOpacity: root.flashOpacity
            tileData: ({
                    title: "Sound",
                    minusSymbol: "􀊡",
                    plusSymbol: "􀊩",
                    value: root.clampedVolumeValue,
                    detailText: root.presentedVolumeDetailText,
                    enabled: true
                })
        }
    }
}
