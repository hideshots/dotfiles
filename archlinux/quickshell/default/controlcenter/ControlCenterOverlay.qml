import Quickshell
import Quickshell.Wayland
import QtQuick

import "." as ControlCenter

PanelWindow {
    id: root
    required property var shellRoot

    readonly property bool requestedOpen: root.shellRoot.controlCenterEnabled && root.shellRoot.controlCenterOpen && root.shellRoot.controlCenterTargetScreen === screen
    property bool overlayVisible: false
    property real panelRevealProgress: 0.0
    property real flashOpacity: 0.0

    property real popinStartScale: 0.98
    property int openDuration: 150
    property int closeDuration: 100
    property int openEasing: Easing.OutCubic
    property int closeEasing: Easing.InCubic
    property real flashPeakOpacity: 0.24
    property int flashRiseDuration: 35
    property int flashFallDuration: 440
    property int flashEasing: Easing.OutCubic

    visible: root.overlayVisible

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    exclusionMode: ExclusionMode.Ignore

    color: "transparent"
    surfaceFormat.opaque: false
    focusable: false
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell:control-center"

    onRequestedOpenChanged: {
        if (requestedOpen) {
            if (closeAnimation.running) {
                closeAnimation.stop();
            }
            root.overlayVisible = true;
            root.flashOpacity = 0.0;
            openAnimation.restart();
            flashAnimation.restart();
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
            root.panelRevealProgress = 0.0;
        }
    }

    Component.onCompleted: {
        if (requestedOpen) {
            root.overlayVisible = true;
            root.panelRevealProgress = 1.0;
            return;
        }

        root.overlayVisible = false;
        root.panelRevealProgress = 0.0;
    }

    NumberAnimation {
        id: openAnimation
        target: root
        property: "panelRevealProgress"
        to: 1.0
        duration: root.openDuration
        easing.type: root.openEasing
    }

    NumberAnimation {
        id: closeAnimation
        target: root
        property: "panelRevealProgress"
        to: 0.0
        duration: root.closeDuration
        easing.type: root.closeEasing
        onStopped: {
            if (!root.requestedOpen && root.panelRevealProgress <= 0.0001) {
                root.overlayVisible = false;
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

    MouseArea {
        id: backdropMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        preventStealing: true

        function _insideControlCenter(mouseX, mouseY) {
            var panelPos = controlCenterPanel.mapToItem(backdropMouseArea, 0, 0);
            var interactionBleed = 8;
            return mouseX >= (panelPos.x - interactionBleed) && mouseX <= (panelPos.x + controlCenterPanel.width + interactionBleed) && mouseY >= (panelPos.y - interactionBleed) && mouseY <= (panelPos.y + controlCenterPanel.height + interactionBleed);
        }

        onPressed: function (mouse) {
            if (_insideControlCenter(mouse.x, mouse.y)) {
                mouse.accepted = false;
                return;
            }
            mouse.accepted = true;
        }

        onClicked: function (mouse) {
            if (_insideControlCenter(mouse.x, mouse.y)) {
                mouse.accepted = false;
                return;
            }
            mouse.accepted = true;
            root.shellRoot.controlCenterOpen = false;
        }
    }

    ControlCenter.ControlCenterPanel {
        id: controlCenterPanel
        z: 1
        openFlashOpacity: root.flashOpacity
        opacity: root.panelRevealProgress
        scale: root.popinStartScale + ((1.0 - root.popinStartScale) * root.panelRevealProgress)
        transformOrigin: Item.Center
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: root.shellRoot.controlCenterTopMargin
        anchors.rightMargin: root.shellRoot.controlCenterRightMargin
    }
}
