pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects

import ".." as Root
import "../menu" as Menu

Rectangle {
    id: root

    property var highlightState: null
    readonly property var wifi: Root.WifiService

    visible: wifi.visible
    height: parent.height
    width: visible ? wifiIcon.width + (Root.Theme.itemPadding * 2) : 0
    color: "transparent"
    radius: Root.Theme.borderRadius

    function syncHighlight() {
        if (!root.highlightState) {
            return;
        }

        if (wifiMenu.visible) {
            root.highlightState.activeTarget = root;
            return;
        }

        if (root.highlightState.activeTarget === root) {
            root.highlightState.activeTarget = null;
        }
    }

    onVisibleChanged: {
        if (!visible && wifiMenu.visible) {
            wifiMenu.closeTopMenu();
        }
    }

    Root.SymbolIcon {
        id: wifiIcon
        anchors.centerIn: parent
        width: Root.Theme.iconSize
        height: Root.Theme.iconSize
        glyph: root.wifi.iconGlyph
        svgNameOverride: root.wifi.iconSvgName
        fallbackFontFamily: Root.Theme.fontFamily
        pixelSize: Root.Theme.iconSize
        fallbackColor: Root.Theme.textSecondary
    }

    DropShadow {
        anchors.fill: wifiIcon
        source: wifiIcon
        visible: Root.Theme.isDark
        horizontalOffset: Root.Theme.shadowHorizontalOffset
        verticalOffset: Root.Theme.shadowVerticalOffset
        radius: Root.Theme.shadowRadius
        samples: 16
        spread: 0
        color: Root.Theme.shadowColor
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: wifiMenu.toggle()
    }

    Menu.MenuPopup {
        id: wifiMenu
        anchorItem: root
        anchorPointX: root.width - implicitWidth
        anchorPointY: root.height + yOffset
        yOffset: 8
        adaptiveWidth: true

        model: [
            {
                type: "header",
                label: "Wi-Fi"
            },
            {
                type: "action",
                label: "Network: " + (root.wifi.connected && root.wifi.ssid.length > 0 ? root.wifi.ssid : "Not Connected"),
                disabled: true
            },
            {
                type: "action",
                label: "Status: " + root.wifi.statusText,
                disabled: true
            },
            {
                type: "action",
                label: "Signal: " + (root.wifi.connected ? (String(root.wifi.signalPercent) + "%") : "—"),
                disabled: true
            },
            {
                type: "separator"
            },
            {
                type: "action",
                label: root.wifi.enabled ? "Turn Wi-Fi Off" : "Turn Wi-Fi On",
                action: function () {
                    root.wifi.setEnabled(!root.wifi.enabled);
                }
            }
        ]
    }

    Connections {
        target: wifiMenu
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
