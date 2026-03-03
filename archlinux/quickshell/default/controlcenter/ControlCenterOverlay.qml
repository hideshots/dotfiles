import Quickshell
import Quickshell.Wayland
import QtQuick

import "." as ControlCenter

PanelWindow {
    id: root
    required property var shellRoot

    visible: root.shellRoot.controlCenterEnabled && root.shellRoot.controlCenterOpen && root.shellRoot.controlCenterTargetScreen === screen

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

    MouseArea {
        id: backdropMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        preventStealing: true

        function _insideControlCenter(mouseX, mouseY) {
            var panelPos = controlCenterPanel.mapToItem(backdropMouseArea, 0, 0);
            var interactionBleed = 8;
            return mouseX >= (panelPos.x - interactionBleed)
                && mouseX <= (panelPos.x + controlCenterPanel.width + interactionBleed)
                && mouseY >= (panelPos.y - interactionBleed)
                && mouseY <= (panelPos.y + controlCenterPanel.height + interactionBleed);
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
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: root.shellRoot.controlCenterTopMargin
        anchors.rightMargin: root.shellRoot.controlCenterRightMargin
    }
}
