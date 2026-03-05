pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects

import ".." as Root
import "../menu" as Menu

Rectangle {
    id: root

    property var highlightState: null

    readonly property var battery: Root.BatteryService

    visible: battery.visible
    height: parent.height
    width: visible ? contentRow.implicitWidth + (Root.Theme.itemPadding * 2) : 0
    color: "transparent"
    radius: Root.Theme.borderRadius

    function syncHighlight() {
        if (!root.highlightState) {
            return;
        }

        if (batteryMenu.visible) {
            root.highlightState.activeTarget = root;
            return;
        }

        if (root.highlightState.activeTarget === root) {
            root.highlightState.activeTarget = null;
        }
    }

    onVisibleChanged: {
        if (!visible && batteryMenu.visible) {
            batteryMenu.closeTopMenu();
        }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 8

        Text {
            id: percentageText
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1
            visible: root.battery.showPercentage
            text: String(root.battery.percentage) + "%"
            font.family: Root.Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
            color: Root.Theme.textPrimary
            renderType: Text.NativeRendering
        }

        Root.SymbolIcon {
            id: batteryIcon
            anchors.verticalCenter: parent.verticalCenter
            width: Root.Theme.iconSize
            height: Root.Theme.iconSize
            glyph: root.battery.iconGlyph
            fallbackFontFamily: Root.Theme.fontFamily
            pixelSize: Root.Theme.iconSize
            fallbackColor: Root.Theme.textSecondary
        }
    }

    DropShadow {
        anchors.fill: contentRow
        source: contentRow
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
        onClicked: batteryMenu.toggle()
    }

    Menu.MenuPopup {
        id: batteryMenu
        anchorItem: root
        anchorPointX: root.width - implicitWidth
        anchorPointY: root.height + yOffset
        yOffset: 8
        adaptiveWidth: true

        model: [
            {
                type: "header",
                label: "Battery"
            },
            {
                type: "action",
                label: "Power source: " + root.battery.powerSourceText,
                disabled: true
            },
            {
                type: "action",
                label: "Status: " + root.battery.statusText,
                disabled: true
            },
            {
                type: "separator"
            },
            {
                type: "action",
                label: "Show Percentage",
                reserveCheckmark: true,
                checked: root.battery.showPercentage,
                action: function () {
                    root.battery.showPercentage = !root.battery.showPercentage;
                }
            }
        ]
    }

    Connections {
        target: batteryMenu
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
