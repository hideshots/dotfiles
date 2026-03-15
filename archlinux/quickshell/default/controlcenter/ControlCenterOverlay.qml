// qmllint disable uncreatable-type
import Quickshell
import Quickshell.Wayland
import QtQuick

import ".." as Root
import "." as ControlCenter

PanelWindow {
    id: root
    required property var shellRoot
    required property var variantScreen

    readonly property bool requestedOpen: root.shellRoot.controlCenterEnabled
        && root.shellRoot.controlCenterOpen
        && root.shellRoot.controlCenterTargetScreen === root.variantScreen
    property bool overlayVisible: false
    property real panelRevealProgress: 0.0
    property real flashOpacity: 0.0

    property real popinStartScale: 0.97
    property int openDuration: 350
    property int closeDuration: 100
    property int openEasing: Easing.OutBack
    property int closeEasing: Easing.OutCirc
    property real flashPeakOpacity: 0.54
    property int flashRiseDuration: 0
    property int flashFallDuration: 350
    property int flashEasing: Easing.OutCirc

    visible: root.overlayVisible

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    exclusionMode: ExclusionMode.Ignore

    screen: root.variantScreen
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
            if (Root.BrightnessService.shouldRefreshOnOpenForScreen(root.variantScreen)) {
                Root.BrightnessService.refreshForScreen(root.variantScreen);
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
        targetScreen: root.variantScreen
        z: 1
        openFlashOpacity: root.flashOpacity
        opacity: root.panelRevealProgress
        scale: closeAnimation.running ? 1.0 : (root.popinStartScale + ((1.0 - root.popinStartScale) * root.panelRevealProgress))
        transformOrigin: Item.Center
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: root.shellRoot.controlCenterTopMargin
        anchors.rightMargin: root.shellRoot.controlCenterRightMargin
    }
}
